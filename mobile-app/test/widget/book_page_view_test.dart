import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literature/theme/book_pager.dart';

Widget _app(
  PageController controller,
  List<int> changes, {
  bool reduceMotion = false,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(
      size: const Size(400, 800),
      disableAnimations: reduceMotion,
    ),
    child: Scaffold(
      body: BookPageView(
        controller: controller,
        itemCount: 3,
        onPageChanged: changes.add,
        itemBuilder: (_, i) => Center(child: Text('Page $i')),
      ),
    ),
  ),
);

final _curl = find.byWidgetPredicate(
  (w) => w.runtimeType.toString() == '_PageCurl',
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('mid-swipe turns the current page over the next one', (
    tester,
  ) async {
    _phone(tester);
    final controller = PageController();
    final changes = <int>[];
    await tester.pumpWidget(_app(controller, changes));

    final gesture = await tester.startGesture(const Offset(300, 400));
    await gesture.moveBy(const Offset(-150, 0));
    await tester.pump();

    // Both pages are on screen mid-turn: the next one underneath...
    expect(find.text('Page 0'), findsOneWidget);
    expect(find.text('Page 1'), findsOneWidget);
    // ...and the page on top is curling, not just sliding.
    expect(_curl, findsOneWidget);

    await gesture.moveBy(const Offset(-150, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(changes, [1]);
    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 0').hitTestable(), findsNothing);
  });

  testWidgets('swiping back lays the previous page down again', (tester) async {
    _phone(tester);
    final controller = PageController(initialPage: 1);
    final changes = <int>[];
    await tester.pumpWidget(_app(controller, changes));

    await tester.fling(find.text('Page 1'), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(changes, [0]);
    expect(find.text('Page 0'), findsOneWidget);
  });

  testWidgets('reduced motion falls back to a plain slide', (tester) async {
    _phone(tester);
    final controller = PageController();
    await tester.pumpWidget(_app(controller, [], reduceMotion: true));
    final gesture = await tester.startGesture(const Offset(300, 400));
    await gesture.moveBy(const Offset(-150, 0));
    await tester.pump();
    expect(_curl, findsNothing);
    await gesture.up();
  });
}
