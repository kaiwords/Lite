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

  /// Pushes the locally-edited profile fields (username / display name / bio)
  /// to the user's row.
  static Future<void> updateProfile(LitUser user) => _client
      .from('users')
      .update({
        'username': user.username,
        'display_name': user.displayName,
        'bio': user.bio,
      })
      .eq('id', user.id);
}
