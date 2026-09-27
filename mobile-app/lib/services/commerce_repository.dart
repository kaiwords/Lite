import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/marketplace.dart';
import 'marketplace_repository.dart';
import 'stripe_service.dart' show StripeCheckoutException, invokeEdgeFunction;
import 'supabase_service.dart';
import 'users_repository.dart';

ShippingMethod? _shippingMethodFromRow(dynamic raw) {
  if (raw is! String) return null;
  for (final m in ShippingMethod.values) {
    if (m.name == raw) return m;
  }
  return null;
}

/// A completed purchase — an `order_items` row (status `paid`) joined back
/// to its listing, from the buyer's side.
class PurchaseRecord {
  final String orderItemId;
  final MarketplaceListing listing;
  final DateTime purchasedAt;
  final String orderId;
  final ShippingMethod? shippingMethod;
  final String? meetupPlace;
  final bool meetupConfirmed;
  const PurchaseRecord({
    required this.orderItemId,
    required this.listing,
    required this.purchasedAt,
    required this.orderId,
    this.shippingMethod,
    this.meetupPlace,
    this.meetupConfirmed = false,
  });
}

/// A completed sale — the same join, from the seller's side, with the
/// buyer's name and the seller's actual take (unit price minus the
/// platform fee — see supabase/functions/stripe-webhook).
class SaleRecord {
  final String orderItemId;
  final MarketplaceListing listing;
  final DateTime soldAt;
  final String buyerName;
  final double amount;
  final ShippingMethod? shippingMethod;
  final String? meetupPlace;
  final bool meetupConfirmed;
  const SaleRecord({
    required this.orderItemId,
    required this.listing,
    required this.soldAt,
    required this.buyerName,
    required this.amount,
    this.shippingMethod,
    this.meetupPlace,
    this.meetupConfirmed = false,
  });
}

/// Whether the signed-in user has finished Stripe Connect onboarding well
/// enough to receive payouts. Drives the "Set up payouts" prompt on the
/// Sales tab and the pre-checkout validation stripe-create-checkout also
/// enforces server-side.
class SellerStripeStatus {
  final bool hasAccount;
  final bool chargesEnabled;
  const SellerStripeStatus({
    required this.hasAccount,
    required this.chargesEnabled,
  });
  static const notStarted = SellerStripeStatus(
    hasAccount: false,
    chargesEnabled: false,
  );
}

/// Reads the real orders/order_items/user_stripe_accounts tables that
/// back Purchases, Sales, and seller payout status — replacing the
/// local-only state that used to live in marketplace_account_provider.dart.
class CommerceRepository {
  static SupabaseClient get _client => SupabaseService.client;

  static Future<List<PurchaseRecord>> fetchPurchases(String buyerId) async {
    final rows = await _client
        .from('order_items')
        .select(
          'id, created_at, shipping_method, meetup_place, meetup_confirmed, '
          'marketplace_listings(*, ebook_chapters(*), audio_volumes(*)), '
          'orders!inner(id, buyer_id, status)',
        )
        .eq('orders.buyer_id', buyerId)
        .eq('orders.status', 'paid')
        .order('created_at', ascending: false);

    return (rows as List).map((r) {
      final row = (r as Map).cast<String, dynamic>();
      final listingRow = (row['marketplace_listings'] as Map)
          .cast<String, dynamic>();
      final order = (row['orders'] as Map).cast<String, dynamic>();
      return PurchaseRecord(
        orderItemId: row['id'] as String,
        listing: MarketplaceRepository.listingFromRow(listingRow),
        purchasedAt: DateTime.parse(row['created_at'] as String),
        orderId: order['id'] as String,
        shippingMethod: _shippingMethodFromRow(row['shipping_method']),
        meetupPlace: row['meetup_place'] as String?,
        meetupConfirmed: (row['meetup_confirmed'] as bool?) ?? false,
      );
    }).toList();
  }

  static Future<List<SaleRecord>> fetchSales(String sellerId) async {
    final rows = await _client
        .from('order_items')
        .select(
          'id, created_at, unit_price_cents, platform_fee_cents, '
          'shipping_method, meetup_place, meetup_confirmed, '
          'marketplace_listings(*, ebook_chapters(*), audio_volumes(*)), '
          'orders!inner(buyer_id, status)',
        )
        .eq('seller_id', sellerId)
        .eq('orders.status', 'paid')
        .order('created_at', ascending: false);

    final items = (rows as List)
        .map((r) => (r as Map).cast<String, dynamic>())
        .toList();
    final buyerIds = items
        .map((r) => ((r['orders'] as Map)['buyer_id']) as String)
        .toSet()
        .toList();
    final buyers = await UsersRepository.fetchByIds(buyerIds);
    final buyerNameById = {for (final b in buyers) b.id: b.displayName};

    return items.map((row) {
      final listingRow = (row['marketplace_listings'] as Map)
          .cast<String, dynamic>();
      final order = (row['orders'] as Map).cast<String, dynamic>();
      final buyerId = order['buyer_id'] as String;
      final unitPriceCents = (row['unit_price_cents'] as num).toInt();
      final feeCents = (row['platform_fee_cents'] as num).toInt();
      return SaleRecord(
        orderItemId: row['id'] as String,
        listing: MarketplaceRepository.listingFromRow(listingRow),
        soldAt: DateTime.parse(row['created_at'] as String),
        buyerName: buyerNameById[buyerId] ?? 'A reader',
        amount: (unitPriceCents - feeCents) / 100,
        shippingMethod: _shippingMethodFromRow(row['shipping_method']),
        meetupPlace: row['meetup_place'] as String?,
        meetupConfirmed: (row['meetup_confirmed'] as bool?) ?? false,
      );
    }).toList();
  }

  /// Marks a Meetup-fulfillment sale as confirmed — see
  /// supabase/functions/confirm-meetup for why this goes through an Edge
  /// Function rather than a direct table update.
  static Future<void> confirmMeetup(String orderItemId) async {
    await invokeEdgeFunction(
      'confirm-meetup',
      body: {'orderItemId': orderItemId},
    );
  }

  /// Claims a Free or Swap listing — creates a $0 orders/order_items pair
  /// server-side with no Stripe involved, via the claim-listing Edge
  /// Function (a normal Postgres insert can't do this: RLS gives
  /// authenticated users no direct INSERT policy on either table). Throws
  /// [StripeCheckoutException] on failure, same as [StripeService.buyListings],
  /// so utils/purchase_flow.dart's error handling covers both.
  static Future<void> claimListing(
    String listingId, {
    ShippingSelection? shipping,
  }) async {
    await invokeEdgeFunction(
      'claim-listing',
      body: {
        'listingId': listingId,
        if (shipping != null) 'shipping': shipping.toJson(),
      },
    );
  }

  static Future<SellerStripeStatus> fetchSellerStripeStatus(
    String userId,
  ) async {
    final row = await _client
        .from('user_stripe_accounts')
        .select('stripe_connect_account_id, charges_enabled')
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return SellerStripeStatus.notStarted;
    return SellerStripeStatus(
      hasAccount: row['stripe_connect_account_id'] != null,
      chargesEnabled: (row['charges_enabled'] as bool?) ?? false,
    );
  }
}
