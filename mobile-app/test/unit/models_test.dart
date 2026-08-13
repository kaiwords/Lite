import 'package:flutter_test/flutter_test.dart';
import 'package:literature/demo_data/demo_comments.dart';
import 'package:literature/demo_data/demo_marketplace.dart';
import 'package:literature/demo_data/demo_posts.dart';
import 'package:literature/models/comment.dart';
import 'package:literature/models/marketplace.dart';
import 'package:literature/models/post.dart';
import 'package:literature/models/user.dart';
import 'package:literature/providers/marketplace_account_provider.dart';

void main() {
  group('LitUser', () {
    test('toJson/fromJson round-trips every field', () {
      const user = LitUser(
        id: 'u9',
        username: 'tester',
        displayName: 'Test User',
        avatarUrl: 'https://example.com/a.png',
        coverImageUrl: '/local/path/cover.jpg',
        bio: 'bio',
        followersCount: 3,
        followingCount: 4,
        postsCount: 5,
        earnings: 1.5,
        isFollowing: true,
        isVerified: true,
      );
      final back = LitUser.fromJson(user.toJson());
      expect(back.toJson(), user.toJson());
    });

    test('copyWith updates avatarUrl/coverImageUrl independently', () {
      const user = LitUser(id: 'u9', username: 'tester', displayName: 'Test User');
      final withAvatar = user.copyWith(avatarUrl: '/a.png');
      expect(withAvatar.avatarUrl, '/a.png');
      expect(withAvatar.coverImageUrl, isNull);
      final withCover = withAvatar.copyWith(coverImageUrl: '/c.png');
      expect(withCover.avatarUrl, '/a.png');
      expect(withCover.coverImageUrl, '/c.png');
    });

    test('fromSupabaseRow maps snake_case columns', () {
      final u = LitUser.fromSupabaseRow({
        'id': 'abc',
        'username': 'writer',
        'display_name': 'A Writer',
        'avatar_url': null,
        'bio': 'hi',
        'followers_count': 7,
        'following_count': 2,
        'posts_count': 1,
        'earnings': 9.25,
        'is_verified': true,
      });
      expect(u.id, 'abc');
      expect(u.username, 'writer');
      expect(u.displayName, 'A Writer');
      expect(u.followersCount, 7);
      expect(u.earnings, 9.25);
      expect(u.isVerified, isTrue);
    });

    test(
        'fromSupabaseRow defaults null display_name/username to empty string '
        '(UI must guard [0] access — see review finding H1)', () {
      final u = LitUser.fromSupabaseRow({'id': 'abc'});
      expect(u.displayName, '');
      expect(u.username, '');
      expect(u.bio, '');
      expect(u.followersCount, 0);
      expect(u.earnings, 0.0);
    });
  });

  group('Post', () {
    test('toJson/fromJson round-trips', () {
      final post = Post(
        id: 'p9',
        author: mockUsers[1],
        title: 'T',
        content: 'C',
        category: ContentCategory.haiku,
        createdAt: DateTime(2026, 3, 4, 5, 6),
        likesCount: 1,
        commentsCount: 2,
        sharesCount: 3,
        isLiked: true,
        isFavourited: true,
        audioUrl: 'https://example.com/a.mp3',
        coverImageUrl: null,
        linkedListingId: 'm1',
        bookId: 'b1',
      );
      final back = Post.fromJson(post.toJson());
      expect(back.toJson(), post.toJson());
    });

    test('copyWith only changes the requested counters/flags', () {
      final post = mockPosts.first;
      final changed = post.copyWith(isLiked: true, likesCount: 999);
      expect(changed.isLiked, isTrue);
      expect(changed.likesCount, 999);
      expect(changed.id, post.id);
      expect(changed.title, post.title);
      expect(changed.audioUrl, post.audioUrl);
    });

    test('contentCategoryFromName falls back to poem for unknown/null', () {
      expect(contentCategoryFromName('novel'), ContentCategory.novel);
      expect(contentCategoryFromName('not-a-category'), ContentCategory.poem);
      expect(contentCategoryFromName(null), ContentCategory.poem);
    });

    test('toJson/fromJson round-trips extra pages, including a hidden title', () {
      final post = Post(
        id: 'p10',
        author: mockUsers[0],
        title: 'Main title',
        content: 'Main content',
        category: ContentCategory.novel,
        createdAt: DateTime(2026, 8, 3),
        pages: const [
          PostPage(title: 'Main title', content: 'Page two content'),
          PostPage(content: 'Page three content'), // title hidden
        ],
      );
      final back = Post.fromJson(post.toJson());
      expect(back.toJson(), post.toJson());
      expect(back.pages.length, 2);
      expect(back.pages[0].title, 'Main title');
      expect(back.pages[1].title, isNull);
    });
  });

  group('MarketplaceListing', () {
    test('toJson/fromJson round-trips chapters and audio volumes', () {
      const listing = MarketplaceListing(
        id: 'x1',
        title: 'Book',
        authorName: 'Author',
        price: '\$9.99',
        type: ListingType.ebook,
        rating: 4.2,
        reviewCount: 11,
        linkedPostId: 'p1',
        contentCategory: ContentCategory.novel,
        genre: Genre.fantasy,
        description: 'desc',
        ebookChapters: [
          EbookChapter(title: 'Ch 1', content: 'Once…'),
          EbookChapter(title: 'Ch 2', content: 'Then…'),
        ],
        audioVolumes: [AudioVolume(title: 'Vol 1', fileName: 'v1.mp3')],
      );
      final back = MarketplaceListing.fromJson(listing.toJson());
      expect(back.toJson(), listing.toJson());
    });

    test('toJson/fromJson round-trips book-metadata and physical fields', () {
      final listing = MarketplaceListing(
        id: 'x2',
        title: 'Physical Book',
        authorName: 'Author',
        price: '\$14.99',
        type: ListingType.physical,
        rating: 4.8,
        reviewCount: 3,
        isbn: '978-3-16-148410-0',
        publisher: 'Penguin Books',
        publicationDate: DateTime.utc(2019, 5, 12),
        condition: ListingCondition.likeNew,
        quantity: 2,
        edition: '1st Edition, English',
        shippingMethods: const [ShippingMethod.pickup, ShippingMethod.meetup],
        pickupLocation: '123 Main St',
        pickupPhone: '(555) 123-4567',
        meetupLocation: 'Downtown, near the library',
        meetupPhone: '(555) 987-6543',
      );
      final back = MarketplaceListing.fromJson(listing.toJson());
      expect(back.toJson(), listing.toJson());
      expect(back.isbn, '978-3-16-148410-0');
      expect(back.publisher, 'Penguin Books');
      expect(back.publicationDate, DateTime.utc(2019, 5, 12));
      expect(back.condition, ListingCondition.likeNew);
      expect(back.quantity, 2);
      expect(back.edition, '1st Edition, English');
      expect(back.shippingMethods, [ShippingMethod.pickup, ShippingMethod.meetup]);
      expect(back.pickupLocation, '123 Main St');
      expect(back.pickupPhone, '(555) 123-4567');
      expect(back.meetupLocation, 'Downtown, near the library');
      expect(back.meetupPhone, '(555) 987-6543');
    });

    test('toJson/fromJson round-trips offer/swap/sold-out fields', () {
      final listing = MarketplaceListing(
        id: 'x3',
        title: 'Swap Book',
        authorName: 'Author',
        price: 'Swap',
        type: ListingType.physical,
        rating: 0,
        reviewCount: 0,
        offer: ListingOffer.swap,
        swapWantedFor: 'Another mystery novel',
        isSoldOut: true,
      );
      final back = MarketplaceListing.fromJson(listing.toJson());
      expect(back.toJson(), listing.toJson());
      expect(back.offer, ListingOffer.swap);
      expect(back.swapWantedFor, 'Another mystery novel');
      expect(back.isSoldOut, isTrue);
    });

    test('missing offer/isSoldOut default to sale/false (pre-existing listings)', () {
      final l = MarketplaceListing.fromJson({
        'id': 'x',
        'title': 't',
        'authorName': 'a',
        'price': '\$1',
        'type': 'physical',
        'rating': 0,
        'reviewCount': 0,
      });
      expect(l.offer, ListingOffer.sale);
      expect(l.isSoldOut, isFalse);
    });

    test('unknown condition falls back to good', () {
      final l = MarketplaceListing.fromJson({
        'id': 'x',
        'title': 't',
        'authorName': 'a',
        'price': '\$1',
        'type': 'physical',
        'rating': 0,
        'reviewCount': 0,
        'condition': 'pristine',
      });
      expect(l.condition, ListingCondition.good);
    });

    test('unknown listing type falls back to physical', () {
      final l = MarketplaceListing.fromJson({
        'id': 'x',
        'title': 't',
        'authorName': 'a',
        'price': '\$1',
        'type': 'hologram',
        'rating': 0,
        'reviewCount': 0,
      });
      expect(l.type, ListingType.physical);
    });

    test('legacy List<String> audioVolumes migrate to titled AudioVolumes',
        () {
      final l = MarketplaceListing.fromJson({
        'id': 'x',
        'title': 't',
        'authorName': 'a',
        'price': '\$1',
        'type': 'audio',
        'rating': 0,
        'reviewCount': 0,
        'audioVolumes': ['one.mp3', 'two.mp3'],
      });
      expect(l.audioVolumes.length, 2);
      expect(l.audioVolumes[0].title, 'Volume 1');
      expect(l.audioVolumes[0].fileName, 'one.mp3');
      expect(l.audioVolumes[1].title, 'Volume 2');
      expect(l.audioVolumes[1].fileName, 'two.mp3');
    });

    test('malformed audioVolumes payloads degrade to an empty list', () {
      final l = MarketplaceListing.fromJson({
        'id': 'x',
        'title': 't',
        'authorName': 'a',
        'price': '\$1',
        'type': 'audio',
        'rating': 0,
        'reviewCount': 0,
        'audioVolumes': 'garbage',
      });
      expect(l.audioVolumes, isEmpty);
    });
  });

  group('Purchase', () {
    test('toJson/fromJson round-trips', () {
      final purchase = Purchase(
        orderItemId: 'OI-1',
        listing: mockListings.first,
        purchasedAt: DateTime(2026, 7, 1, 12),
        orderId: 'ORD-1',
      );
      final back = Purchase.fromJson(purchase.toJson());
      expect(back.orderItemId, 'OI-1');
      expect(back.orderId, 'ORD-1');
      expect(back.purchasedAt, DateTime(2026, 7, 1, 12));
      expect(back.listing.toJson(), mockListings.first.toJson());
    });
  });

  group('Comment', () {
    test('toJson/fromJson round-trips', () {
      final comment = Comment(
        id: 'c9',
        postId: 'p1',
        author: mockUsers[2],
        text: 'Nice.',
        createdAt: DateTime(2026, 5, 5),
        likesCount: 2,
        isLiked: true,
      );
      final back = Comment.fromJson(comment.toJson());
      expect(back.toJson(), comment.toJson());
    });

    test('copyWith toggling like preserves identity fields', () {
      final c = mockComments.first.copyWith(isLiked: false, likesCount: 13);
      expect(c.id, mockComments.first.id);
      expect(c.isLiked, isFalse);
      expect(c.likesCount, 13);
    });
  });
}
