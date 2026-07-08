import 'package:flutter/widgets.dart';
import '../models/post.dart';

/// Splits a post's content into pages for horizontal swiping.
/// - Poems/Haiku: one stanza per page (split by blank line)
/// - Jokes: single page
/// - Novels/Stories/Articles/Essays: paragraphs batched to ~550 chars each
List<String> paginatePost(Post post) {
  final raw = post.content.trim();

  switch (post.category) {
    case ContentCategory.joke:
      return [raw];

    case ContentCategory.haiku:
    case ContentCategory.poem:
      final stanzas = raw
          .split(RegExp(r'\n[ \t]*\n'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      return stanzas.isEmpty ? [raw] : stanzas;

    default:
      final paragraphs = raw
          .split(RegExp(r'\n[ \t]*\n'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (paragraphs.length <= 1) return [raw];

      const maxChars = 550;
      final pages = <String>[];
      var current = '';

      for (final p in paragraphs) {
        if (current.isEmpty) {
          current = p;
        } else if (current.length + p.length + 2 > maxChars) {
          pages.add(current);
          current = p;
        } else {
          current = '$current\n\n$p';
        }
      }
      if (current.isNotEmpty) pages.add(current);
      return pages;
  }
}

/// Splits [text] into pages that each fill the [size] box when rendered in
/// [style], breaking on word boundaries. Anything that doesn't fit flows onto
/// the next page. Used to show a post's content page-by-page with swipe.
List<String> paginateTextToFit(String text, TextStyle style, Size size) {
  final t = text.trim();
  if (t.isEmpty) return [''];
  if (size.width <= 0 || size.height <= 0) return [t];

  final pages = <String>[];
  var start = 0;
  while (start < t.length) {
    final remaining = t.substring(start);
    final tp = TextPainter(
      text: TextSpan(text: remaining, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    if (tp.height <= size.height) {
      pages.add(remaining);
      break;
    }

    // How many whole lines fit in the page height?
    final metrics = tp.computeLineMetrics();
    var used = 0.0;
    var lastFit = -1;
    for (var i = 0; i < metrics.length; i++) {
      if (used + metrics[i].height <= size.height) {
        used += metrics[i].height;
        lastFit = i;
      } else {
        break;
      }
    }
    if (lastFit < 0) lastFit = 0;
    var top = 0.0;
    for (var i = 0; i < lastFit; i++) {
      top += metrics[i].height;
    }
    final yMid = top + metrics[lastFit].height / 2;
    final pos = tp.getPositionForOffset(Offset(size.width, yMid));
    var end = start + pos.offset;
    if (end <= start) end = start + 1; // always make progress
    if (end >= t.length) {
      pages.add(t.substring(start));
      break;
    }
    // Prefer a word boundary
    final slice = t.substring(start, end);
    final lastWs = slice.lastIndexOf(RegExp(r'\s'));
    if (lastWs > 0) end = start + lastWs + 1;
    pages.add(t.substring(start, end));
    start = end;
  }
  return pages.isEmpty ? [t] : pages;
}
