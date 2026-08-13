import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/marketplace.dart';
import '../services/commerce_repository.dart';
import '../services/local_store.dart';
import '../services/marketplace_repository.dart';
import '../services/stripe_service.dart';
import '../services/supabase_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cart
// ─────────────────────────────────────────────────────────────────────────────

class CartNotifier extends StateNotifier<List<MarketplaceListing>> {
  CartNotifier(super.initial);

  void add(MarketplaceListing listing) {
    if (!state.any((l) => l.id == listing.id)) {
      state = [...state, listing];
    }
  }

  void remove(String listingId) {
    state = state.where((l) => l.id != listingId).toList();
  }

  void clear() => state = [];

  bool contains(String listingId) => state.any((l) => l.id == listingId);
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<MarketplaceListing>>((ref) {
  final notifier = CartNotifier(LocalStore.instance.loadCart() ?? const []);
  notifier.addListener(LocalStore.instance.saveCart, fireImmediately: false);
  return notifier;
});

// ─────────────────────────────────────────────────────────────────────────────
// Purchases (items the user has bought)
// ─────────────────────────────────────────────────────────────────────────────

class Purchase {
  final String orderItemId;
  final MarketplaceListing listing;
  final DateTime purchasedAt;
  final String orderId;
  final ShippingMethod? shippingMethod;
  final String? meetupPlace;
  final bool meetupConfirmed;
  const Purchase({
    required this.orderItemId,
    required this.listing,
    required this.purchasedAt,
    required this.orderId,
    this.shippingMethod,
    this.meetupPlace,
    this.meetupConfirmed = false,
  });

  Map<String, dynamic> toJson() => {
        'orderItemId': orderItemId,
        'listing': listing.toJson(),
        'purchasedAt': purchasedAt.toIso8601String(),
        'orderId': orderId,
        'shippingMethod': shippingMethod?.name,
        'meetupPlace': meetupPlace,
        'meetupConfirmed': meetupConfirmed,
      };

  factory Purchase.fromJson(Map<String, dynamic> j) => Purchase(
        // Older locally-cached purchases predate order_items.id being
        // stored — fall back to orderId so they still round-trip.
        orderItemId: (j['orderItemId'] as String?) ?? j['orderId'] as String,
        listing:
            MarketplaceListing.fromJson((j['listing'] as Map).cast<String, dynamic>()),
        purchasedAt: DateTime.parse(j['purchasedAt'] as String),
        orderId: j['orderId'] as String,
        shippingMethod: j['shippingMethod'] == null
            ? null
            : ShippingMethod.values.firstWhere(
                (m) => m.name == j['shippingMethod'],
                orElse: () => ShippingMethod.pickup,
              ),
        meetupPlace: j['meetupPlace'] as String?,
        meetupConfirmed: (j['meetupConfirmed'] as bool?) ?? false,
      );
}

class PurchasesNotifier extends StateNotifier<List<Purchase>> {
  PurchasesNotifier(super.initial);

  bool contains(String listingId) =>
      state.any((p) => p.listing.id == listingId);

  /// Replaces local state with the buyer's real paid orders from Supabase
  /// (`orders`/`order_items`, joined back to their listings — see
  /// CommerceRepository.fetchPurchases). Swallows errors, same as the rest
  /// of the app's `loadFromSupabase()` methods: offline or a transient
  /// failure just means the previously-shown/local data stays up.
  Future<void> loadFromSupabase(String buyerId) async {
    try {
      final records = await CommerceRepository.fetchPurchases(buyerId);
      state = records
          .map((r) => Purchase(
                orderItemId: r.orderItemId,
                listing: r.listing,
                purchasedAt: r.purchasedAt,
                orderId: r.orderId,
                shippingMethod: r.shippingMethod,
                meetupPlace: r.meetupPlace,
                meetupConfirmed: r.meetupConfirmed,
              ))
          .toList();
    } catch (_) {
      // See doc comment above.
    }
  }

  /// Runs real Stripe checkout for [listings] (one item for "Buy Now",
  /// several for cart checkout) via [StripeService.buyListings], then
  /// refreshes from Supabase once the payment succeeds. Throws
  /// [StripeCheckoutException] on failure or cancellation — see
  /// utils/purchase_flow.dart for the shared UI handling every buy entry
  /// point uses.
  Future<void> buyListings(
    List<MarketplaceListing> listings, {
    required String buyerId,
    Map<String, ShippingSelection> shipping = const {},
  }) async {
    await StripeService.buyListings(
      listings.map((l) => l.id).toList(),
      shipping: shipping,
    );
    await loadFromSupabase(buyerId);
  }

  /// Claims a Free or Swap [listing] via [CommerceRepository.claimListing]
  /// (no Stripe involved — see the claim-listing Edge Function), then
  /// refreshes from Supabase the same way [buyListings] does.
  Future<void> claimListing(
    MarketplaceListing listing, {
    required String buyerId,
    ShippingSelection? shipping,
  }) async {
    await CommerceRepository.claimListing(listing.id, shipping: shipping);
    await loadFromSupabase(buyerId);
  }
}

final purchasesProvider =
    StateNotifierProvider<PurchasesNotifier, List<Purchase>>((ref) {
  final notifier =
      PurchasesNotifier(LocalStore.instance.loadPurchases() ?? const []);
  notifier.addListener(LocalStore.instance.savePurchases,
      fireImmediately: false);
  final buyerId = SupabaseService.client.auth.currentUser?.id;
  if (buyerId != null) notifier.loadFromSupabase(buyerId);
  return notifier;
});

// ─────────────────────────────────────────────────────────────────────────────
// Sales (the current user's own listings that have sold)
// ─────────────────────────────────────────────────────────────────────────────

class Sale {
  final String orderItemId;
  final MarketplaceListing listing;
  final DateTime soldAt;
  final String buyerName;
  final double amount;
  final ShippingMethod? shippingMethod;
  final String? meetupPlace;
  final bool meetupConfirmed;
  const Sale({
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

class SalesNotifier extends StateNotifier<List<Sale>> {
  SalesNotifier() : super(const []);

  /// Loads the seller's real paid sales from Supabase (`order_items` where
  /// `seller_id` is this user, joined to the buyer's name and the listing —
  /// see CommerceRepository.fetchSales). `amount` is the seller's actual
  /// take (unit price minus the platform fee taken in stripe-webhook).
  Future<void> loadFromSupabase(String sellerId) async {
    try {
      final records = await CommerceRepository.fetchSales(sellerId);
      state = records
          .map((r) => Sale(
                orderItemId: r.orderItemId,
                listing: r.listing,
                soldAt: r.soldAt,
                buyerName: r.buyerName,
                amount: r.amount,
                shippingMethod: r.shippingMethod,
                meetupPlace: r.meetupPlace,
                meetupConfirmed: r.meetupConfirmed,
              ))
          .toList();
    } catch (_) {
      // Offline or request failed — keep whatever was last shown.
    }
  }

  /// Marks one sale's Meetup as confirmed and refreshes so the Sales tab
  /// reflects it immediately.
  Future<void> confirmMeetup(String orderItemId, String sellerId) async {
    await CommerceRepository.confirmMeetup(orderItemId);
    await loadFromSupabase(sellerId);
  }
}

final salesProvider = StateNotifierProvider<SalesNotifier, List<Sale>>((ref) {
  final notifier = SalesNotifier();
  final sellerId = SupabaseService.client.auth.currentUser?.id;
  if (sellerId != null) notifier.loadFromSupabase(sellerId);
  return notifier;
});

// ─────────────────────────────────────────────────────────────────────────────
// Seller Stripe Connect status — drives the "Set up payouts" prompt
// ─────────────────────────────────────────────────────────────────────────────

class SellerStripeStatusNotifier extends StateNotifier<SellerStripeStatus> {
  SellerStripeStatusNotifier() : super(SellerStripeStatus.notStarted);

  Future<void> refresh(String userId) async {
    try {
      state = await CommerceRepository.fetchSellerStripeStatus(userId);
    } catch (_) {
      // Offline or request failed — keep the last known status.
    }
  }
}

final sellerStripeStatusProvider =
    StateNotifierProvider<SellerStripeStatusNotifier, SellerStripeStatus>(
        (ref) {
  final notifier = SellerStripeStatusNotifier();
  final userId = SupabaseService.client.auth.currentUser?.id;
  if (userId != null) notifier.refresh(userId);
  return notifier;
});

// ─────────────────────────────────────────────────────────────────────────────
// My Listings (books the current user has listed for sale)
// ─────────────────────────────────────────────────────────────────────────────

class MyListingsNotifier extends StateNotifier<List<MarketplaceListing>> {
  MyListingsNotifier(super.initial);

  /// No initial-listings backend exists yet — starts empty rather than
  /// fabricated. Listings added via [add] do sync to the real backend.
  static List<MarketplaceListing> seed() => const [];

  /// Prepends [listing] locally right away; returns whether the backend
  /// insert also succeeded so the UI can tell the user when it didn't sync.
  Future<bool> add(MarketplaceListing listing) async {
    state = [listing, ...state];
    try {
      await MarketplaceRepository.insert(listing);
      return true;
    } catch (_) {
      return false;
    }
  }

  void remove(String id) =>
      state = state.where((l) => l.id != id).toList();

  /// Replaces the matching listing locally right away; returns whether the
  /// backend update also succeeded.
  Future<bool> update(MarketplaceListing updated) async {
    state = [
      for (final l in state) if (l.id == updated.id) updated else l,
    ];
    try {
      await MarketplaceRepository.update(updated);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final myListingsProvider =
    StateNotifierProvider<MyListingsNotifier, List<MarketplaceListing>>((ref) {
  final notifier = MyListingsNotifier(
      LocalStore.instance.loadMyListings() ?? MyListingsNotifier.seed());
  notifier.addListener(LocalStore.instance.saveMyListings,
      fireImmediately: false);
  return notifier;
});
