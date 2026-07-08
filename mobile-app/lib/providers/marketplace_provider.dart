import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/marketplace.dart';
import '../models/post.dart';

enum MarketplacePriceSort { none, lowToHigh, highToLow }

final marketplaceListingsProvider = Provider<List<MarketplaceListing>>(
  (_) => mockListings,
);

final marketplaceTabProvider = StateProvider<ListingType>(
  (_) => ListingType.physical,
);

final marketplaceCategoryFilterProvider =
    StateProvider<ContentCategory?>((_) => null);

final marketplacePriceSortProvider =
    StateProvider<MarketplacePriceSort>((_) => MarketplacePriceSort.none);

/// Listings filtered by category + price sort only (NOT by type).
/// Each tab then further filters by its own [ListingType].
final filteredListingsProvider = Provider<List<MarketplaceListing>>((ref) {
  final category = ref.watch(marketplaceCategoryFilterProvider);
  final priceSort = ref.watch(marketplacePriceSortProvider);

  var listings = mockListings.toList();

  if (category != null) {
    listings = listings.where((l) => l.contentCategory == category).toList();
  }

  if (priceSort == MarketplacePriceSort.lowToHigh) {
    listings.sort((a, b) => _parsePrice(a.price).compareTo(_parsePrice(b.price)));
  } else if (priceSort == MarketplacePriceSort.highToLow) {
    listings.sort((a, b) => _parsePrice(b.price).compareTo(_parsePrice(a.price)));
  }

  return listings;
});

double _parsePrice(String price) =>
    double.tryParse(price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
