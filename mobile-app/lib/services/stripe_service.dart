import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;
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
    // Stripe is never initialised on web (see [init]), so the Payment Sheet
    // can't open there.
    if (kIsWeb) {
      throw const StripeCheckoutException(
        'Checkout works in the Literature app on your phone.',
      );
    }
    final data = await invokeEdgeFunction(
      'stripe-create-checkout',
      body: {
        'listingIds': listingIds,
        if (shipping.isNotEmpty)
          'shipping': shipping.map((id, sel) => MapEntry(id, sel.toJson())),
      },
    );

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
        e.error.localizedMessage ?? 'Payment failed. Please try again.',
      );
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
    final data = await invokeEdgeFunction('stripe-connect-onboarding');
    final url = Uri.parse(data['url'] as String);
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!opened) {
      throw StripeCheckoutException(
        "Couldn't open the Stripe setup page. Your browser may have blocked the popup. Allow popups for this site and tap Connect again.",
      );
    }
  }
}

/// Calls a Supabase Edge Function and returns its JSON body.
///
/// functions_client throws [FunctionException] for every non-2xx response,
/// so the server's `{error: "..."}` message (e.g. "seller hasn't finished
/// payment setup yet") only arrives in `e.details`. This rethrows it as a
/// [StripeCheckoutException] the UI can show as-is.
Future<Map<String, dynamic>> invokeEdgeFunction(
  String name, {
  Map<String, dynamic>? body,
}) async {
  try {
    final response = await SupabaseService.client.functions.invoke(
      name,
      body: body,
    );
    final data = response.data;
    return data is Map<String, dynamic> ? data : const {};
  } on FunctionException catch (e) {
    final details = e.details;
    final message = details is Map ? details['error'] : null;
    if (message is String && message.isNotEmpty) {
      throw StripeCheckoutException(message);
    }
    rethrow;
  }
}

class StripeCheckoutException implements Exception {
  final String message;
  const StripeCheckoutException(this.message);

  @override
  String toString() => message;
}
