import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literature/app.dart';

import 'helpers/test_env.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await initTestEnv();

    await tester.pumpWidget(
      const ProviderScope(child: LiteratureApp()),
    );
    // Bounded pumps instead of pumpAndSettle: the home feed starts async
    // work (Supabase fetches, entrance animations) that pumpAndSettle could
    // wait on indefinitely.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Literature'), findsOneWidget);
  });
}
