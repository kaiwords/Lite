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
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
          if (!isSelf) ...[
            _FollowPill(
              isFollowing: isFollowing,
              isDark: isDark,
              onTap: () {
                final notifier = ref.read(followNotifierProvider.notifier);
                if (isFollowing) {
                  notifier.unfollow(post.author.id);
                } else {
                  notifier.follow(post.author.id);
                }
              },
            ),
            const SizedBox(width: 8),
          ],
          _SupportButton(isDark: isDark),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.transparent : accent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent, width: 1),
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
  const _SupportButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showTipSheet(context, isDark),
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

  void _showTipSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _TipSheet(),
    );
  }
}

class _TipSheet extends StatefulWidget {
  const _TipSheet();
  @override
  State<_TipSheet> createState() => _TipSheetState();
}

class _TipSheetState extends State<_TipSheet> {
  int _selectedAmount = 2;

  @override
  Widget build(BuildContext context) {
    final amounts = [1, 2, 5, 10, 20];
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Support this writer', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Send a tip to show your appreciation',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: amounts.map((amt) {
              final selected = amt == _selectedAmount;
              return GestureDetector(
                onTap: () => setState(() => _selectedAmount = amt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 58,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accent : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '\$$amt',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: selected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tip of \$$_selectedAmount sent! ✨'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(
                'Send \$$_selectedAmount tip',
                style: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
