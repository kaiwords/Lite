import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/comment.dart';
import '../models/user.dart';
import 'supabase_service.dart';

/// Reads and writes [Comment] rows (joined with their author) in Supabase.
class CommentsRepository {
  static SupabaseClient get _client => SupabaseService.client;

  static Future<List<Comment>> fetchAll() async {
    final rows = await _client
        .from('comments')
        .select('*, author:users(*)')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => _commentFromRow((r as Map).cast<String, dynamic>()))
        .toList();
  }

  static Future<void> insert(Comment comment) => _client.from('comments').insert({
        'id': comment.id,
        'post_id': comment.postId,
        'author_id': comment.author.id,
        'text': comment.text,
      });

  static Comment _commentFromRow(Map<String, dynamic> row) {
    final authorRow = (row['author'] as Map).cast<String, dynamic>();
    final author = LitUser(
      id: authorRow['id'] as String,
      username: authorRow['username'] as String,
      displayName: authorRow['display_name'] as String,
      avatarUrl: authorRow['avatar_url'] as String?,
      bio: (authorRow['bio'] as String?) ?? '',
      followersCount: (authorRow['followers_count'] as num?)?.toInt() ?? 0,
      followingCount: (authorRow['following_count'] as num?)?.toInt() ?? 0,
      postsCount: (authorRow['posts_count'] as num?)?.toInt() ?? 0,
      earnings: (authorRow['earnings'] as num?)?.toDouble() ?? 0.0,
      isVerified: (authorRow['is_verified'] as bool?) ?? false,
    );
    return Comment(
      id: row['id'] as String,
      postId: row['post_id'] as String,
      author: author,
      text: row['text'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      likesCount: (row['likes_count'] as num?)?.toInt() ?? 0,
    );
  }
}
