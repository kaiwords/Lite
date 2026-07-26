import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literature/models/post.dart';
import 'package:literature/models/user.dart';
import 'package:literature/utils/post_paginator.dart';

Post _post(String content, ContentCategory category) => Post(
      id: 'test',
      author: mockUsers[0],
      title: 'Test',
      content: content,
      category: category,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('paginatePost', () {
    test('joke is always a single page', () {
      final pages = _post('Setup.\n\nPunchline.', ContentCategory.joke);
      expect(paginatePost(pages), ['Setup.\n\nPunchline.']);
    });

    test('poem splits one stanza per page', () {
      final pages = paginatePost(
        _post('line one\nline two\n\nstanza two\n\nstanza three',
            ContentCategory.poem),
      );
      expect(pages, ['line one\nline two', 'stanza two', 'stanza three']);
    });

    test('haiku with no blank lines stays a single page', () {
      final pages = paginatePost(
        _post('first line\nsecond line\nthird line', ContentCategory.haiku),
      );
      expect(pages, ['first line\nsecond line\nthird line']);
    });

    test('blank-line splitting tolerates trailing spaces/tabs on the divider',
        () {
      final pages = paginatePost(
        _post('stanza one\n \t \nstanza two', ContentCategory.poem),
      );
      expect(pages, ['stanza one', 'stanza two']);
    });

    test('empty poem content returns one (empty) page, never an empty list',
        () {
      final pages = paginatePost(_post('   ', ContentCategory.poem));
      expect(pages, ['']);
    });

    test('prose with a single paragraph stays a single page', () {
      final pages =
          paginatePost(_post('Just one paragraph.', ContentCategory.essay));
      expect(pages, ['Just one paragraph.']);
    });

    test('prose paragraphs are batched up to ~550 chars per page', () {
      final para = 'x' * 300; // two fit (300+300+2 > 550 → they do not)
      final pages = paginatePost(
        _post('$para\n\n$para\n\n$para', ContentCategory.novel),
      );
      // 300 + 2 + 300 > 550, so each paragraph lands on its own page.
      expect(pages.length, 3);
      expect(pages.every((p) => p == para), isTrue);
    });

    test('short prose paragraphs share a page', () {
      final pages = paginatePost(
        _post('First.\n\nSecond.\n\nThird.', ContentCategory.story),
      );
      expect(pages, ['First.\n\nSecond.\n\nThird.']);
    });

    test('an oversized single paragraph is not split mid-paragraph', () {
      final huge = 'y' * 2000;
      final pages =
          paginatePost(_post('$huge\n\nshort', ContentCategory.article));
      expect(pages, [huge, 'short']);
    });
  });

  group('paginateTextToFit', () {
    const style = TextStyle(fontSize: 10);

    test('empty text returns a single empty page', () {
      expect(paginateTextToFit('   ', style, const Size(100, 100)), ['']);
    });

    test('zero-sized box returns the whole text as one page', () {
      expect(
        paginateTextToFit('hello world', style, const Size(0, 100)),
        ['hello world'],
      );
      expect(
        paginateTextToFit('hello world', style, const Size(100, 0)),
        ['hello world'],
      );
    });

    test('short text fits on one page', () {
      expect(
        paginateTextToFit('hello', style, const Size(200, 200)),
        ['hello'],
      );
    });

    test('long text splits into multiple pages without losing characters', () {
      final words = List.generate(60, (i) => 'word$i').join(' ');
      final pages = paginateTextToFit(words, style, const Size(100, 30));
      expect(pages.length, greaterThan(1));
      // Nothing lost or duplicated: pages concatenate back to the input.
      expect(pages.join(), words);
    });

    test('pages prefer word boundaries', () {
      final words = List.generate(60, (i) => 'word$i').join(' ');
      final pages = paginateTextToFit(words, style, const Size(100, 30));
      // Every page but the last should end at a word boundary (trailing space).
      for (final page in pages.sublist(0, pages.length - 1)) {
        expect(page.endsWith(' '), isTrue,
            reason: 'page "$page" should end on a word boundary');
      }
    });

    test('always makes progress even in a box smaller than one line', () {
      // Height of 5 fits no full 10px line; the `end <= start` guard must
      // still advance to avoid an infinite loop.
      final pages = paginateTextToFit('abcdef', style, const Size(100, 5));
      expect(pages.join(), 'abcdef');
    });
  });
}
