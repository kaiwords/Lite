import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/post.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../providers/follow_provider.dart';
import '../theme/app_theme.dart';
import '../utils/rich_text.dart';
import 'comments_sheet.dart';
import 'marketplace_badge.dart';
import 'share_sheet.dart';
import 'tip_sheet.dart';

class PostCard extends ConsumerWidget {
  final Post post;
  final VoidCallback? onContentTap;

  const PostCard({super.key, required this.post, this.onContentTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.cardBorder;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ref.watch(feedCategoryProvider) == FeedCategory.all)
            _CategoryBadge(category: post.category, isDark: isDark),
          if (post.linkedListingId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: MarketplaceBadge(listingId: post.linkedListingId!, isDark: isDark),
            ),
          _ContentSection(post: post, isDark: isDark, onTap: onContentTap),
          Divider(height: 1, color: borderColor),
          _EngagementRow(post: post, isDark: isDark, ref: ref),
          Divider(height: 1, color: borderColor),
          _AuthorRow(post: post, isDark: isDark),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final ContentCategory category;
  final bool isDark;
  const _CategoryBadge({required this.category, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${category.emoji} ${category.label}',
              style: GoogleFonts.lato(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkAccent : AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentSection extends StatelessWidget {
  final Post post;
  final bool isDark;
  final VoidCallback? onTap;
  const _ContentSection({required this.post, required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final bodyColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final isPoetic = post.category == ContentCategory.poem ||
        post.category == ContentCategory.haiku;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: titleColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Builder(builder: (context) {
            final bodyStyle = isPoetic
                ? GoogleFonts.lora(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: bodyColor,
                    height: 1.8,
                  )
                : GoogleFonts.lora(
                    fontSize: 14,
                    color: bodyColor,
                    height: 1.65,
                  );
            return Text.rich(
              TextSpan(
                children: buildFormattedSpans(
                  post.content,
                  bodyStyle,
                  accent: isDark ? AppColors.darkAccent : AppColors.accent,
                ),
              ),
              maxLines: isPoetic ? 10 : 4,
              overflow: TextOverflow.ellipsis,
            );
          }),
          if (!isPoetic) ...[
            const SizedBox(height: 6),
            Text(
              'Read more',
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkAccent : AppColors.accent,
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }
}

class _EngagementRow extends StatelessWidget {
  final Post post;
  final bool isDark;
  final WidgetRef ref;
  const _EngagementRow({required this.post, required this.isDark, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          _EngagementButton(
            icon: post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            label: _formatCount(post.likesCount),
            color: post.isLiked
                ? AppColors.like
                : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
            onTap: () => ref.read(postsNotifierProvider.notifier).toggleLike(post.id),
          ),
          _EngagementButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: _formatCount(post.commentsCount),
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            onTap: () => showCommentsSheet(context, post.id),
          ),
          _EngagementButton(
            icon: Icons.share_outlined,
            label: _formatCount(post.sharesCount),
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            onTap: () => sharePost(context, ref, post),
          ),
          const Spacer(),
          _EngagementButton(
            icon: post.isFavourited
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            label: '',
            color: post.isFavourited
                ? AppColors.bookmark
                : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
            onTap: () =>
                ref.read(postsNotifierProvider.notifier).toggleFavourite(post.id),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}

class _EngagementButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _EngagementButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        // Minimum 44x44 tappable area (accessibility touch target guidance)
        // even though the icon itself stays visually compact.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: color),
                  if (label.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: GoogleFonts.lato(fontSize: 13, color: color, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthorRow extends ConsumerWidget {
  final Post post;
  final bool isDark;
  const _AuthorRow({required this.post, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final metaColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final currentUser = ref.watch(currentUserProvider);
    final isSelf = currentUser?.id == post.author.id;
    final isFollowing = ref.watch(followNotifierProvider).contains(post.author.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.push('/user/${post.author.id}'),
            child: _Avatar(user: post.author, isDark: isDark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/user/${post.author.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          post.author.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: nameColor,
                          ),
                        ),
                      ),
                      if (post.author.isVerified) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified_rounded,
                          size: 13,
                          color: isDark ? AppColors.darkAccent : AppColors.accent,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    timeago.format(post.createdAt),
                    style: GoogleFonts.lato(fontSize: 11, color: metaColor),
                  ),
                ],
              ),
            ),
          ),
          // The action buttons shrink as a group when the row is too tight
          // (narrow screens / wide fonts) instead of overflowing it. The
          // generous flex keeps them at natural size whenever they fit.
          Flexible(
            flex: 3,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isSelf) ...[
                    _FollowPill(
                      isFollowing: isFollowing,
                      isDark: isDark,
                      onTap: () {
                        final notifier =
                            ref.read(followNotifierProvider.notifier);
                        // Returned sync result deliberately ignored: follows
                        // apply locally either way; a failed backend write is
                        // non-fatal.
                        if (isFollowing) {
                          notifier.unfollow(post.author.id);
                        } else {
                          notifier.follow(post.author.id);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  _SupportButton(
                      isDark: isDark, authorName: post.author.displayName),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowPill extends StatelessWidget {
  final bool isFollowing;
  final bool isDark;
  final VoidCallback onTap;
  const _FollowPill({
    required this.isFollowing,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.darkAccent : AppColors.accent;
    // Solid fill uses the darker accentOnFill token so the white label keeps
    // WCAG AA contrast (plain `accent` is only ~3:1 against white).
    final fill = isDark ? AppColors.darkAccentOnFill : AppColors.accentOnFill;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.transparent : fill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isFollowing ? accent : fill, width: 1),
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isFollowing ? accent : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final dynamic user;
  final bool isDark;
  const _Avatar({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
      child: Text(
        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
        style: GoogleFonts.playfairDisplay(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkAccent : AppColors.accent,
        ),
      ),
    );
  }
}

class _SupportButton extends StatelessWidget {
  final bool isDark;
  final String authorName;
  const _SupportButton({required this.isDark, required this.authorName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => TipSheet.show(context, authorName: authorName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkAccent : AppColors.accent,
            width: 1,
          ),
        ),
        child: Text(
          'Support',
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkAccent : AppColors.accent,
          ),
        ),
      ),
    );
  }
}
