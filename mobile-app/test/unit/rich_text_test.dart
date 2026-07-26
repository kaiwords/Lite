import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literature/utils/rich_text.dart';

const _base = TextStyle(fontSize: 14, color: Color(0xFF222222));

List<TextSpan> _textSpans(List<InlineSpan> spans) =>
    spans.whereType<TextSpan>().toList();

/// Concatenated plain text of all spans — what the reader actually sees.
String _visibleText(List<InlineSpan> spans) =>
    _textSpans(spans).map((s) => s.text ?? '').join();

void main() {
  test('plain text renders as-is', () {
    final spans = buildFormattedSpans('hello world', _base);
    expect(_visibleText(spans), 'hello world');
  });

  test('**bold** styles the marked run and strips the markers', () {
    final spans = _textSpans(buildFormattedSpans('a **b** c', _base));
    expect(_visibleText(spans), 'a b c');
    final bold = spans.firstWhere((s) => s.text == 'b');
    expect(bold.style?.fontWeight, FontWeight.w700);
    final plain = spans.firstWhere((s) => s.text == 'a ');
    expect(plain.style?.fontWeight, isNull);
  });

  test('*italic* styles the marked run', () {
    final spans = _textSpans(buildFormattedSpans('x *y* z', _base));
    expect(_visibleText(spans), 'x y z');
    expect(spans.firstWhere((s) => s.text == 'y').style?.fontStyle,
        FontStyle.italic);
  });

  test('__underline__ and ~~strike~~ set text decorations', () {
    final spans = _textSpans(buildFormattedSpans('__u__ and ~~s~~', _base));
    expect(_visibleText(spans), 'u and s');
    final u = spans.firstWhere((s) => s.text == 'u');
    final s = spans.firstWhere((s) => s.text == 's');
    expect(u.style?.decoration?.contains(TextDecoration.underline), isTrue);
    expect(s.style?.decoration?.contains(TextDecoration.lineThrough), isTrue);
  });

  test('nested markers combine styles', () {
    final spans = _textSpans(buildFormattedSpans('**bold *both***', _base));
    final both = spans.firstWhere((s) => s.text == 'both');
    expect(both.style?.fontWeight, FontWeight.w700);
    expect(both.style?.fontStyle, FontStyle.italic);
  });

  test('unmatched marker styles the remainder instead of leaking the marker',
      () {
    final spans = _textSpans(buildFormattedSpans('a **rest', _base));
    // The literal ** must never reach the screen.
    expect(_visibleText(spans).contains('*'), isFalse);
    expect(_visibleText(spans), 'a rest');
    expect(spans.firstWhere((s) => s.text == 'rest').style?.fontWeight,
        FontWeight.w700);
  });

  test('quote line gets the accent bar prefix and italic muted body', () {
    final spans = _textSpans(buildFormattedSpans('> wise words', _base));
    expect(spans.first.text, '▎  ');
    final body = spans.firstWhere((s) => s.text == 'wise words');
    expect(body.style?.fontStyle, FontStyle.italic);
  });

  test('bullet line gets the bullet prefix', () {
    final spans = _textSpans(buildFormattedSpans('- item', _base));
    expect(spans.first.text, '•  ');
    expect(_visibleText(spans), '•  item');
  });

  test('line breaks are preserved and empty lines still emit a span', () {
    final spans = _textSpans(buildFormattedSpans('a\n\nb', _base));
    expect(_visibleText(spans), 'a\n\nb');
  });
}
