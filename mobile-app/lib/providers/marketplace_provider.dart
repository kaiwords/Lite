import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/marketplace.dart';
import '../services/marketplace_repository.dart';
import 'marketplace_account_provider.dart';

/// The shared browsable catalogue, seeded synchronously from [mockListings]
/// and then refreshed from Supabase once the live data loads.
class CatalogueNotifier extends StateNotifier<List<MarketplaceListing>> {
  CatalogueNotifier(super.initial);

  Future<void> loadFromSupabase() async {
    try {
      final remote = await MarketplaceRepository.fetchAll();
      if (remote.isNotEmpty) state = remote;
    } catch (_) {
      // Offline or request failed — keep the mock catalogue already shown.
    }
  }
}

final catalogueProvider =
    StateNotifierProvider<CatalogueNotifier, List<MarketplaceListing>>((ref) {
  final notifier = CatalogueNotifier(mockListings);
  notifier.loadFromSupabase();
  return notifier;
});

/// The full browsable catalogue: [catalogueProvider] plus any listings the
/// user has created through the sell flow ([myListingsProvider]) that aren't
/// already part of it. This is the single source of truth for Browse/Search —
/// listings created via "My Listings" must show up here too, not just under
/// the seller's own listings tab.
final marketplaceListingsProvider = Provider<List<MarketplaceListing>>((ref) {
  final catalogue = ref.watch(catalogueProvider);
  final myListings = ref.watch(myListingsProvider);
  final catalogueIds = catalogue.map((l) => l.id).toSet();
  final ownOnly = myListings.where((l) => !catalogueIds.contains(l.id));
  return [...catalogue, ...ownOnly];
});
