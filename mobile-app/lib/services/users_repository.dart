import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user.dart';
import 'supabase_service.dart';

/// Reads and writes `public.users` rows in Supabase.
class UsersRepository {
  static SupabaseClient get _client => SupabaseService.client;

  /// Fetches a single user by id, or null if no row exists.
  static Future<LitUser?> fetchById(String id) async {
    final row =
        await _client.from('users').select().eq('id', id).maybeSingle();
    return row == null ? null : LitUser.fromSupabaseRow(row);
  }

  /// Batch-fetches users by id — used to resolve buyer display names for
  /// the Sales tab without one query per sale.
  static Future<List<LitUser>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await _client.from('users').select().inFilter('id', ids);
    return (rows as List)
        .map((r) => LitUser.fromSupabaseRow((r as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Pushes the locally-edited profile fields (username / display name /
  /// bio / avatar / cover photo) to the user's row.
  static Future<void> updateProfile(LitUser user) => _client
      .from('users')
      .update({
        'username': user.username,
        'display_name': user.displayName,
        'bio': user.bio,
        'avatar_url': user.avatarUrl,
        'cover_image_url': user.coverImageUrl,
      })
      .eq('id', user.id);
}
