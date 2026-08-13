// Functional coverage for FollowListScreen (`/profile/followers` and
// `/profile/following`): there is no reverse-follower tracking in the
// backend, so Followers is always empty; Following resolves the real
// followed ids against the `users` table (which, in this offline test
// environment, never returns real rows either) — both degrade to their
// honest empty states rather than fabricated placeholder users.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:literature/app.dart';
import 'package:literature/models/user.dart';
import 'package:literature/providers/auth_provider.dart';
import 'package:literature/providers/follow_provider.dart';
import 'package:literature/router/app_router.dart';

import '../helpers/test_env.dart';

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

Future<void> _goTo(WidgetTester tester, String location) async {
  appRouter.go(location);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  final currentUser = mockUsers.first; // u1, Eleanor Voss

  setUp(() async {
    await initTestEnv();
  });

  testWidgets(
    'followers screen always shows the empty state (no reverse-follow backend)',
    (tester) async {
      await _pumpApp(
        tester,
        overrides: [currentUserProvider.overrideWith((ref) => currentUser)],
      );
      await _goTo(tester, '/profile/followers');

      expect(find.text('Followers (0)'), findsOneWidget);
      expect(find.text('No followers yet'), findsOneWidget);
    },
  );

  testWidgets(
    'following screen shows the empty state when the user follows no one',
    (tester) async {
      await _pumpApp(
        tester,
        overrides: [currentUserProvider.overrideWith((ref) => currentUser)],
      );
      await _goTo(tester, '/profile/following');

      expect(find.text('Following (0)'), findsOneWidget);
      expect(find.text('Not following anyone yet'), findsOneWidget);
    },
  );

  testWidgets(
    'following a real-looking id resolves through the users table without crashing '
    '(and shows empty here since the test backend has no matching row)',
    (tester) async {
      await _pumpApp(
        tester,
        overrides: [currentUserProvider.overrideWith((ref) => currentUser)],
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      await container.read(followNotifierProvider.notifier).follow('some-user-id');

      await _goTo(tester, '/profile/following');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Not following anyone yet'), findsOneWidget);
    },
  );
}
