import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_store.dart';

class FollowNotifier extends StateNotifier<Set<String>> {
  FollowNotifier(super.initial);

  void follow(String userId) => state = {...state, userId};
  void unfollow(String userId) => state = state.difference({userId});
  bool isFollowing(String userId) => state.contains(userId);
}

final followNotifierProvider =
    StateNotifierProvider<FollowNotifier, Set<String>>((ref) {
  final saved = LocalStore.instance.loadFollows();
  final notifier = FollowNotifier(saved == null ? <String>{} : saved.toSet());
  notifier.addListener(LocalStore.instance.saveFollows, fireImmediately: false);
  return notifier;
});
