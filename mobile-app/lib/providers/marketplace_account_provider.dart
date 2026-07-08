import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/marketplace.dart';
import '../services/local_store.dart';

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
  final MarketplaceListing listing;
  final DateTime purchasedAt;
  final String orderId;
  const Purchase({
    required this.listing,
    required this.purchasedAt,
    required this.orderId,
  });

  Map<String, dynamic> toJson() => {
        'listing': listing.toJson(),
        'purchasedAt': purchasedAt.toIso8601String(),
        'orderId': orderId,
      };

  factory Purchase.fromJson(Map<String, dynamic> j) => Purchase(
        listing:
            MarketplaceListing.fromJson((j['listing'] as Map).cast<String, dynamic>()),
        purchasedAt: DateTime.parse(j['purchasedAt'] as String),
        orderId: j['orderId'] as String,
      );
}

class PurchasesNotifier extends StateNotifier<List<Purchase>> {
  PurchasesNotifier(super.initial);

  /// Default purchases seeded on first launch (before any persistence exists).
  static List<Purchase> seed() => [
        Purchase(
          listing: mockListings.last, // The Ember Throne (eBook)
          purchasedAt: DateTime.now().subtract(const Duration(days: 1)),
          orderId: 'ORD-00422',
        ),
        Purchase(
          listing: mockListings[4], // The Iron Kingdom (Physical)
          purchasedAt: DateTime.now().subtract(const Duration(days: 3)),
          orderId: 'ORD-00421',
        ),
        Purchase(
          listing: mockListings[8], // Before the Storm Breaks
          purchasedAt: DateTime.now().subtract(const Duration(days: 10)),
          orderId: 'ORD-00389',
        ),
        Purchase(
          listing: mockListings[0], // The Glass House (Physical)
          purchasedAt: DateTime.now().subtract(const Duration(days: 21)),
          orderId: 'ORD-00301',
        ),
      ];

  void add(Purchase purchase) => state = [purchase, ...state];

  void remove(String listingId) =>
      state = state.where((p) => p.listing.id != listingId).toList();

  bool contains(String listingId) =>
      state.any((p) => p.listing.id == listingId);
}

final purchasesProvider =
    StateNotifierProvider<PurchasesNotifier, List<Purchase>>((ref) {
  final notifier =
      PurchasesNotifier(LocalStore.instance.loadPurchases() ?? PurchasesNotifier.seed());
  notifier.addListener(LocalStore.instance.savePurchases,
      fireImmediately: false);
  return notifier;
});

// ─────────────────────────────────────────────────────────────────────────────
// Sales (the current user's own listings that have sold)
// ─────────────────────────────────────────────────────────────────────────────

class Sale {
  final MarketplaceListing listing;
  final DateTime soldAt;
  final String buyerName;
  final double amount;
  const Sale({
    required this.listing,
    required this.soldAt,
    required this.buyerName,
    required this.amount,
  });
}

class SalesNotifier extends StateNotifier<List<Sale>> {
  SalesNotifier()
      : super([
          // Seed mock sales for Eleanor Voss (current user)
          Sale(
            listing: mockListings[8], // Between the Lines (Audio)
            soldAt: DateTime.now().subtract(const Duration(hours: 4)),
            buyerName: 'Priya Nair',
            amount: 8.99,
          ),
          Sale(
            listing: mockListings[0], // The Glass House (Physical)
            soldAt: DateTime.now().subtract(const Duration(days: 1)),
            buyerName: 'marcus_ink',
            amount: 14.99,
          ),
          Sale(
            listing: mockListings[2], // Midnight Verses (Physical)
            soldAt: DateTime.now().subtract(const Duration(days: 2)),
            buyerName: 'luna_reads',
            amount: 11.99,
          ),
          Sale(
            listing: mockListings[8], // Between the Lines (Audio)
            soldAt: DateTime.now().subtract(const Duration(days: 4)),
            buyerName: 'javier_poetic',
            amount: 8.99,
          ),
          Sale(
            listing: mockListings[0], // The Glass House (Physical)
            soldAt: DateTime.now().subtract(const Duration(days: 7)),
            buyerName: 'ink_and_fire',
            amount: 14.99,
          ),
        ]);

  void add(Sale sale) => state = [sale, ...state];
}

final salesProvider =
    StateNotifierProvider<SalesNotifier, List<Sale>>(
        (ref) => SalesNotifier());

// ─────────────────────────────────────────────────────────────────────────────
// My Listings (books the current user has listed for sale)
// ─────────────────────────────────────────────────────────────────────────────

class MyListingsNotifier extends StateNotifier<List<MarketplaceListing>> {
  MyListingsNotifier(super.initial);

  /// Eleanor Voss's existing listings, seeded on first launch.
  static List<MarketplaceListing> seed() => [
        mockListings[0], // The Glass House
        mockListings[2], // Midnight Verses
        mockListings[8], // Between the Lines (Audio)
      ];

  void add(MarketplaceListing listing) => state = [listing, ...state];

  void remove(String id) =>
      state = state.where((l) => l.id != id).toList();

  void update(MarketplaceListing updated) => state = [
        for (final l in state) if (l.id == updated.id) updated else l,
      ];
}

final myListingsProvider =
    StateNotifierProvider<MyListingsNotifier, List<MarketplaceListing>>((ref) {
  final notifier = MyListingsNotifier(
      LocalStore.instance.loadMyListings() ?? MyListingsNotifier.seed());
  notifier.addListener(LocalStore.instance.saveMyListings,
      fireImmediately: false);
  return notifier;
});
