// Regression suite: pumps every major screen reachable from app_router.dart
// (plus a few high-risk sheets/editors called out during a recent UI push)
// at common narrow-phone widths and asserts no `RenderFlex overflowed`
// (or any other) error was thrown during layout.
//
// Widths covered: 320x568 (iPhone SE — narrowest common phone) and
// 360x690 (a common small Android). These are the sizes most likely to
// surface a fixed-width Row/Text that doesn't wrap or ellipsize.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:literature/app.dart';
import 'package:literature/models/marketplace.dart';
import 'package:literature/models/user.dart';
// AUDIO DISABLED (2026-09-30): book/e-book only for now.
// import 'package:literature/providers/audio_provider.dart';
import 'package:literature/providers/auth_provider.dart';
import 'package:literature/router/app_router.dart';
// import 'package:literature/screens/audio/audiobook_player_screen.dart'; // Audio disabled
import 'package:literature/screens/marketplace/list_item_sheet.dart';
import 'package:literature/widgets/listing_buy_sheet.dart';
import 'package:literature/widgets/tip_sheet.dart';

import 'helpers/test_env.dart';

// AUDIO DISABLED (2026-09-30):
// /// Stands in for [AudioPlayerController] in tests: [AudiobookPlayerScreen]
// /// starts real playback in `initState`, and the real controller hits the
// /// network via `just_audio` — in the sandboxed test environment that
// /// connection attempt doesn't fail fast, it hangs for many minutes before
// /// timing out. Overriding `playQueue`/`stop` to no-ops keeps the test
// /// exercising real layout code without ever touching the network.
// class _NoopAudioController extends AudioPlayerController {
//   @override
//   Future<void> playQueue(List<AudioTrack> tracks, {int startIndex = 0}) async {}
//
//   @override
//   void stop() {}
// }

const _sizes = {
  'iPhone SE (320x568)': Size(320, 568),
  'small Android (360x690)': Size(360, 690),
};

/// Sets the test surface to [size] at devicePixelRatio 1.0, restoring the
/// default afterwards via [addTearDown].
void _setScreenSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Pumps the full app (real router, real providers unless overridden) and
/// returns after the initial route has settled.
///
/// `currentUserProvider` is seeded with a real mock user by default — it's
/// never populated by the test Supabase setup (see `helpers/test_env.dart`),
/// and several screens (profile, settings, followers/following, earnings…)
/// null-guard on it with a loading spinner. Without this default, every one
/// of those routes would only ever render (and overflow-check) that spinner
/// instead of its real content. Pass a `currentUserProvider` override in
/// [overrides] to replace this default, e.g. to exercise the logged-out case.
Future<void> _pumpApp(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => mockUsers.first),
        ...overrides,
      ],
      child: const LiteratureApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Navigates the shared [appRouter] to [location] (optionally with `extra`)
/// and pumps enough frames for the route + its finite entrance animations to
/// settle, without using pumpAndSettle (some screens start real, possibly
/// never-resolving async work — e.g. audio playback — that would time it out).
Future<void> _goTo(
  WidgetTester tester,
  String location, {
  Object? extra,
}) async {
  appRouter.go(location, extra: extra);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

/// Asserts no exception (e.g. a `RenderFlex overflowed` FlutterError) was
/// recorded during the test so far.
///
/// `tester.takeException()` only returns (and clears) a *single* pending
/// exception. A widget that overflows on every one of the several pump()
/// calls above records one exception per layout pass, so a single
/// `takeException()` call leaves the rest sitting in the binding's queue —
/// they then get misattributed to (and fail) whichever *next* test happens
/// to run, cascading a single real bug into dozens of unrelated failures.
/// Draining the queue fully here keeps each test's failure isolated to
/// itself.
void _expectNoOverflow(WidgetTester tester, String context) {
  final exceptions = <Object>[];
  Object? next;
  while ((next = tester.takeException()) != null) {
    exceptions.add(next!);
  }
  expect(
    exceptions,
    isEmpty,
    reason:
        'Overflow (or other error) rendering $context:\n'
        '${exceptions.join('\n\n')}',
  );
}

void main() {
  setUp(() async {
    await initTestEnv();
  });

  for (final entry in _sizes.entries) {
    group(entry.key, () {
      final size = entry.value;

      // Each route exercised from app_router.dart, with realistic mock args
      // matching the shapes app_router.dart expects.
      final routes = <String, Object?>{
        '/': null,
        // '/audio': null, // Audio disabled — route is commented out
        '/marketplace': null,
        '/alerts': null,
        '/profile': null,
        '/profile/followers': null,
        '/profile/following': null,
        '/profile/earnings': null,
        '/settings': null,
        '/post/new': null,
        '/search': null,
        '/messages': null,
        // Plain social conversation.
        '/messages/u2': null,
        // Marketplace-context conversation — renders the "About: <listing>"
        // label row under the peer name (`contextLabel` in conversation.dart);
        // 'sc2' has one of the longer labels ("Echoes in the Dark (E-Book)").
        '/messages/sc2': null,
        '/marketplace/notifications': null,
        '/marketplace/messages': null,
        // Physical book.
        '/marketplace/listing/m1': null,
        // E-book.
        '/marketplace/listing/m5': null,
        // Audio disabled: the m9 audio listing is commented out of the demo
        // data, so its detail route has nothing to render.
        // '/marketplace/listing/m9': null,
        // E-book listed via the chapter-builder (has ebookChapters).
        '/marketplace/listing/mBook1': null,
        '/user/u1': null,
        '/viewer/0': null,
        '/reader/b1': null,
      };

      for (final routeEntry in routes.entries) {
        testWidgets('${routeEntry.key} has no overflow', (tester) async {
          _setScreenSize(tester, size);
          await _pumpApp(tester);
          await _goTo(tester, routeEntry.key, extra: routeEntry.value);

          _expectNoOverflow(tester, '${routeEntry.key} at $size');
        });
      }

      // ── Buy-now sheet on a marketplace badge (listing_buy_sheet.dart) ────
      testWidgets('listing buy sheet has no overflow', (tester) async {
        _setScreenSize(tester, size);
        await _pumpApp(tester);

        final context = tester.element(find.byType(Scaffold).first);
        // A long title/author stresses the two-line title + Buy Now row.
        const listing = MarketplaceListing(
          id: 'test-buy-sheet',
          title: 'The Extraordinarily Long and Winding Title of a Book',
          authorName: 'A Author With A Genuinely Very Long Display Name',
          price: '\$999.99',
          type: ListingType.physical,
          rating: 4.5,
          reviewCount: 10,
        );
        unawaited(showListingBuySheet(context, listing));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        _expectNoOverflow(tester, 'listing buy sheet at $size');
      });

      // ── Tip sheet (tip_sheet.dart) ────────────────────────────────────────
      testWidgets('tip sheet has no overflow', (tester) async {
        _setScreenSize(tester, size);
        await _pumpApp(tester);

        final context = tester.element(find.byType(Scaffold).first);
        unawaited(
          TipSheet.show(
            context,
            authorName: 'A Author With A Genuinely Very Long Display Name',
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        _expectNoOverflow(tester, 'tip sheet at $size');
      });

      // ── Audiobook player (audiobook_player_screen.dart) ──────────────────
      // AUDIO DISABLED (2026-09-30): the player screen is commented out, so
      // this test is too.
      // testWidgets('audiobook player has no overflow', (tester) async {
      //   _setScreenSize(tester, size);
      //   await _pumpApp(
      //     tester,
      //     overrides: [
      //       audioPlayerProvider.overrideWith((ref) => _NoopAudioController()),
      //     ],
      //   );
      //
      //   const listing = MarketplaceListing(
      //     id: 'test-audiobook',
      //     title: 'A Very Long Audiobook Title That Keeps Going',
      //     authorName: 'Eleanor Voss',
      //     price: '\$9.99',
      //     type: ListingType.audio,
      //     rating: 4.5,
      //     reviewCount: 10,
      //     audioVolumes: [
      //       AudioVolume(
      //         title: 'Volume One: The Extremely Long Chapter Name',
      //         fileName: 'a-very-long-original-upload-filename-track-01.mp3',
      //       ),
      //       AudioVolume(title: 'Vol. 2', fileName: 'short.mp3'),
      //     ],
      //   );
      //
      //   final context = tester.element(find.byType(Scaffold).first);
      //   // Note: deliberately not `await`ed — Navigator.push()'s Future only
      //   // completes when the route is later popped (never, here), not when
      //   // it's built; awaiting it would hang the test forever.
      //   unawaited(
      //     Navigator.of(context).push(
      //       MaterialPageRoute<void>(
      //         builder: (_) => const AudiobookPlayerScreen(listing: listing),
      //       ),
      //     ),
      //   );
      //   await tester.pump();
      //   await tester.pump(const Duration(milliseconds: 300));
      //   await tester.pump(const Duration(milliseconds: 300));
      //
      //   _expectNoOverflow(tester, 'audiobook player at $size');
      //
      //   // Pop before the test ends: AudiobookPlayerScreen.dispose() reads a
      //   // provider (`ref.read(audioPlayerProvider.notifier).stop()`), which
      //   // requires the ProviderScope to still be alive. If this screen is
      //   // left on the stack, the *next* test's pumpWidget() tears down the
      //   // whole tree (this screen + the ProviderScope) in the same pass,
      //   // and dispose() can run after the ProviderScope element is already
      //   // gone — throwing "Cannot use ref after the widget was disposed"
      //   // and cascading a StateError into unrelated later tests.
      //   Navigator.of(context).pop();
      //   await tester.pump();
      // });

      // ── Sell flow: List a Book sheet (Audio disabled 2026-09-30) ─────────
      testWidgets('list item sheet (ebook) has no overflow', (tester) async {
        _setScreenSize(tester, size);
        await _pumpApp(tester);

        final context = tester.element(find.byType(Scaffold).first);
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ListItemSheet(
              isDark: false,
              initialType: ListingType.ebook,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        _expectNoOverflow(tester, 'list item sheet (ebook) at $size');
      });

      // AUDIO DISABLED (2026-09-30): the audio sell flow is commented out.
      // testWidgets('list item sheet (audio) has no overflow', (tester) async {
      //   _setScreenSize(tester, size);
      //   await _pumpApp(tester);
      //
      //   final context = tester.element(find.byType(Scaffold).first);
      //   Navigator.of(context).push(
      //     MaterialPageRoute<void>(
      //       builder: (_) => const ListItemSheet(
      //         isDark: false,
      //         initialType: ListingType.audio,
      //       ),
      //     ),
      //   );
      //   await tester.pump();
      //   await tester.pump(const Duration(milliseconds: 300));
      //
      //   _expectNoOverflow(tester, 'list item sheet (audio) at $size');
      // });

      testWidgets('list item sheet (physical) has no overflow', (tester) async {
        _setScreenSize(tester, size);
        await _pumpApp(tester);

        final context = tester.element(find.byType(Scaffold).first);
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ListItemSheet(
              isDark: false,
              initialType: ListingType.physical,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Check Pickup and Meet Up so their conditional location/phone
        // fields (added 2026-08-13) actually render, since they're the
        // rows most likely to overflow on a narrow phone.
        final pickupChip = find.text('Pickup');
        await tester.scrollUntilVisible(
          pickupChip,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(pickupChip);
        await tester.pump();
        final meetupChip = find.text('Meet Up');
        await tester.scrollUntilVisible(
          meetupChip,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(meetupChip);
        await tester.pump();

        // Check Swap too, so the "what would you like in exchange" field
        // (added 2026-08-13) renders — the Price field it replaces is gone,
        // this is the row most likely to trip up that swap.
        final swapChip = find.text('Swap');
        await tester.scrollUntilVisible(
          swapChip,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(swapChip);
        await tester.pump();

        _expectNoOverflow(tester, 'list item sheet (physical) at $size');
      });

      // ── Chapter list editor + per-chapter editor, reached by editing an
      // existing chapter-built listing (mBook1 has no ebookChapters seeded,
      // so start from an in-memory listing that already has one, then open
      // the chapter list and the per-chapter "write" screen for it).
      testWidgets('chapter list + write-book editor have no overflow', (
        tester,
      ) async {
        _setScreenSize(tester, size);
        await _pumpApp(tester);

        const existing = MarketplaceListing(
          id: 'test-chapters',
          title: 'A Book Being Written Online',
          authorName: 'Eleanor Voss',
          price: '\$9.99',
          type: ListingType.ebook,
          rating: 0,
          reviewCount: 0,
          ebookChapters: [
            EbookChapter(
              title: 'An Extremely Long Chapter Title That Goes On And On',
              content: 'Some content.',
            ),
          ],
        );

        final context = tester.element(find.byType(Scaffold).first);
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                const ListItemSheet(isDark: false, existing: existing),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Sheet defaults to "Write online" source since chapters exist —
        // tap the chapters box to open the chapter list screen. On short
        // screens the sheet's Cover step (photo/design picker) pushes this
        // below the fold, so scroll it into view first instead of assuming
        // it's already on-screen.
        final chaptersBox = find.text('Continue writing');
        expect(chaptersBox, findsOneWidget);
        await tester.scrollUntilVisible(
          chaptersBox,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(chaptersBox);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        _expectNoOverflow(tester, 'chapter list at $size');

        // Open the existing (long-titled) chapter in the per-chapter editor.
        final chapterCard = find.text(
          'An Extremely Long Chapter Title That Goes On And On',
        );
        expect(chapterCard, findsOneWidget);
        await tester.tap(chapterCard);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        _expectNoOverflow(tester, 'write-book editor at $size');
      });

      // ── Marketplace section screens (Cart / My Library / My Listings /
      // Sales) — these are pushed via Navigator from the storefront's
      // quick-access pills on MarketplaceScreen rather than being GoRoutes,
      // so the route-table loop above never reaches them. (The old "Books"
      // section is gone: the storefront home *is* the book browse now, and
      // the '/marketplace' route pump above covers it.) They're exactly the
      // tabs that were recently split into cart_tab.dart/library_tab.dart/
      // my_listings_tab.dart/sales_tab.dart, so worth covering directly.
      for (final section in ['Cart', 'My Library', 'My Listings', 'Sales']) {
        testWidgets('marketplace "$section" section has no overflow', (
          tester,
        ) async {
          _setScreenSize(tester, size);
          await _pumpApp(tester);
          await _goTo(tester, '/marketplace');

          // The quick-access row scrolls horizontally — the pills are all
          // built (non-lazy row), and scrollUntilVisible's ensureVisible
          // reveals the later ones (e.g. "Sales") on narrow screens.
          await tester.scrollUntilVisible(
            find.text(section),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          // warnIfMissed: false — a pill can sit at the very edge of the
          // horizontal viewport after ensureVisible, which makes the
          // computed tap offset occasionally straddle a neighboring
          // render object even though the pill itself is visible.
          await tester.tap(find.text(section), warnIfMissed: false);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));

          _expectNoOverflow(tester, 'marketplace "$section" section at $size');
        });
      }
    });
  }

  // Regression check for a bug that slipped past the narrow-phone sizes
  // above: a grid tile's cover used AspectRatio(1), so its height scaled
  // with the cell width — but the grid itself uses a fixed mainAxisExtent.
  // On screens wide enough that a square cell exceeded that budget, the
  // tile's Column overflowed. Fixed by giving the cover a fixed height
  // instead. The book grid now sits directly on the marketplace storefront
  // ('/marketplace'), no tile tap needed. One-off, not part of the `_sizes`
  // matrix above, since it only needs to prove this width class is safe.
  testWidgets(
    'marketplace storefront book grid has no overflow on a wide phone (430x932)',
    (tester) async {
      _setScreenSize(tester, const Size(430, 932));
      await _pumpApp(tester);
      await _goTo(tester, '/marketplace');
      await tester.pump(const Duration(milliseconds: 300));

      // Confirms the storefront grid actually rendered (not some other
      // screen that just happened not to overflow) before trusting a clean
      // result.
      expect(find.textContaining('Showing'), findsOneWidget);
      _expectNoOverflow(tester, 'marketplace storefront grid at 430x932');
    },
  );
}
