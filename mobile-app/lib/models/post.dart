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
      );
}

/// Resolves a [ContentCategory] from its `.name`, defaulting to poem.
ContentCategory contentCategoryFromName(String? name) =>
    ContentCategory.values.firstWhere(
      (c) => c.name == name,
      orElse: () => ContentCategory.poem,
    );

final mockPosts = [
  Post(
    id: 'p1',
    author: mockUsers[0],
    title: 'Between the Lines',
    content:
        'There is a language\nthat lives between the words —\nin the pause before a name is spoken,\nin the breath after a door has closed.\n\nI have been learning it my whole life,\nthis tongue of silences,\nthis grammar of the almost-said.\n\nSome days I am fluent.\nOther days, I cannot even begin.',
    category: ContentCategory.poem,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    likesCount: 234,
    commentsCount: 18,
    sharesCount: 42,
    isLiked: true,
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    linkedListingId: 'm9', // Audio Book in Marketplace
  ),
  Post(
    id: 'p2',
    author: mockUsers[2],
    title: 'Why We Read Alone But Feel Together',
    content:
        'There is something paradoxical about reading. It is the most solitary of activities — just you, the page, and the dim lamplight. And yet, at the end of every great book, you feel as though you have spent time with company. Real company. The kind that changes you.\n\nThis is the miracle literature performs quietly, without fanfare: it dissolves the self long enough for you to inhabit another\'s consciousness entirely.',
    category: ContentCategory.article,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    likesCount: 891,
    commentsCount: 67,
    sharesCount: 203,
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    linkedListingId: 'm10', // Audio Book in Marketplace
  ),
  Post(
    id: 'p3',
    author: mockUsers[1],
    title: 'My Wi-Fi Password',
    content:
        'My therapist told me to set boundaries.\nSo I changed my Wi-Fi password\nto my ex\'s name.\n\nNow every time someone asks for it\nI have to say:\n"It\'s complicated."',
    category: ContentCategory.joke,
    createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    likesCount: 1204,
    commentsCount: 94,
    sharesCount: 512,
    isLiked: true,
    isFavourited: true,
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
  ),
  Post(
    id: 'p4',
    author: mockUsers[3],
    title: 'Morning Without You',
    content:
        'Coffee grows cold.\nYour chair still holds your shape —\nI do not sit there.',
    category: ContentCategory.haiku,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    likesCount: 567,
    commentsCount: 33,
    sharesCount: 88,
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    linkedListingId: 'm12', // Audio Book in Marketplace
  ),
  Post(
    id: 'p7',
    author: mockUsers[3],
    title: 'The Ember Throne',
    content:
        'The letter arrived on a morning that smelled of rain and old iron.\n\n'
        'Sera did not open it at first. Letters from the capital had a weight '
        'that ordinary envelopes could not contain — as though the parchment '
        'itself had absorbed the ambitions of every hand it passed through.\n\n'
        'She set it on the windowsill and brewed tea instead.',
    category: ContentCategory.book,
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    likesCount: 528,
    commentsCount: 41,
    sharesCount: 93,
    linkedListingId: 'mBook1',
    bookId: 'b1',
  ),
  Post(
    id: 'p5',
    author: mockUsers[0],
    title: 'The Glass House — Chapter One',
    content:
        'The town of Belcroft had one rule everyone knew but no one said aloud: you did not look at the Glass House after dark.\n\nRosalind had been breaking rules her whole life, which is perhaps why, on the night of her twenty-third birthday, she found herself standing on the hill above town, staring directly at the structure that no one dared name.',
    category: ContentCategory.novel,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    likesCount: 412,
    commentsCount: 51,
    sharesCount: 76,
    isFavourited: true,
    linkedListingId: 'm1', // Physical Book in Marketplace
  ),
  Post(
    id: 'p6',
    author: mockUsers[2],
    title: 'On Solitude and the Creative Mind',
    content:
        'Every artist knows the particular agony of the empty page. But what we talk about less is the gift that lives inside that emptiness — if you are willing to sit with it long enough.\n\nSolitude is not loneliness. Loneliness is the ache of absence. Solitude is the discovery of presence: your own, undiluted.',
    category: ContentCategory.essay,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    likesCount: 723,
    commentsCount: 45,
    sharesCount: 134,
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
  ),
];
