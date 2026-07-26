import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/marketplace.dart';
import '../providers/marketplace_account_provider.dart';
import '../providers/marketplace_provider.dart';

/// Resolves a listing by id across the full browsable catalogue (seeded +
/// user-created listings, via [marketplaceListingsProvider]) and the current
/// user's purchase history. Lets UI that only has a listing id — e.g. a
/// post's `linkedListingId` — show full listing details (title, price,
/// cover) without duplicating this lookup in every widget.
MarketplaceListing? findListingById(WidgetRef ref, String id) {
  final catalogue = ref.read(marketplaceListingsProvider);
  final match = catalogue.where((l) => l.id == id).firstOrNull;
  if (match != null) return match;

  final purchases = ref.read(purchasesProvider);
  return purchases.map((p) => p.listing).where((l) => l.id == id).firstOrNull;
}
