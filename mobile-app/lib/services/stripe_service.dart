import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/marketplace.dart';
import 'supabase_service.dart';

/// Wraps the two buyer/seller-facing Stripe flows, both backed by Supabase
/// Edge Functions (never talks to Stripe directly — the secret key never
/// leaves the server). See `supabase/functions/stripe-*` for the
/// server-side half of each of these.
class StripeService {
  static Future<void> init() async {
    // flutter_stripe's web implementation currently calls dart:io
    // Platform.isIOS internally when `publishableKey` is set, which throws
    // ("Unsupported operation: Platform._operatingSystem") on web before
    // the app ever renders — this app is mobile-first (this is
    // `mobile-app/`) and real payments need a native device/emulator
    // anyway, so skip Stripe init on web rather than crashing app startup.
    if (kIsWeb) return;
    Stripe.publishableKey = dotenv.get('STRIPE_PUBLISHABLE_KEY');
    await Stripe.instance.applySettings();
  }

  /// Buys [listingIds] (one listing for "Buy Now", several for cart
  /// checkout) — creates the order server-side and presents Stripe's
  /// native Payment Sheet. Returns the new order id on success, or throws
  /// a [StripeCheckoutException] with a message safe to show the user
  /// (either a validation error from the server, e.g. "seller hasn't
  /// finished payment setup yet", or "cancelled" if the sheet was
  /// dismissed).
  static Future<String> buyListings(
    List<String> listingIds, {
    Map<String, ShippingSelection> shipping = const {},
  }) async {
    final response = await SupabaseService.client.functions.invoke(
      'stripe-create-checkout',
      body: {
        'listingIds': listingIds,
        if (shipping.isNotEmpty)
          'shipping': shipping.map((id, sel) => MapEntry(id, sel.toJson())),
      },
    );
    final data = response.data as Map<String, dynamic>;
    if (data['error'] != null) {
      throw StripeCheckoutException(data['error'] as String);
    }

    final clientSecret = data['clientSecret'] as String;
    final orderId = data['orderId'] as String;

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Literature',
      ),
    );

    try {
      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        throw StripeCheckoutException('cancelled');
      }
      throw StripeCheckoutException(
          e.error.localizedMessage ?? 'Payment failed. Please try again.');
    }

    return orderId;
  }

  /// Starts (or resumes) Stripe Connect onboarding for the signed-in user
  /// so they can receive payouts as a seller — opens the Stripe-hosted
  /// onboarding flow in the system browser (Stripe-hosted onboarding
  /// doesn't work inside an app webview). Throws [StripeCheckoutException]
  /// if the browser tab couldn't be opened — on web in particular, a
  /// browser's popup blocker can silently block `launchUrl` here, since it
  /// fires after an `await` (the Edge Function call above) rather than
  /// perfectly synchronously inside the button tap.
  static Future<void> startSellerOnboarding() async {
    final response = await SupabaseService.client.functions.invoke(
      'stripe-connect-onboarding',
    );
    final data = response.data as Map<String, dynamic>;
    if (data['error'] != null) {
      throw StripeCheckoutException(data['error'] as String);
    }
    final url = Uri.parse(data['url'] as String);
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened) {
      throw StripeCheckoutException(
          "Couldn't open the Stripe setup page — your browser may have blocked the popup. Try allowing popups for this site and tap Connect again.");
    }
  }
}

class StripeCheckoutException implements Exception {
  final String message;
  const StripeCheckoutException(this.message);

  @override
  String toString() => message;
}
