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
