import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/comment.dart';
import '../services/comments_repository.dart';
import '../services/local_store.dart';

class CommentsNotifier extends StateNotifier<List<Comment>> {
  CommentsNotifier(super.initial);

  /// Default comments seeded on first launch.
  static List<Comment> seed() => List<Comment>.from(mockComments);

  /// Prepends [comment] locally right away; returns whether the backend
  /// insert also succeeded so the UI can tell the user when it didn't sync.
  Future<bool> add(Comment comment) async {
    state = [comment, ...state];
    try {
      await CommentsRepository.insert(comment);
      return true;
    } catch (_) {
      return false;
    }
  }

  void toggleLike(String id) => state = [
        for (final c in state)
          if (c.id == id)
            c.copyWith(
              isLiked: !c.isLiked,
              likesCount: c.isLiked ? c.likesCount - 1 : c.likesCount + 1,
            )
          else
            c,
      ];

  /// Replaces local/mock comments with the current Supabase data once it
  /// loads, preserving each comment's locally-tracked like flag by id.
  Future<void> loadFromSupabase() async {
    try {
      final remote = await CommentsRepository.fetchAll();
      if (remote.isEmpty) return;
      final localById = {for (final c in state) c.id: c};
      state = remote.map((r) {
        final local = localById[r.id];
        return local == null ? r : r.copyWith(isLiked: local.isLiked);
      }).toList();
    } catch (_) {
      // Offline or request failed — keep the local/mock comments already shown.
    }
  }
}

final commentsProvider =
    StateNotifierProvider<CommentsNotifier, List<Comment>>((ref) {
  final notifier = CommentsNotifier(
      LocalStore.instance.loadComments() ?? CommentsNotifier.seed());
  notifier.addListener(LocalStore.instance.saveComments, fireImmediately: false);
  notifier.loadFromSupabase();
  return notifier;
});

/// Comments for a single post, newest first.
final commentsForPostProvider =
    Provider.family<List<Comment>, String>((ref, postId) {
  final all = ref.watch(commentsProvider);
  return all.where((c) => c.postId == postId).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});
