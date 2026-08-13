import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page types
// ─────────────────────────────────────────────────────────────────────────────

enum BookPageType {
  cover,
  titlePage,
  introduction,
  chapter,
  glossary,
  references,
  backCover,
}

extension BookPageTypeExt on BookPageType {
  /// Returns null (no number), roman numeral string, or arabic string
  /// given the running counters.
  String? pageLabel({int introIndex = 0, int arabicIndex = 0}) {
    switch (this) {
      case BookPageType.cover:
      case BookPageType.titlePage:
      case BookPageType.backCover:
        return null;
      case BookPageType.introduction:
        return _toRoman(introIndex);
      case BookPageType.chapter:
      case BookPageType.glossary:
      case BookPageType.references:
        return arabicIndex.toString();
    }
  }
}

String _toRoman(int n) {
  if (n <= 0) return '';
  const vals = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
  const syms = ['M', 'CM', 'D', 'CD', 'C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I'];
  final buf = StringBuffer();
  var rem = n;
  for (var i = 0; i < vals.length; i++) {
    while (rem >= vals[i]) {
      buf.write(syms[i]);
      rem -= vals[i];
    }
  }
  return buf.toString().toLowerCase(); // i, ii, iii, iv …
}

// ─────────────────────────────────────────────────────────────────────────────
// BookPage
// ─────────────────────────────────────────────────────────────────────────────

class BookPage {
  final BookPageType type;
  final String? chapterTitle; // for chapter pages
  final String content;       // body text (may be empty for cover/back)

  const BookPage({
    required this.type,
    this.chapterTitle,
    this.content = '',
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Book
// ─────────────────────────────────────────────────────────────────────────────

class Book {
  final String id;
  final String title;
  final String authorName;
  final String subtitle;
  final Color coverColor;      // dominant cover background colour
  final Color coverTextColor;
  final String? coverImagePath; // seller-picked cover photo (local file path)
  final List<BookPage> pages;

  const Book({
    required this.id,
    required this.title,
    required this.authorName,
    this.subtitle = '',
    required this.coverColor,
    required this.coverTextColor,
    this.coverImagePath,
    required this.pages,
  });
}

// There is no books backend (no Supabase table) — findBook always returns
// null until one exists. See demo_data/demo_books.dart for the old sample
// content, kept for reference/tests only, not used by the running app.
Book? findBook(String id) => null;
