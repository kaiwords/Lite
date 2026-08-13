// Functional coverage for EarningsScreen (`/profile/earnings`): there is no
// tipping/payments backend at all, so the screen always reflects the honest
// zero state rather than fabricated tips — this just confirms that.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:literature/app.dart';
import 'package:literature/models/user.dart';
import 'package:literature/providers/auth_provider.dart';
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

  testWidgets('shows a zero total and "No tips yet" with no fabricated data', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      overrides: [currentUserProvider.overrideWith((ref) => currentUser)],
    );
    await _goTo(tester, '/profile/earnings');

    expect(find.text('\$0.00'), findsOneWidget);
    expect(find.text('No tips yet'), findsOneWidget);
    expect(find.text('Top supporters'), findsNothing);
    expect(find.text('0 tips · 0 supporters'), findsOneWidget);
  });
}
