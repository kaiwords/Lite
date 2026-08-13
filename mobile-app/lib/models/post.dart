import 'user.dart';

// NOTE: This app has no backend, so there is no real per-post audio to serve.
// The `audioUrl` values below point at a small rotating set of freely
// licensed SoundHelix demo tracks (the same URLs commonly used for
// audio-player development/testing) — they are placeholders, not real
// narrations of the post content.

enum ContentCategory {
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

extension ContentCategoryLabel on ContentCategory {
  String get label => switch (this) {
    ContentCategory.poem => 'Poem',
    ContentCategory.book => 'Book',
    ContentCategory.joke => 'Joke',
    ContentCategory.novel => 'Novel',
    ContentCategory.article => 'Article',
    ContentCategory.story => 'Story',
    ContentCategory.essay => 'Essay',
    ContentCategory.haiku => 'Haiku',
    ContentCategory.biography => 'Biography',
    ContentCategory.shortStory => 'Short Story',
    ContentCategory.script => 'Script',
    ContentCategory.lyrics => 'Lyrics',
  };

  String get emoji => switch (this) {
    ContentCategory.poem => '🖊️',
    ContentCategory.book => '📖',
    ContentCategory.joke => '😄',
    ContentCategory.novel => '📚',
    ContentCategory.article => '📰',
    ContentCategory.story => '📝',
    ContentCategory.essay => '✍️',
    ContentCategory.haiku => '🌸',
    ContentCategory.biography => '👤',
    ContentCategory.shortStory => '📄',
    ContentCategory.script => '🎬',
    ContentCategory.lyrics => '🎵',
  };
}

/// An additional page in a multi-page post, beyond the post's main
/// title/content (which is always page one). [title] is null when the
/// writer chose not to show a title on this page.
class PostPage {
  final String? title;
  final String content;

  const PostPage({this.title, required this.content});

  Map<String, dynamic> toJson() => {'title': title, 'content': content};

  factory PostPage.fromJson(Map<String, dynamic> j) => PostPage(
        title: j['title'] as String?,
        content: j['content'] as String,
      );
}

class Post {
  final String id;
  final LitUser author;
  final String title;
  final String content;
  final ContentCategory category;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isLiked;
  final bool isFavourited;
  final String? audioUrl;
  final String? coverImageUrl;
  final String? linkedListingId;
  final String? bookId; // links to a Book in the reader
  final List<PostPage> pages; // additional pages beyond title/content

  const Post({
    required this.id,
    required this.author,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.isLiked = false,
    this.isFavourited = false,
    this.audioUrl,
    this.coverImageUrl,
    this.linkedListingId,
    this.bookId,
    this.pages = const [],
  });

  Post copyWith({
    bool? isLiked,
    bool? isFavourited,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
  }) =>
      Post(
        id: id,
        author: author,
        title: title,
        content: content,
        category: category,
        createdAt: createdAt,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        sharesCount: sharesCount ?? this.sharesCount,
        isLiked: isLiked ?? this.isLiked,
        isFavourited: isFavourited ?? this.isFavourited,
        audioUrl: audioUrl,
        coverImageUrl: coverImageUrl,
        linkedListingId: linkedListingId,
        bookId: bookId,
        pages: pages,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author.toJson(),
        'title': title,
        'content': content,
        'category': category.name,
        'createdAt': createdAt.toIso8601String(),
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'sharesCount': sharesCount,
        'isLiked': isLiked,
        'isFavourited': isFavourited,
        'audioUrl': audioUrl,
        'coverImageUrl': coverImageUrl,
        'linkedListingId': linkedListingId,
        'bookId': bookId,
        'pages': pages.map((p) => p.toJson()).toList(),
      };

  factory Post.fromJson(Map<String, dynamic> j) => Post(
        id: j['id'] as String,
        author: LitUser.fromJson((j['author'] as Map).cast<String, dynamic>()),
        title: j['title'] as String,
        content: j['content'] as String,
        category: contentCategoryFromName(j['category'] as String?),
        createdAt: DateTime.parse(j['createdAt'] as String),
        likesCount: (j['likesCount'] as num?)?.toInt() ?? 0,
        commentsCount: (j['commentsCount'] as num?)?.toInt() ?? 0,
        sharesCount: (j['sharesCount'] as num?)?.toInt() ?? 0,
        isLiked: (j['isLiked'] as bool?) ?? false,
        isFavourited: (j['isFavourited'] as bool?) ?? false,
        audioUrl: j['audioUrl'] as String?,
        coverImageUrl: j['coverImageUrl'] as String?,
        linkedListingId: j['linkedListingId'] as String?,
        bookId: j['bookId'] as String?,
        pages: (j['pages'] as List?)
                ?.map((p) => PostPage.fromJson((p as Map).cast<String, dynamic>()))
                .toList() ??
            const [],
      );
}

/// Resolves a [ContentCategory] from its `.name`, defaulting to poem.
ContentCategory contentCategoryFromName(String? name) =>
    ContentCategory.values.firstWhere(
      (c) => c.name == name,
      orElse: () => ContentCategory.poem,
    );
