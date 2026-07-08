import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/comment.dart';
import '../providers/auth_provider.dart';
import '../providers/comments_provider.dart';
import '../providers/feed_provider.dart';
import '../theme/app_theme.dart';

/// Opens the comments thread for [postId] as a modal bottom sheet.
Future<void> showCommentsSheet(BuildContext context, String postId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CommentsSheet(postId: postId),
  );
}

class CommentsSheet extends ConsumerStatefulWidget {
  final String postId;
  const CommentsSheet({super.key, required this.postId});

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final can = _controller.text.trim().isNotEmpty;
      if (can != _canSend) setState(() => _canSend = can);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    ref.read(commentsProvider.notifier).add(Comment(
          id: 'c${DateTime.now().microsecondsSinceEpoch}',
          postId: widget.postId,
          author: user,
          text: text,
          createdAt: DateTime.now(),
        ));
    ref.read(postsNotifierProvider.notifier).addComment(widget.postId);
    _controller.clear();
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final divColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final titleColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    final comments = ref.watch(commentsForPostProvider(widget.postId));
    final post = ref
        .watch(postsNotifierProvider)
        .where((p) => p.id == widget.postId)
        .firstOrNull;
    final count = post?.commentsCount ?? comments.length;

    final media = MediaQuery.of(context);
    // Cap to the space left above the keyboard so the list shrinks instead of
    // overflowing when the composer is focused.
    final maxSheet = media.size.height * 0.85;
    final available =
        media.size.height - media.viewInsets.bottom - media.padding.top - 8;
    final sheetHeight = maxSheet < available ? maxSheet : available;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Grab handle
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: divColor, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
              child: Row(
                children: [
                  Text('Comments',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: titleColor)),
                  const SizedBox(width: 8),
                  Text(_fmt(count),
                      style:
                          GoogleFonts.lato(fontSize: 14, color: mutedColor)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: mutedColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: divColor),
            // List
            Expanded(
              child: comments.isEmpty
                  ? _EmptyComments(mutedColor: mutedColor)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: comments.length,
                      itemBuilder: (_, i) =>
                          _CommentRow(comment: comments[i], isDark: isDark),
                    ),
            ),
            Divider(height: 1, color: divColor),
            _composer(isDark, divColor, mutedColor, titleColor),
          ],
        ),
      ),
    );
  }

  Widget _composer(
      bool isDark, Color divColor, Color mutedColor, Color titleColor) {
    final user = ref.watch(currentUserProvider);
    final fieldBg =
        isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Avatar(initial: _initial(user?.displayName), size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.lato(fontSize: 14, color: titleColor),
                  decoration: InputDecoration(
                    hintText: 'Add a comment…',
                    hintStyle:
                        GoogleFonts.lato(fontSize: 14, color: mutedColor),
                    filled: true,
                    fillColor: fieldBg,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send_rounded,
                  color: _canSend ? AppColors.accent : mutedColor),
              onPressed: _canSend ? _send : null,
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

String _initial(String? name) =>
    (name == null || name.isEmpty) ? '?' : name[0].toUpperCase();

class _CommentRow extends ConsumerWidget {
  final Comment comment;
  final bool isDark;
  const _CommentRow({required this.comment, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final bodyColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(initial: _initial(comment.author.displayName), size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.author.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: titleColor),
                      ),
                    ),
                    if (comment.author.isVerified) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.verified_rounded,
                          size: 12, color: AppColors.accent),
                    ],
                    const SizedBox(width: 6),
                    Text(
                      timeago.format(comment.createdAt, locale: 'en_short'),
                      style: GoogleFonts.lato(fontSize: 11, color: mutedColor),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  comment.text,
                  style: GoogleFonts.lato(
                      fontSize: 14, height: 1.35, color: bodyColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Like
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () =>
                ref.read(commentsProvider.notifier).toggleLike(comment.id),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    comment.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 16,
                    color: comment.isLiked ? AppColors.like : mutedColor,
                  ),
                  if (comment.likesCount > 0) ...[
                    const SizedBox(height: 2),
                    Text('${comment.likesCount}',
                        style: GoogleFonts.lato(
                            fontSize: 11, color: mutedColor)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initial;
  final double size;
  const _Avatar({required this.initial, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.playfairDisplay(
              fontSize: size * 0.42,
              fontWeight: FontWeight.w700,
              color: AppColors.accent),
        ),
      ),
    );
  }
}

class _EmptyComments extends StatelessWidget {
  final Color mutedColor;
  const _EmptyComments({required this.mutedColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 48, color: mutedColor),
          const SizedBox(height: 10),
          Text('No comments yet',
              style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: mutedColor)),
          const SizedBox(height: 2),
          Text('Be the first to share what you think.',
              style: GoogleFonts.lato(fontSize: 13, color: mutedColor)),
        ],
      ),
    );
  }
}
