import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../services/local_store.dart';

enum FeedFilter { following, writers }

enum FeedCategory {
  all,
  poem,
  book,
  joke,
  novel,
  article,
  story,
  essay,
  haiku,
  biography,
  shortStory,
  script,
  lyrics,
}

extension FeedCategoryLabel on FeedCategory {
  String get label => switch (this) {
    FeedCategory.all => 'All',
    FeedCategory.poem => 'Poems',
    FeedCategory.book => 'Books',
    FeedCategory.joke => 'Jokes',
    FeedCategory.novel => 'Novels',
    FeedCategory.article => 'Articles',
    FeedCategory.story => 'Stories',
    FeedCategory.essay => 'Essays',
    FeedCategory.haiku => 'Haiku',
    FeedCategory.biography => 'Biography',
    FeedCategory.shortStory => 'Short Stories',
    FeedCategory.script => 'Scripts',
    FeedCategory.lyrics => 'Lyrics',
  };
}

final feedFilterProvider = StateProvider<FeedFilter>((ref) => FeedFilter.following);

// ── Visible categories in the chip bar (user-customisable) ───────────────────

class VisibleCategoriesNotifier
    extends StateNotifier<Set<FeedCategory>> {
  VisibleCategoriesNotifier(super.initial);

  /// All categories except [FeedCategory.all] — the first-launch default.
  static Set<FeedCategory> defaults() =>
      FeedCategory.values.where((c) => c != FeedCategory.all).toSet();

  void toggle(FeedCategory cat) {
    if (state.contains(cat)) {
      state = Set.unmodifiable({...state}..remove(cat));
    } else {
      state = Set.unmodifiable({...state, cat});
    }
  }
}

final visibleCategoriesProvider =
    StateNotifierProvider<VisibleCategoriesNotifier, Set<FeedCategory>>((ref) {
  final savedNames = LocalStore.instance.loadVisibleCategories();
  final initial = savedNames == null
      ? VisibleCategoriesNotifier.defaults()
      : savedNames
          .map((n) => FeedCategory.values
              .firstWhere((c) => c.name == n, orElse: () => FeedCategory.all))
          .where((c) => c != FeedCategory.all)
          .toSet();
  final notifier = VisibleCategoriesNotifier(initial);
  notifier.addListener(
    (s) => LocalStore.instance
        .saveVisibleCategories(s.map((c) => c.name).toList()),
    fireImmediately: false,
  );
  return notifier;
});
final feedCategoryProvider = StateProvider<FeedCategory>((ref) => FeedCategory.all);

/// Separate category filter for the Audio tab — does not affect the home feed.
final audioCategoryProvider = StateProvider<FeedCategory>((ref) => FeedCategory.all);

/// Following / Narrators filter for the Audio tab.
enum AudioFilter { following, narrators }

final audioFilterProvider =
    StateProvider<AudioFilter>((ref) => AudioFilter.following);

final feedPostsProvider = Provider<List<Post>>((ref) {
  final category = ref.watch(feedCategoryProvider);
  if (category == FeedCategory.all) return mockPosts;
  final contentCategory = ContentCategory.values.firstWhere(
    (c) => c.name == category.name,
    orElse: () => ContentCategory.poem,
  );
  return mockPosts.where((p) => p.category == contentCategory).toList();
});

class PostsNotifier extends StateNotifier<List<Post>> {
  PostsNotifier(super.initial);

  void toggleLike(String postId) {
    state = state.map((p) {
      if (p.id != postId) return p;
      return p.copyWith(
        isLiked: !p.isLiked,
        likesCount: p.isLiked ? p.likesCount - 1 : p.likesCount + 1,
      );
    }).toList();
  }

  void toggleFavourite(String postId) {
    state = state.map((p) {
      if (p.id != postId) return p;
      return p.copyWith(isFavourited: !p.isFavourited);
    }).toList();
  }

  void addPost(Post post) {
    state = [post, ...state];
  }

  /// Bumps a post's comment count when a new comment is added.
  void addComment(String postId) {
    state = state
        .map((p) => p.id == postId
            ? p.copyWith(commentsCount: p.commentsCount + 1)
            : p)
        .toList();
  }

  /// Bumps a post's share count when it is shared.
  void addShare(String postId) {
    state = state
        .map((p) =>
            p.id == postId ? p.copyWith(sharesCount: p.sharesCount + 1) : p)
        .toList();
  }
}

final postsNotifierProvider = StateNotifierProvider<PostsNotifier, List<Post>>(
  (ref) {
    final notifier = PostsNotifier(LocalStore.instance.loadPosts() ?? mockPosts);
    notifier.addListener(LocalStore.instance.savePosts, fireImmediately: false);
    return notifier;
  },
);

final filteredPostsProvider = Provider<List<Post>>((ref) {
  final posts = ref.watch(postsNotifierProvider);
  final category = ref.watch(feedCategoryProvider);
  if (category == FeedCategory.all) return posts;
  final contentCategory = ContentCategory.values.firstWhere(
    (c) => c.name == category.name,
    orElse: () => ContentCategory.poem,
  );
  return posts.where((p) => p.category == contentCategory).toList();
});
