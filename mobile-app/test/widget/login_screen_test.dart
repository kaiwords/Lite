import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literature/screens/auth/login_screen.dart';
import 'package:literature/widgets/auth_text_field.dart';

import '../helpers/test_env.dart';

void main() {
  setUp(() async {
    // Unauthenticated: this suite exercises the login form itself.
    await initTestEnv(authenticated: false);
  });

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pump();
  }

  Finder emailField() => find.byType(TextField).at(0);
  Finder passwordField() => find.byType(TextField).at(1);

  testWidgets('shows title, both fields and the Log In button',
      (tester) async {
    await pumpLogin(tester);
    expect(find.text('Literature'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Log In'), findsOneWidget);
    expect(find.byType(AuthMessageBanner), findsNothing);
  });

  testWidgets('rejects an invalid email before hitting the network',
      (tester) async {
    await pumpLogin(tester);
    await tester.enterText(emailField(), 'not-an-email');
    await tester.enterText(passwordField(), 'password123');
    await tester.tap(find.text('Log In'));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });

  testWidgets('rejects an empty password', (tester) async {
    await pumpLogin(tester);
    await tester.enterText(emailField(), 'reader@example.com');
    await tester.tap(find.text('Log In'));
    await tester.pump();
    expect(find.text('Enter your password.'), findsOneWidget);
  });

  testWidgets(
      'a failed sign-in surfaces an error banner and re-enables the button',
      (tester) async {
    await pumpLogin(tester);
    await tester.enterText(emailField(), 'reader@example.com');
    await tester.enterText(passwordField(), 'wrong-password');
    // The test HTTP stub fails every request, so signInWithPassword throws
    // and the screen must recover: show a banner, stop the spinner.
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthMessageBanner), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    final button =
        tester.widget<FilledButton>(find.byType(FilledButton).first);
    expect(button.onPressed, isNotNull, reason: 'button must re-enable');
  });

  testWidgets('a fresh valid submit clears the previous validation error',
      (tester) async {
    await pumpLogin(tester);
    await tester.enterText(emailField(), 'bad');
    await tester.tap(find.text('Log In'));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);

    await tester.enterText(emailField(), 'reader@example.com');
    await tester.enterText(passwordField(), 'pw123456');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsNothing);
  });
}
