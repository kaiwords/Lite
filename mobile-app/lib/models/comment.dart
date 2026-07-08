import 'user.dart';

class Comment {
  final String id;
  final String postId;
  final LitUser author;
  final String text;
  final DateTime createdAt;
  final int likesCount;
  final bool isLiked;

  const Comment({
    required this.id,
    required this.postId,
    required this.author,
    required this.text,
    required this.createdAt,
    this.likesCount = 0,
    this.isLiked = false,
  });

  Comment copyWith({int? likesCount, bool? isLiked}) => Comment(
        id: id,
        postId: postId,
        author: author,
        text: text,
        createdAt: createdAt,
        likesCount: likesCount ?? this.likesCount,
        isLiked: isLiked ?? this.isLiked,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'author': author.toJson(),
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'likesCount': likesCount,
        'isLiked': isLiked,
      };

  factory Comment.fromJson(Map<String, dynamic> j) => Comment(
        id: j['id'] as String,
        postId: j['postId'] as String,
        author: LitUser.fromJson((j['author'] as Map).cast<String, dynamic>()),
        text: j['text'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        likesCount: (j['likesCount'] as num?)?.toInt() ?? 0,
        isLiked: (j['isLiked'] as bool?) ?? false,
      );
}

/// A few seeded comments so threads aren't empty on first launch.
final mockComments = <Comment>[
  Comment(
    id: 'c1',
    postId: 'p1',
    author: mockUsers[2],
    text: 'The "grammar of the almost-said" — this gave me chills. Saving it.',
    createdAt: DateTime.now().subtract(const Duration(minutes: 38)),
    likesCount: 14,
    isLiked: true,
  ),
  Comment(
    id: 'c2',
    postId: 'p1',
    author: mockUsers[3],
    text: 'Some days I am fluent. Other days I cannot even begin. Felt that.',
    createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 12)),
    likesCount: 6,
  ),
  Comment(
    id: 'c3',
    postId: 'p2',
    author: mockUsers[1],
    text:
        'This is exactly why I keep a notebook of lines from books — that "real company" lingers.',
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    likesCount: 21,
  ),
  Comment(
    id: 'c4',
    postId: 'p3',
    author: mockUsers[0],
    text: '"It\'s complicated" 😂 I\'m stealing this.',
    createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    likesCount: 33,
    isLiked: true,
  ),
  Comment(
    id: 'c5',
    postId: 'p3',
    author: mockUsers[3],
    text: 'Therapist-approved chaos. Take my like.',
    createdAt: DateTime.now().subtract(const Duration(hours: 7)),
    likesCount: 9,
  ),
  Comment(
    id: 'c6',
    postId: 'p7',
    author: mockUsers[0],
    text: 'That opening line does so much work. "Rain and old iron." Hooked.',
    createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 20)),
    likesCount: 11,
  ),
];
