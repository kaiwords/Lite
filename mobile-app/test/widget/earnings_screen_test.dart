// Functional coverage for EarningsScreen (`/profile/earnings`): the totals
// and orderings it derives from its internal mock tips, and navigation from
// a tip row / top-supporter chip to that tipper's `/user/:id`.
//
// The mock tip data (`_mockTips` in earnings_screen.dart) is private to that
// file, so rather than hardcoding amounts mirrored from its source (which
// would silently drift if that data changes), these tests read the numbers
// back out of the rendered widget tree and check them for *internal*
// consistency: the total matches the sum of the visible line items, the top
// supporters are actually sorted descending, the recent tips are actually
// sorted newest-first, and a tapped row/chip actually leads to the profile
// of the person it displayed.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:literature/app.dart';
import 'package:literature/models/user.dart';
import 'package:literature/providers/auth_provider.dart';
import 'package:literature/router/app_router.dart';
import 'package:literature/screens/profile/user_profile_screen.dart';

import '../helpers/test_env.dart';

/// Pumps the full app (real router, real providers unless overridden) and
/// returns after the initial route has settled — mirrors the pattern in
/// test/overflow_test.dart.
Future<void> _pumpApp(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(overrides: overrides, child: const LiteratureApp()),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Navigates the shared [appRouter] to [location] and pumps enough frames
/// for the route to settle, without pumpAndSettle (see overflow_test.dart).
Future<void> _goTo(WidgetTester tester, String location) async {
  appRouter.go(location);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

// "Total earned" — a bare "$225.00", never followed by other characters.
final _totalRe = RegExp(r'^\$(\d+\.\d{2})$');
// A top-supporter chip's amount — "$125", no decimals (toStringAsFixed(0)).
final _chipAmountRe = RegExp(r'^\$(\d+)$');
// A _TipRow subtitle — "3h ago · +$50.00" (age unit + signed amount).
final _tipSubtitleRe = RegExp(r'^(\d+)(m|h|d|w) ago · \+\$(\d+\.\d{2})$');

double _ageInMinutes(String value, String unit) {
  final n = double.parse(value);
  switch (unit) {
    case 'm':
      return n;
    case 'h':
      return n * 60;
    case 'd':
      return n * 1440;
    case 'w':
      return n * 10080;
    default:
      throw ArgumentError('unknown unit: $unit');
  }
}

void main() {
  final currentUser = mockUsers.first; // u1, Eleanor Voss

  setUp(() async {
    await initTestEnv();
  });

  Future<void> pumpEarnings(WidgetTester tester) async {
    // Tall viewport: the "Recent tips" ListView only lazily builds the
    // rows that fit on screen, and several assertions below read every
    // tip's text out of the widget tree — a viewport too short to fit
    // all of them would silently make those tests see a truncated list
    // rather than the real one.
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpApp(
      tester,
      overrides: [currentUserProvider.overrideWith((ref) => currentUser)],
    );
    await _goTo(tester, '/profile/earnings');
  }

  List<String> allTexts(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .toList();

  testWidgets(
    'total earned is positive and equals the sum of every recent-tip amount',
    (tester) async {
      await pumpEarnings(tester);
      final texts = allTexts(tester);

      final totalMatches = texts
          .map((s) => _totalRe.firstMatch(s))
          .whereType<RegExpMatch>()
          .toList();
      expect(
        totalMatches,
        hasLength(1),
        reason: 'exactly one "Total earned" amount should be on screen',
      );
      final total = double.parse(totalMatches.single.group(1)!);
      expect(total, greaterThan(0));

      final tipAmounts = texts
          .map((s) => _tipSubtitleRe.firstMatch(s))
          .whereType<RegExpMatch>()
          .map((m) => double.parse(m.group(3)!))
          .toList();
      expect(tipAmounts, isNotEmpty);

      final sumOfTips = tipAmounts.fold<double>(0, (a, b) => a + b);
      expect(total, closeTo(sumOfTips, 0.001));
    },
  );

  testWidgets('top supporters are ordered by descending total tip amount', (
    tester,
  ) async {
    await pumpEarnings(tester);
    final texts = allTexts(tester);

    // Each chip renders its dollar amount immediately followed (in build
    // order: avatar initial, amount, "N× · Name" label) by its
    // supporter label, so pairing consecutive matches reconstructs the
    // chips in their on-screen left-to-right order.
    final chipAmounts = <int>[];
    for (var i = 0; i < texts.length - 1; i++) {
      final m = _chipAmountRe.firstMatch(texts[i]);
      if (m != null) chipAmounts.add(int.parse(m.group(1)!));
    }
    expect(chipAmounts, isNotEmpty);

    for (var i = 1; i < chipAmounts.length; i++) {
      expect(
        chipAmounts[i],
        lessThanOrEqualTo(chipAmounts[i - 1]),
        reason: 'top supporters must be sorted highest total first',
      );
    }
  });

  testWidgets('recent tips are ordered newest-first', (tester) async {
    await pumpEarnings(tester);
    final texts = allTexts(tester);

    final ages = texts
        .map((s) => _tipSubtitleRe.firstMatch(s))
        .whereType<RegExpMatch>()
        .map((m) => _ageInMinutes(m.group(1)!, m.group(2)!))
        .toList();
    expect(ages.length, greaterThan(1));

    for (var i = 1; i < ages.length; i++) {
      expect(
        ages[i],
        greaterThanOrEqualTo(ages[i - 1]),
        reason: 'recent tips must be sorted newest (smallest age) first',
      );
    }
  });

  testWidgets("tapping a tip row navigates to that tipper's profile", (
    tester,
  ) async {
    await pumpEarnings(tester);

    final firstTile = find.byType(ListTile).first;
    final tileTexts = tester
        .widgetList<Text>(
          find.descendant(of: firstTile, matching: find.byType(Text)),
        )
        .map((t) => t.data)
        .whereType<String>();
    // The tile also contains the leading avatar's single-letter initial
    // (also "$"/"·"-free), so match against known display names rather
    // than just excluding the subtitle's punctuation.
    final nameText = tileTexts.firstWhere(
      (s) => mockUsers.any((u) => u.displayName == s),
    );

    final tappedUser = mockUsers.firstWhere((u) => u.displayName == nameText);

    await tester.tap(firstTile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(UserProfileScreen), findsOneWidget);
    final screen = tester.widget<UserProfileScreen>(
      find.byType(UserProfileScreen),
    );
    expect(screen.userId, tappedUser.id);
  });

  testWidgets(
    "tapping a top-supporter chip navigates to that tipper's profile",
    (tester) async {
      await pumpEarnings(tester);
      final texts = allTexts(tester);

      int? firstChipAmount;
      String? firstChipLabel;
      for (var i = 0; i < texts.length - 1; i++) {
        final m = _chipAmountRe.firstMatch(texts[i]);
        if (m != null) {
          firstChipAmount = int.parse(m.group(1)!);
          firstChipLabel = texts[i + 1];
          break;
        }
      }
      expect(firstChipAmount, isNotNull);
      // Label is "N× · FirstName" — the tipper's first name only.
      final firstName = firstChipLabel!.split('·').last.trim();

      await tester.tap(find.text('\$$firstChipAmount').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(UserProfileScreen), findsOneWidget);
      final screen = tester.widget<UserProfileScreen>(
        find.byType(UserProfileScreen),
      );
      final tappedUser = mockUsers.firstWhere((u) => u.id == screen.userId);
      expect(tappedUser.displayName.split(' ').first, firstName);
    },
  );
}
