import 'package:flutter_test/flutter_test.dart';
import 'package:literature/services/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStore.init();
  });

  group('Book bookmarks', () {
    test('starts empty for a book never bookmarked', () {
      expect(LocalStore.instance.loadBookBookmarks('b1'), isEmpty);
    });

    test('save/load round-trips and keeps books separate', () {
      LocalStore.instance.saveBookBookmarks('b1', [2, 5, 9]);
      LocalStore.instance.saveBookBookmarks('b2', [0]);
      expect(LocalStore.instance.loadBookBookmarks('b1'), [2, 5, 9]);
      expect(LocalStore.instance.loadBookBookmarks('b2'), [0]);
    });

    test('saving an empty list clears that book\'s entry', () {
      LocalStore.instance.saveBookBookmarks('b1', [2, 5]);
      LocalStore.instance.saveBookBookmarks('b1', []);
      expect(LocalStore.instance.loadBookBookmarks('b1'), isEmpty);
    });
  });

  group('Book last read position', () {
    test('is null for a book never opened', () {
      expect(LocalStore.instance.loadBookLastPosition('b1'), isNull);
    });

    test('save/load round-trips and keeps books separate', () {
      LocalStore.instance.saveBookLastPosition('b1', 12);
      LocalStore.instance.saveBookLastPosition('b2', 3);
      expect(LocalStore.instance.loadBookLastPosition('b1'), 12);
      expect(LocalStore.instance.loadBookLastPosition('b2'), 3);
    });

    test('later saves overwrite the earlier position for the same book', () {
      LocalStore.instance.saveBookLastPosition('b1', 4);
      LocalStore.instance.saveBookLastPosition('b1', 7);
      expect(LocalStore.instance.loadBookLastPosition('b1'), 7);
    });
  });

  group('Post reading last page', () {
    test('is null for a post never opened', () {
      expect(LocalStore.instance.loadPostLastPageIndex('p1'), isNull);
    });

    test('save/load round-trips and keeps posts separate', () {
      LocalStore.instance.savePostLastPageIndex('p1', 3);
      LocalStore.instance.savePostLastPageIndex('p2', 0);
      expect(LocalStore.instance.loadPostLastPageIndex('p1'), 3);
      expect(LocalStore.instance.loadPostLastPageIndex('p2'), 0);
    });

    test('later saves overwrite the earlier position for the same post', () {
      LocalStore.instance.savePostLastPageIndex('p1', 1);
      LocalStore.instance.savePostLastPageIndex('p1', 4);
      expect(LocalStore.instance.loadPostLastPageIndex('p1'), 4);
    });
  });

  group('clearAll', () {
    test('wipes bookmarks, book last position, and post last page', () async {
      LocalStore.instance.saveBookBookmarks('b1', [1, 2]);
      LocalStore.instance.saveBookLastPosition('b1', 5);
      LocalStore.instance.savePostLastPageIndex('p1', 2);
      await LocalStore.instance.clearAll();
      expect(LocalStore.instance.loadBookBookmarks('b1'), isEmpty);
      expect(LocalStore.instance.loadBookLastPosition('b1'), isNull);
      expect(LocalStore.instance.loadPostLastPageIndex('p1'), isNull);
    });
  });
}
