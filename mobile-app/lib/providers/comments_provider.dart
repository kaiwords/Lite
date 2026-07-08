import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/comment.dart';
import '../services/local_store.dart';

class CommentsNotifier extends StateNotifier<List<Comment>> {
  CommentsNotifier(super.initial);

  /// Default comments seeded on first launch.
  static List<Comment> seed() => List<Comment>.from(mockComments);

  void add(Comment comment) => state = [comment, ...state];

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
}

final commentsProvider =
    StateNotifierProvider<CommentsNotifier, List<Comment>>((ref) {
  final notifier = CommentsNotifier(
      LocalStore.instance.loadComments() ?? CommentsNotifier.seed());
  notifier.addListener(LocalStore.instance.saveComments, fireImmediately: false);
  return notifier;
});

/// Comments for a single post, newest first.
final commentsForPostProvider =
    Provider.family<List<Comment>, String>((ref, postId) {
  final all = ref.watch(commentsProvider);
  return all.where((c) => c.postId == postId).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});
