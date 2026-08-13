import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/marketplace.dart';
import '../providers/auth_provider.dart';
import '../providers/marketplace_account_provider.dart';
import '../services/stripe_service.dart';
import '../widgets/shipping_method_sheet.dart';

/// Runs the real Stripe checkout for [listings] — one item for "Buy Now",
/// several for cart checkout — and shows the resulting SnackBar. Shared by
/// every buy entry point (listing detail, the feed's buy sheet, cart
/// checkout, and Library's "Add to Library") so they don't each duplicate
/// the Payment Sheet error handling. Returns whether the purchase
/// completed; a user-cancelled Payment Sheet returns false silently.
Future<bool> runPurchaseFlow(
  BuildContext context,
  WidgetRef ref,
  List<MarketplaceListing> listings,
) async {
  final buyerId = ref.read(currentUserProvider)?.id;
  if (buyerId == null) return false;

  // Physical listings the seller set up shipping methods for need the
  // buyer's choice (and, for Meetup, a suggested place) before payment
  // starts. Skipped entirely — returns {} immediately — when nothing in
  // the cart needs it. A null result means the buyer backed out.
  final shipping = await pickShippingMethods(context, listings);
  if (shipping == null) return false;
  if (!context.mounted) return false;

  // A lightweight non-dismissible spinner around the await — every buy
  // entry point here is a stateless bottom sheet or list row, so this is
  // simpler than threading a loading flag through each one, and it blocks
  // double-taps while the Payment Sheet is being set up.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  Future<void> dismissSpinner() async {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  return _runWithSpinner(
    context,
    dismissSpinner,
    action: () => ref
        .read(purchasesProvider.notifier)
        .buyListings(listings, buyerId: buyerId, shipping: shipping),
    successMessage: listings.length == 1
        ? '"${listings.first.title}" purchased! Check your Library.'
        : 'Purchase complete! Check your Library.',
  );
}

/// Claims a Free or Swap [listing] — no payment involved, so it skips the
/// Stripe Payment Sheet entirely but otherwise mirrors [runPurchaseFlow]:
/// same shipping-method step (Pickup/Meetup still need coordinating even
/// when nothing's being paid), same spinner/error handling.
Future<bool> runClaimFlow(
  BuildContext context,
  WidgetRef ref,
  MarketplaceListing listing,
) async {
  final buyerId = ref.read(currentUserProvider)?.id;
  if (buyerId == null) return false;

  final shipping = await pickShippingMethods(context, [listing]);
  if (shipping == null) return false;
  if (!context.mounted) return false;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  Future<void> dismissSpinner() async {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  return _runWithSpinner(
    context,
    dismissSpinner,
    action: () => ref.read(purchasesProvider.notifier).claimListing(
          listing,
          buyerId: buyerId,
          shipping: shipping[listing.id],
        ),
    successMessage: '"${listing.title}" claimed! Check your Library.',
  );
}

/// Shared tail of both flows above: run [action], dismiss the spinner, and
/// show the right SnackBar for success / cancellation / failure. Returns
/// whether it completed.
Future<bool> _runWithSpinner(
  BuildContext context,
  Future<void> Function() dismissSpinner, {
  required Future<void> Function() action,
  required String successMessage,
}) async {
  try {
    await action();
    await dismissSpinner();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(successMessage),
        behavior: SnackBarBehavior.floating,
      ));
    }
    return true;
  } on StripeCheckoutException catch (e) {
    await dismissSpinner();
    if (e.message == 'cancelled') return false;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        behavior: SnackBarBehavior.floating,
      ));
    }
    return false;
  } catch (_) {
    // Anything else (no network, Supabase unreachable, ...) — show a
    // generic message rather than letting it surface as a crash.
    await dismissSpinner();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Something went wrong. Please try again.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
    return false;
  }
}
