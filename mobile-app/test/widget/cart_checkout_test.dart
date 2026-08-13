import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literature/models/marketplace.dart';
import 'package:literature/models/user.dart';
import 'package:literature/providers/auth_provider.dart';
import 'package:literature/providers/marketplace_account_provider.dart';
import 'package:literature/screens/marketplace/cart_tab.dart';

import '../helpers/test_env.dart';

const _testUser = LitUser(id: 'test-user-id', username: 'tester', displayName: 'Tester');

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
      ProviderScope(
        overrides: [currentUserProvider.overrideWith((ref) => _testUser)],
        child: const MaterialApp(
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
    // $10.00 + $5.50 — shown in the subtotal row.
    expect(find.text('\$15.50'), findsOneWidget);
    expect(find.text('Checkout'), findsOneWidget);
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
    expect(find.text('Cart Book B'), findsOneWidget);
    // Subtotal updates to the remaining item's price — which now happens to
    // match that same row's own price label, so there are two instances.
    expect(find.text('\$5.50'), findsNWidgets(2));
    expect(find.text('Checkout'), findsOneWidget);
  });

  testWidgets(
      'checkout attempts real Stripe checkout without crashing and leaves '
      'the cart alone when it fails', (tester) async {
    // Checkout now goes through Stripe (stripe-create-checkout + the native
    // Payment Sheet) instead of an instant local purchase, so there's no
    // real backend here for it to succeed against. Bounded pumps instead of
    // pumpAndSettle — the loading spinner shown during the await is an
    // indeterminate CircularProgressIndicator, which never lets
    // pumpAndSettle converge on its own.
    final container = await pumpCart(tester);
    container.read(cartProvider.notifier)
      ..add(_bookA)
      ..add(_bookB);
    await tester.pump();

    await tester.tap(find.textContaining('Checkout'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }

    // Cart is left untouched rather than optimistically cleared.
    expect(container.read(cartProvider).length, 2);
  });
}
