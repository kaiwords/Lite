import 'package:flutter_test/flutter_test.dart';
import 'package:literature/models/book.dart';
import 'package:literature/utils/auth_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('humanizeAuthError', () {
    String h(String raw) => humanizeAuthError(AuthException(raw));

    test('rewrites the known awkward Supabase messages', () {
      expect(h('User already registered'),
          'An account with this email already exists. Try logging in instead.');
      expect(h('Invalid login credentials'), 'Incorrect email or password.');
      expect(
          h('Email not confirmed'),
          'Please confirm your email first — check your inbox for the '
          'confirmation link.');
      expect(h('Password should be at least 6 characters'),
          'Password must be at least 6 characters.');
      expect(h('Unable to validate email address: invalid format'),
          'Enter a valid email address.');
      expect(h('Request rate limit reached'),
          'Too many attempts — please wait a moment and try again.');
    });

    test('matching is case-insensitive', () {
      expect(h('INVALID LOGIN CREDENTIALS'), 'Incorrect email or password.');
    });

    test('falls back to the raw message for anything else', () {
      expect(h('Some unusual backend error'), 'Some unusual backend error');
    });
  });

  group('BookPageType.pageLabel', () {
    test('cover, title page and back cover have no label', () {
      expect(BookPageType.cover.pageLabel(), isNull);
      expect(BookPageType.titlePage.pageLabel(), isNull);
      expect(BookPageType.backCover.pageLabel(), isNull);
    });

    test('introduction pages use lowercase roman numerals', () {
      expect(BookPageType.introduction.pageLabel(introIndex: 1), 'i');
      expect(BookPageType.introduction.pageLabel(introIndex: 4), 'iv');
      expect(BookPageType.introduction.pageLabel(introIndex: 9), 'ix');
      expect(BookPageType.introduction.pageLabel(introIndex: 14), 'xiv');
      expect(BookPageType.introduction.pageLabel(introIndex: 40), 'xl');
    });

    test('non-positive intro index yields an empty label, not a crash', () {
      expect(BookPageType.introduction.pageLabel(introIndex: 0), '');
      expect(BookPageType.introduction.pageLabel(), '');
    });

    test('chapter/glossary/references pages use arabic numbers', () {
      expect(BookPageType.chapter.pageLabel(arabicIndex: 12), '12');
      expect(BookPageType.glossary.pageLabel(arabicIndex: 3), '3');
      expect(BookPageType.references.pageLabel(arabicIndex: 7), '7');
    });
  });
}
