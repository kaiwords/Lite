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
        .select('*, author:users(*), post_pages(*)')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => _postFromRow((r as Map).cast<String, dynamic>()))
        .toList();
  }

  static Future<void> insert(Post post) async {
    await _client.from('posts').insert({
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
    if (post.pages.isNotEmpty) {
      await _client.from('post_pages').insert([
        for (var i = 0; i < post.pages.length; i++)
          {
            'post_id': post.id,
            'position': i,
            'title': post.pages[i].title,
            'content': post.pages[i].content,
          },
      ]);
    }
  }

  static Post _postFromRow(Map<String, dynamic> row) {
    final authorRow = (row['author'] as Map).cast<String, dynamic>();
    final pageRows = (row['post_pages'] as List? ?? [])
        .map((r) => (r as Map).cast<String, dynamic>())
        .toList()
      ..sort((a, b) =>
          ((a['position'] as num?)?.toInt() ?? 0)
              .compareTo((b['position'] as num?)?.toInt() ?? 0));
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
      pages: pageRows
          .map((r) => PostPage(title: r['title'] as String?, content: r['content'] as String))
          .toList(),
    );
  }
}
