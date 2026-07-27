// Functional coverage for FollowListScreen (`/profile/followers` and
// `/profile/following`): the placeholder followers/following lists it
// derives from `mockUsers`, its client-side search filter, the follow/
// unfollow toggle pill, and row-tap navigation to `/user/:id`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:literature/app.dart';
import 'package:literature/models/user.dart';
import 'package:literature/providers/auth_provider.dart';
import 'package:literature/providers/follow_provider.dart';
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

void main() {
  // Screen logic (follow_list_screen.dart): followers = every mock user
  // except the signed-in one; following = the first two of those (a
  // pre-existing placeholder — there's no reverse-follow tracking yet).
  final currentUser = mockUsers.first; // u1, Eleanor Voss
  final followers = mockUsers.where((u) => u.id != currentUser.id).toList();
  final following = followers.take(2).toList();

  setUp(() async {
    await initTestEnv();
  });

  Future<void> pumpFollowers(WidgetTester tester) async {
    await _pumpApp(
      tester,
      overrides: [currentUserProvider.overrideWith((ref) => currentUser)],
    );
    await _goTo(tester, '/profile/followers');
  }

  Future<void> pumpFollowing(WidgetTester tester) async {
    await _pumpApp(
      tester,
      overrides: [currentUserProvider.overrideWith((ref) => currentUser)],
    );
    await _goTo(tester, '/profile/following');
  }

  testWidgets(
    'followers screen lists every non-current mock user with a matching count',
    (tester) async {
      await pumpFollowers(tester);

      expect(find.text('Followers (${followers.length})'), findsOneWidget);
      for (final u in followers) {
        expect(find.text(u.displayName), findsOneWidget);
      }
      // The signed-in user never appears in their own followers list.
      expect(find.text(currentUser.displayName), findsNothing);
    },
  );

  testWidgets(
    'following screen reflects the "first two" placeholder logic',
    (tester) async {
      await pumpFollowing(tester);

      expect(find.text('Following (${following.length})'), findsOneWidget);
      for (final u in following) {
        expect(find.text(u.displayName), findsOneWidget);
      }
      // Everyone past the first two must be omitted.
      for (final u in followers.skip(2)) {
        expect(find.text(u.displayName), findsNothing);
      }
    },
  );

  testWidgets('search matches by display name, case-insensitively', (
    tester,
  ) async {
    await pumpFollowers(tester);
    final target = followers[1]; // Priya Nair

    await tester.enterText(
      find.byType(TextField),
      target.displayName.toLowerCase(),
    );
    await tester.pump();

    expect(find.text(target.displayName), findsOneWidget);
    for (final u in followers) {
      if (u.id == target.id) continue;
      expect(find.text(u.displayName), findsNothing);
    }
  });

  testWidgets('search matches by username, case-insensitively', (
    tester,
  ) async {
    await pumpFollowers(tester);
    final target = followers[0]; // Marcus Osei / marcus_ink
    final needle = target.username
        .substring(target.username.length - 3) // "ink"
        .toUpperCase();

    await tester.enterText(find.byType(TextField), needle);
    await tester.pump();

    expect(find.text(target.displayName), findsOneWidget);
    for (final u in followers) {
      if (u.id == target.id) continue;
      expect(find.text(u.displayName), findsNothing);
    }
  });

  testWidgets(
    'a query matching nothing shows the empty state but keeps the unfiltered count',
    (tester) async {
      await pumpFollowers(tester);

      await tester.enterText(find.byType(TextField), 'zzz-no-match-zzz');
      await tester.pump();

      expect(find.text('No matches'), findsOneWidget);
      // AppBar count is derived from the unfiltered list, so it must not
      // drop to 0 just because the filtered list is empty.
      expect(find.text('Followers (${followers.length})'), findsOneWidget);
      for (final u in followers) {
        expect(find.text(u.displayName), findsNothing);
      }
    },
  );

  testWidgets('clearing the search field restores the full list', (
    tester,
  ) async {
    await pumpFollowers(tester);

    await tester.enterText(find.byType(TextField), 'zzz-no-match-zzz');
    await tester.pump();
    expect(find.text('No matches'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(find.text('No matches'), findsNothing);
    for (final u in followers) {
      expect(find.text(u.displayName), findsOneWidget);
    }
  });

  testWidgets(
    "tapping the follow pill toggles followNotifierProvider and flips the pill's label without navigating",
    (tester) async {
      await pumpFollowers(tester);
      final target = followers.first; // first row === first "Follow" pill

      final container = ProviderScope.containerOf(
        tester.element(find.text('Followers (${followers.length})')),
      );
      expect(
        container.read(followNotifierProvider).contains(target.id),
        isFalse,
      );
      expect(find.text('Follow'), findsWidgets);

      await tester.tap(find.text('Follow').first);
      await tester.pump();

      expect(
        container.read(followNotifierProvider).contains(target.id),
        isTrue,
        reason: 'tapping the pill should follow the user',
      );
      expect(find.text('Following'), findsOneWidget);
      expect(
        find.byType(UserProfileScreen),
        findsNothing,
        reason: 'toggling follow must not navigate away',
      );

      // Toggle back off.
      await tester.tap(find.text('Following').first);
      await tester.pump();

      expect(
        container.read(followNotifierProvider).contains(target.id),
        isFalse,
      );
      expect(find.text('Follow'), findsWidgets);
      expect(find.byType(UserProfileScreen), findsNothing);
    },
  );

  testWidgets(
    "tapping a row (not the pill) navigates to that user's profile",
    (tester) async {
      await pumpFollowers(tester);
      final target = followers[2]; // Javier Morales

      await tester.tap(find.text(target.displayName));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(UserProfileScreen), findsOneWidget);
      final screen = tester.widget<UserProfileScreen>(
        find.byType(UserProfileScreen),
      );
      expect(screen.userId, target.id);
    },
  );
}
