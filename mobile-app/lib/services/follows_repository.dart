import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Reads and writes `follows` rows in Supabase for a single follower.
class FollowsRepository {
  static SupabaseClient get _client => SupabaseService.client;

  static Future<Set<String>> fetchFollowing(String followerId) async {
    final rows = await _client
        .from('follows')
        .select('followee_id')
        .eq('follower_id', followerId);
    return (rows as List)
        .map((r) => (r as Map)['followee_id'] as String)
        .toSet();
  }

  static Future<void> follow(String followerId, String followeeId) =>
      _client.from('follows').insert({
        'follower_id': followerId,
        'followee_id': followeeId,
      });

  static Future<void> unfollow(String followerId, String followeeId) =>
      _client
          .from('follows')
          .delete()
          .eq('follower_id', followerId)
          .eq('followee_id', followeeId);
}
