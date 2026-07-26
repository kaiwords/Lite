import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/follows_repository.dart';
import '../services/local_store.dart';
import 'auth_provider.dart';

class FollowNotifier extends StateNotifier<Set<String>> {
  final Ref _ref;
  FollowNotifier(super.initial, this._ref);

  /// Read at every call (not captured at provider creation) so a logout/login
  /// without a full app restart always writes with the right account.
  String? get _followerId => _ref.read(currentUserProvider)?.id;

  /// Applies the follow locally right away and returns whether the backend
  /// write also succeeded. With no signed-in profile the local state still
  /// updates but the backend write is skipped (returns false).
  Future<bool> follow(String userId) async {
    state = {...state, userId};
    final followerId = _followerId;
    if (followerId == null) return false;
    try {
      await FollowsRepository.follow(followerId, userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Same contract as [follow]: local removal always happens; the return
  /// value reports whether the backend delete went through.
  Future<bool> unfollow(String userId) async {
    state = state.difference({userId});
    final followerId = _followerId;
    if (followerId == null) return false;
    try {
      await FollowsRepository.unfollow(followerId, userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool isFollowing(String userId) => state.contains(userId);

  /// Merges in the current user's Supabase follow set once it loads.
  Future<void> loadFromSupabase() async {
    final followerId = _followerId;
    if (followerId == null) return;
    try {
      final remote = await FollowsRepository.fetchFollowing(followerId);
      state = {...state, ...remote};
    } catch (_) {
      // Offline or request failed — keep the locally-saved follows already shown.
    }
  }
}

final followNotifierProvider =
    StateNotifierProvider<FollowNotifier, Set<String>>((ref) {
  final saved = LocalStore.instance.loadFollows();
  final notifier =
      FollowNotifier(saved == null ? <String>{} : saved.toSet(), ref);
  notifier.addListener(LocalStore.instance.saveFollows, fireImmediately: false);
  notifier.loadFromSupabase();
  return notifier;
});
