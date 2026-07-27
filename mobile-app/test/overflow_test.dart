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
import 'package:literature/providers/audio_provider.dart';
import 'package:literature/providers/auth_provider.dart';
import 'package:literature/router/app_router.dart';
import 'package:literature/screens/audio/audiobook_player_screen.dart';
import 'package:literature/screens/marketplace/list_item_sheet.dart';
import 'package:literature/widgets/listing_buy_sheet.dart';
import 'package:literature/widgets/tip_sheet.dart';

import 'helpers/test_env.dart';

/// Stands in for [AudioPlayerController] in tests: [AudiobookPlayerScreen]
/// starts real playback in `initState`, and the real controller hits the
/// network via `just_audio` — in the sandboxed test environment that
/// connection attempt doesn't fail fast, it hangs for many minutes before
/// timing out. Overriding `playQueue`/`stop` to no-ops keeps the test
/// exercising real layout code without ever touching the network.
class _NoopAudioController extends AudioPlayerController {
  @override
  Future<void> playQueue(List<AudioTrack> tracks, {int startIndex = 0}) async {}

  @override
  void stop() {}
}

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
        '/audio': null,
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
        // 'sc2' has one of the longer labels ("Echoes in the Dark (Audio)").
        '/messages/sc2': null,
        '/marketplace/notifications': null,
        '/marketplace/messages': null,
        // Physical book.
        '/marketplace/listing/m1': null,
        // E-book.
        '/marketplace/listing/m5': null,
        // Audio book with a linked feed post.
        '/marketplace/listing/m9': null,
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
      // Volume rows now show both a seller-chosen title *and* the uploaded
      // filename (two lines where there used to be one), alongside a
      // duration label — a prime overflow candidate on narrow screens.
      testWidgets('audiobook player has no overflow', (tester) async {
        _setScreenSize(tester, size);
        await _pumpApp(
          tester,
          overrides: [
            audioPlayerProvider.overrideWith((ref) => _NoopAudioController()),
          ],
        );

        const listing = MarketplaceListing(
          id: 'test-audiobook',
          title: 'A Very Long Audiobook Title That Keeps Going',
          authorName: 'Eleanor Voss',
          price: '\$9.99',
          type: ListingType.audio,
          rating: 4.5,
          reviewCount: 10,
          audioVolumes: [
            AudioVolume(
              title: 'Volume One: The Extremely Long Chapter Name',
              fileName: 'a-very-long-original-upload-filename-track-01.mp3',
            ),
            AudioVolume(title: 'Vol. 2', fileName: 'short.mp3'),
          ],
        );

        final context = tester.element(find.byType(Scaffold).first);
        // Note: deliberately not `await`ed — Navigator.push()'s Future only
        // completes when the route is later popped (never, here), not when
        // it's built; awaiting it would hang the test forever.
        unawaited(
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AudiobookPlayerScreen(listing: listing),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        _expectNoOverflow(tester, 'audiobook player at $size');

        // Pop before the test ends: AudiobookPlayerScreen.dispose() reads a
        // provider (`ref.read(audioPlayerProvider.notifier).stop()`), which
        // requires the ProviderScope to still be alive. If this screen is
        // left on the stack, the *next* test's pumpWidget() tears down the
        // whole tree (this screen + the ProviderScope) in the same pass,
        // and dispose() can run after the ProviderScope element is already
        // gone — throwing "Cannot use ref after the widget was disposed"
        // and cascading a StateError into unrelated later tests.
        Navigator.of(context).pop();
        await tester.pump();
      });

      // ── Sell flow: List a Book sheet, both E-Book and Audio types ────────
      testWidgets('list item sheet (ebook) has no overflow', (tester) async {
        _setScreenSize(tester, size);
        await _pumpApp(tester);

        final context = tester.element(find.byType(Scaffold).first);
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const ListItemSheet(
            isDark: false,
            initialType: ListingType.ebook,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        _expectNoOverflow(tester, 'list item sheet (ebook) at $size');
      });

      testWidgets('list item sheet (audio) has no overflow', (tester) async {
        _setScreenSize(tester, size);
        await _pumpApp(tester);

        final context = tester.element(find.byType(Scaffold).first);
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const ListItemSheet(
            isDark: false,
            initialType: ListingType.audio,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        _expectNoOverflow(tester, 'list item sheet (audio) at $size');
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
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) =>
              const ListItemSheet(isDark: false, existing: existing),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Sheet defaults to "Write online" source since chapters exist —
        // tap the chapters box to open the chapter list screen.
        final chaptersBox = find.text('Continue writing');
        expect(chaptersBox, findsOneWidget);
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

      // ── Marketplace section screens (Books / Cart / My Library /
      // My Listings / Sales) — these are pushed via Navigator from the
      // section tiles on MarketplaceScreen rather than being GoRoutes, so
      // the route-table loop above never reaches them. They're exactly the
      // tabs that were recently split into cart_tab.dart/library_tab.dart/
      // my_listings_tab.dart/sales_tab.dart, so worth covering directly.
      for (final section in [
        'Books',
        'Cart',
        'My Library',
        'My Listings',
        'Sales',
      ]) {
        testWidgets('marketplace "$section" section has no overflow', (
          tester,
        ) async {
          _setScreenSize(tester, size);
          await _pumpApp(tester);
          await _goTo(tester, '/marketplace');

          // The section grid can need scrolling to reach later tiles (e.g.
          // "Sales") on short screens — scroll it into view first instead of
          // assuming it's already built/visible.
          await tester.scrollUntilVisible(
            find.text(section),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          // warnIfMissed: false — the tile can sit at the very edge of the
          // scrolled grid viewport (e.g. "Sales", the 5th/last tile, right
          // above the bottom nav bar on short screens), which makes the
          // computed tap offset occasionally straddle a neighboring
          // render object even though the tile itself is fully visible and
          // scrollUntilVisible() above already confirmed it's on-screen.
          await tester.tap(find.text(section), warnIfMissed: false);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));

          _expectNoOverflow(tester, 'marketplace "$section" section at $size');
        });
      }
    });
  }
}
