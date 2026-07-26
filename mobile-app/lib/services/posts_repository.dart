import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/post.dart';
import '../models/user.dart';
import 'supabase_service.dart';

/// Reads and writes [Post] rows (joined with their author) in Supabase.
class PostsRepository {
  static SupabaseClient get _client => SupabaseService.client;

  static Future<List<Post>> fetchAll() async {
    final rows = await _client
        .from('posts')
        .select('*, author:users(*)')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => _postFromRow((r as Map).cast<String, dynamic>()))
        .toList();
  }

  static Future<void> insert(Post post) => _client.from('posts').insert({
        'id': post.id,
        'author_id': post.author.id,
        'title': post.title,
        'content': post.content,
        'category': post.category.name,
        'audio_url': post.audioUrl,
        'cover_image_url': post.coverImageUrl,
        'linked_listing_id': post.linkedListingId,
        'book_id': post.bookId,
      });

  static Post _postFromRow(Map<String, dynamic> row) {
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
    return Post(
      id: row['id'] as String,
      author: author,
      title: row['title'] as String,
      content: row['content'] as String,
      category: contentCategoryFromName(row['category'] as String?),
      createdAt: DateTime.parse(row['created_at'] as String),
      likesCount: (row['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (row['comments_count'] as num?)?.toInt() ?? 0,
      sharesCount: (row['shares_count'] as num?)?.toInt() ?? 0,
      audioUrl: row['audio_url'] as String?,
      coverImageUrl: row['cover_image_url'] as String?,
      linkedListingId: row['linked_listing_id'] as String?,
      bookId: row['book_id'] as String?,
    );
  }
}
