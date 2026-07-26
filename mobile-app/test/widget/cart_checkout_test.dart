import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literature/models/marketplace.dart';
import 'package:literature/providers/marketplace_account_provider.dart';
import 'package:literature/screens/marketplace/cart_tab.dart';

import '../helpers/test_env.dart';

const _bookA = MarketplaceListing(
  id: 'cart-a',
  title: 'Cart Book A',
  authorName: 'Author A',
  price: '\$10.00',
  type: ListingType.physical,
  rating: 4.0,
  reviewCount: 1,
);

const _bookB = MarketplaceListing(
  id: 'cart-b',
  title: 'Cart Book B',
  authorName: 'Author B',
  price: '\$5.50',
  type: ListingType.ebook,
  rating: 4.5,
  reviewCount: 2,
);

void main() {
  setUp(() async {
    await initTestEnv();
  });

  Future<ProviderContainer> pumpCart(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: CartTab(isDark: false)),
        ),
      ),
    );
    await tester.pump();
    return ProviderScope.containerOf(
      tester.element(find.byType(CartTab)),
    );
  }

  testWidgets('empty cart shows the empty state', (tester) async {
    await pumpCart(tester);
    expect(find.text('Your cart is empty'), findsOneWidget);
  });

  testWidgets('items render with a correct subtotal', (tester) async {
    final container = await pumpCart(tester);
    container.read(cartProvider.notifier)
      ..add(_bookA)
      ..add(_bookB);
    await tester.pump();

    expect(find.text('Cart Book A'), findsOneWidget);
    expect(find.text('Cart Book B'), findsOneWidget);
    // $10.00 + $5.50 — shown in the subtotal row and on the checkout button.
    expect(find.text('\$15.50'), findsOneWidget);
    expect(find.text('Checkout · \$15.50'), findsOneWidget);
  });

  testWidgets('adding the same listing twice keeps one row', (tester) async {
    final container = await pumpCart(tester);
    container.read(cartProvider.notifier)
      ..add(_bookA)
      ..add(_bookA);
    await tester.pump();
    expect(find.text('Cart Book A'), findsOneWidget);
    expect(find.text('\$10.00'), findsOneWidget);
  });

  testWidgets('remove button takes the row out and updates the total',
      (tester) async {
    final container = await pumpCart(tester);
    container.read(cartProvider.notifier)
      ..add(_bookA)
      ..add(_bookB);
    await tester.pump();

    await tester.tap(find.byTooltip('Remove').first);
    await tester.pump();

    expect(find.text('Cart Book A'), findsNothing);
    expect(find.text('Checkout · \$5.50'), findsOneWidget);
  });

  testWidgets('checkout moves every cart item into purchases and clears it',
      (tester) async {
    final container = await pumpCart(tester);
    container.read(cartProvider.notifier)
      ..add(_bookA)
      ..add(_bookB);
    await tester.pump();

    await tester.tap(find.textContaining('Checkout'));
    await tester.pump();

    // Cart cleared → empty state back on screen, snackbar confirms.
    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(
        find.text('Purchase complete! ✨ Check your Library.'), findsOneWidget);
    expect(container.read(cartProvider), isEmpty);

    final purchases = container.read(purchasesProvider.notifier);
    expect(purchases.contains(_bookA.id), isTrue);
    expect(purchases.contains(_bookB.id), isTrue);
  });
}
