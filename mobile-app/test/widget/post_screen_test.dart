// Functional coverage for PostScreen's "Add page" flow (post_screen.dart):
// the show-title-on-next-page prompt, carrying a title forward vs. hiding
// it, and removing an added page.
import 'package:flutter/material.dart';
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

/// The "Add page" button sits below the fold in the compose form's
/// SingleChildScrollView, so it has to be scrolled into view before it can
/// receive a tap in a fixed-size test viewport.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  final currentUser = mockUsers.first;

  setUp(() async {
    await initTestEnv();
  });

  Future<void> pumpNewPost(WidgetTester tester) async {
    await _pumpApp(
      tester,
      overrides: [currentUserProvider.overrideWith((ref) => currentUser)],
    );
    await _goTo(tester, '/post/new');
  }

  testWidgets(
    'adding a page with no title yet skips the prompt and adds an untitled page',
    (tester) async {
      await pumpNewPost(tester);

      await _tap(tester, find.text('Add page'));

      // No dialog — straight to a new, title-less page.
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Page 2'), findsOneWidget);
      // Only the main title field + the new page's content field — no extra
      // title field, since there was nothing to offer to carry forward.
      expect(find.byType(TextField), findsNWidgets(3));
    },
  );

  testWidgets(
    'adding a page after typing a title prompts to keep showing it, and Yes carries it forward',
    (tester) async {
      await pumpNewPost(tester);

      await tester.enterText(find.byType(TextField).first, 'My Great Title');
      await tester.pump();

      await _tap(tester, find.text('Add page'));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text('Show "My Great Title" as the title on this page too?'),
        findsOneWidget,
      );

      await _tap(tester, find.widgetWithText(FilledButton, 'Yes, keep it'));

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Page 2'), findsOneWidget);
      // main title, main content, page-2 title (pre-filled), page-2 content.
      final titleFields = find.byType(TextField);
      expect(titleFields, findsNWidgets(4));
      final page2Title = tester.widget<TextField>(titleFields.at(2));
      expect(page2Title.controller!.text, 'My Great Title');
    },
  );

  testWidgets(
    'choosing "No title" leaves the new page without a title field',
    (tester) async {
      await pumpNewPost(tester);

      await tester.enterText(find.byType(TextField).first, 'My Great Title');
      await tester.pump();

      await _tap(tester, find.text('Add page'));
      expect(find.byType(AlertDialog), findsOneWidget);

      await _tap(tester, find.widgetWithText(TextButton, 'No title'));

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Page 2'), findsOneWidget);
      // main title, main content, page-2 content — no page-2 title field.
      expect(find.byType(TextField), findsNWidgets(3));
    },
  );

  testWidgets('removing a page removes its fields', (tester) async {
    await pumpNewPost(tester);

    await _tap(tester, find.text('Add page'));
    expect(find.text('Page 2'), findsOneWidget);

    await _tap(tester, find.byTooltip('Remove page'));

    expect(find.text('Page 2'), findsNothing);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
