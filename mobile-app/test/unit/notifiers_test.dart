import 'package:flutter_test/flutter_test.dart';
import 'package:literature/models/comment.dart';
import 'package:literature/models/marketplace.dart';
import 'package:literature/models/post.dart';
import 'package:literature/providers/comments_provider.dart';
import 'package:literature/providers/feed_provider.dart';
import 'package:literature/providers/marketplace_account_provider.dart';

import '../helpers/test_env.dart';

void main() {
  // Notifier methods like addPost/add/update fire Supabase writes internally
  // (currently swallowed with catchError — review finding H6), so the
  // Supabase singleton must exist even for these state-only assertions.
  setUpAll(() async {
    await initTestEnv();
  });

  group('PostsNotifier', () {
    test('toggleLike flips the flag and adjusts the count both ways', () {
      final notifier = PostsNotifier(List.of(mockPosts));
      final id = mockPosts.first.id;
      final before = mockPosts.first;

      notifier.toggleLike(id);
      var p = notifier.state.firstWhere((p) => p.id == id);
      expect(p.isLiked, !before.isLiked);
      expect(p.likesCount,
          before.isLiked ? before.likesCount - 1 : before.likesCount + 1);

      notifier.toggleLike(id);
      p = notifier.state.firstWhere((p) => p.id == id);
      expect(p.isLiked, before.isLiked);
      expect(p.likesCount, before.likesCount);
    });

    test('toggleLike leaves other posts untouched', () {
      final notifier = PostsNotifier(List.of(mockPosts));
      notifier.toggleLike(mockPosts.first.id);
      final other = notifier.state[1];
      expect(other.isLiked, mockPosts[1].isLiked);
      expect(other.likesCount, mockPosts[1].likesCount);
    });

    test('toggleFavourite flips only the favourite flag', () {
      final notifier = PostsNotifier(List.of(mockPosts));
      final id = mockPosts.first.id;
      notifier.toggleFavourite(id);
      final p = notifier.state.firstWhere((p) => p.id == id);
      expect(p.isFavourited, !mockPosts.first.isFavourited);
      expect(p.likesCount, mockPosts.first.likesCount);
    });

    test('addPost prepends the new post', () {
      final notifier = PostsNotifier(List.of(mockPosts));
      final post = Post(
        id: 'new-post',
        author: mockPosts.first.author,
        title: 'New',
        content: 'Body',
        category: ContentCategory.essay,
        createdAt: DateTime(2026, 7, 18),
      );
      notifier.addPost(post);
      expect(notifier.state.first.id, 'new-post');
      expect(notifier.state.length, mockPosts.length + 1);
    });

    test('addComment / addShare bump the right counters', () {
      final notifier = PostsNotifier(List.of(mockPosts));
      final id = mockPosts.first.id;
      notifier.addComment(id);
      notifier.addShare(id);
      notifier.addShare(id);
      final p = notifier.state.firstWhere((p) => p.id == id);
      expect(p.commentsCount, mockPosts.first.commentsCount + 1);
      expect(p.sharesCount, mockPosts.first.sharesCount + 2);
    });

    test('loadFromSupabase failure keeps existing state (offline fallback)',
        () async {
      final notifier = PostsNotifier(List.of(mockPosts));
      await notifier.loadFromSupabase(); // fake URL — request fails
      expect(notifier.state.length, mockPosts.length);
      expect(notifier.state.first.id, mockPosts.first.id);
    });
  });

  group('CartNotifier', () {
    test('add de-duplicates by listing id', () {
      final cart = CartNotifier([]);
      cart.add(mockListings.first);
      cart.add(mockListings.first);
      expect(cart.state.length, 1);
    });

    test('remove/clear/contains behave', () {
      final cart = CartNotifier([]);
      cart.add(mockListings[0]);
      cart.add(mockListings[1]);
      expect(cart.contains(mockListings[0].id), isTrue);
      cart.remove(mockListings[0].id);
      expect(cart.contains(mockListings[0].id), isFalse);
      expect(cart.state.length, 1);
      cart.clear();
      expect(cart.state, isEmpty);
    });
  });

  group('PurchasesNotifier', () {
    test('buyNow adds a purchase with an ORD- order id', () {
      final purchases = PurchasesNotifier([]);
      purchases.buyNow(mockListings.first);
      expect(purchases.state.length, 1);
      expect(purchases.state.first.listing.id, mockListings.first.id);
      expect(purchases.state.first.orderId, startsWith('ORD-'));
      expect(purchases.contains(mockListings.first.id), isTrue);
    });

    test('remove drops the purchase by listing id', () {
      final purchases = PurchasesNotifier([]);
      purchases.buyNow(mockListings.first);
      purchases.remove(mockListings.first.id);
      expect(purchases.state, isEmpty);
    });
  });

  group('MyListingsNotifier', () {
    test('update replaces the listing with a matching id in place', () {
      final mine = MyListingsNotifier(List.of(MyListingsNotifier.seed()));
      final original = mine.state[1];
      final edited = MarketplaceListing(
        id: original.id,
        title: 'Edited Title',
        authorName: original.authorName,
        price: '\$1.23',
        type: original.type,
        rating: original.rating,
        reviewCount: original.reviewCount,
      );
      mine.update(edited);
      expect(mine.state[1].title, 'Edited Title');
      expect(mine.state[1].price, '\$1.23');
      expect(mine.state.length, MyListingsNotifier.seed().length);
    });

    test('remove drops by id', () {
      final mine = MyListingsNotifier(List.of(MyListingsNotifier.seed()));
      final id = mine.state.first.id;
      mine.remove(id);
      expect(mine.state.any((l) => l.id == id), isFalse);
    });
  });

  group('CommentsNotifier', () {
    test('add prepends the comment', () {
      final notifier = CommentsNotifier(List.of(mockComments));
      final comment = Comment(
        id: 'c-new',
        postId: 'p1',
        author: mockComments.first.author,
        text: 'hi',
        createdAt: DateTime(2026, 7, 18),
      );
      notifier.add(comment);
      expect(notifier.state.first.id, 'c-new');
    });

    test('toggleLike flips flag and count for that comment only', () {
      final notifier = CommentsNotifier(List.of(mockComments));
      final target = mockComments[1]; // isLiked: false
      notifier.toggleLike(target.id);
      final c = notifier.state.firstWhere((c) => c.id == target.id);
      expect(c.isLiked, isTrue);
      expect(c.likesCount, target.likesCount + 1);
      final untouched =
          notifier.state.firstWhere((c) => c.id == mockComments.first.id);
      expect(untouched.likesCount, mockComments.first.likesCount);
    });
  });

  group('VisibleCategoriesNotifier', () {
    test('defaults contain every category except "all"', () {
      final defaults = VisibleCategoriesNotifier.defaults();
      expect(defaults.contains(FeedCategory.all), isFalse);
      expect(defaults.length, FeedCategory.values.length - 1);
    });

    test('toggle removes then restores a category', () {
      final notifier =
          VisibleCategoriesNotifier(VisibleCategoriesNotifier.defaults());
      notifier.toggle(FeedCategory.haiku);
      expect(notifier.state.contains(FeedCategory.haiku), isFalse);
      notifier.toggle(FeedCategory.haiku);
      expect(notifier.state.contains(FeedCategory.haiku), isTrue);
    });
  });
}
