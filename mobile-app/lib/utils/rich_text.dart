import 'package:flutter/material.dart';

/// Lightweight, pagination-safe rich-text renderer.
///
/// Posts are stored as plain strings carrying a small markdown-style subset
/// that the composer's formatting toolbar inserts:
///
///   `**bold**`  `*italic*`  `__underline__`  `~~strikethrough~~`   (inline)
///   `"> "` quote line        `"- "` bullet line                    (line prefix)
///
/// The inline parser is deliberately tolerant: an unmatched marker simply
/// toggles a style for the remainder of the slice instead of throwing or
/// leaving a raw marker on screen. That keeps it safe when the full-screen
/// viewer's [paginateTextToFit] splits content mid-text across pages.
List<InlineSpan> buildFormattedSpans(
  String text,
  TextStyle base, {
  Color? accent,
}) {
  final spans = <InlineSpan>[];
  final lines = text.split('\n');
  final mutedColor =
      (base.color ?? const Color(0xFF000000)).withValues(alpha: 0.7);

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    if (line.startsWith('> ')) {
      // Quote line — leading accent bar + italic, muted body.
      spans.add(TextSpan(
        text: '▎  ', // ▎ left vertical bar
        style: base.copyWith(
          color: accent ?? mutedColor,
          fontWeight: FontWeight.w700,
        ),
      ));
      spans.addAll(_inlineSpans(
        line.substring(2),
        base.copyWith(fontStyle: FontStyle.italic, color: mutedColor),
      ));
    } else if (line.startsWith('- ')) {
      // Bullet line.
      spans.add(TextSpan(text: '•  ', style: base)); // •
      spans.addAll(_inlineSpans(line.substring(2), base));
    } else {
      spans.addAll(_inlineSpans(line, base));
    }

    if (i != lines.length - 1) spans.add(const TextSpan(text: '\n'));
  }
  return spans;
}

/// Parses inline markers within a single run of text into styled spans.
List<InlineSpan> _inlineSpans(String text, TextStyle base) {
  final spans = <InlineSpan>[];
  final buf = StringBuffer();
  var bold = false, italic = false, underline = false, strike = false;

  TextStyle styleNow() {
    final decorations = <TextDecoration>[];
    if (underline) decorations.add(TextDecoration.underline);
    if (strike) decorations.add(TextDecoration.lineThrough);
    return base.copyWith(
      fontWeight: bold ? FontWeight.w700 : null,
      fontStyle: italic ? FontStyle.italic : null,
      decoration:
          decorations.isEmpty ? null : TextDecoration.combine(decorations),
    );
  }

  void flush() {
    if (buf.isNotEmpty) {
      spans.add(TextSpan(text: buf.toString(), style: styleNow()));
      buf.clear();
    }
  }

  var i = 0;
  while (i < text.length) {
    final two = (i + 2 <= text.length) ? text.substring(i, i + 2) : '';
    if (two == '**') {
      flush();
      bold = !bold;
      i += 2;
    } else if (two == '~~') {
      flush();
      strike = !strike;
      i += 2;
    } else if (two == '__') {
      flush();
      underline = !underline;
      i += 2;
    } else if (text[i] == '*') {
      flush();
      italic = !italic;
      i += 1;
    } else {
      buf.write(text[i]);
      i += 1;
    }
  }
  flush();

  // Guarantee at least one span so empty lines still occupy their height.
  if (spans.isEmpty) spans.add(TextSpan(text: '', style: base));
  return spans;
}
