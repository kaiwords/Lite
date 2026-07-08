import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/marketplace.dart';
import '../models/post.dart';
import '../providers/feed_provider.dart';
import '../theme/app_theme.dart';
import 'audio_marketplace_badge.dart';
import 'comments_sheet.dart';
import 'share_sheet.dart';

class AudioPostCard extends ConsumerWidget {
  final Post post;

  const AudioPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.cardBorder;
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    // Resolve linked audio listing (only if type is audio)
    final linkedListing = post.linkedListingId != null
        ? mockListings
            .where((l) =>
                l.id == post.linkedListingId && l.type == ListingType.audio)
            .firstOrNull
        : null;

    // Live post (for reactive engagement state)
    final livePost = ref
        .watch(postsNotifierProvider)
        .firstWhere((p) => p.id == post.id, orElse: () => post);

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
          // ── Category badge ──────────────────────────────────────────────
          Padding(
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
                    '${post.category.emoji} ${post.category.label}',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkAccent : AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Audio marketplace badge ─────────────────────────────────────
          if (linkedListing != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: AudioMarketplaceBadge(
                listingId: linkedListing.id,
                isDark: isDark,
              ),
            ),

          // ── Title ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Text(
              post.title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: titleColor,
                height: 1.3,
              ),
            ),
          ),

          // ── Mini audio player ───────────────────────────────────────────
          _MiniPlayer(isDark: isDark),

          Divider(height: 1, color: borderColor),

          // ── Engagement row ──────────────────────────────────────────────
          _EngagementRow(post: livePost, isDark: isDark, ref: ref),

          Divider(height: 1, color: borderColor),

          // ── Author row ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.push('/user/${post.author.id}'),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.surfaceVariant,
                    child: Text(
                      post.author.displayName[0].toUpperCase(),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkAccent : AppColors.accent,
                      ),
                    ),
                  ),
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
                          Text(
                            post.author.displayName,
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (post.author.isVerified) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.verified_rounded,
                                size: 12,
                                color: isDark
                                    ? AppColors.darkAccent
                                    : AppColors.accent),
                          ],
                        ],
                      ),
                      Text(
                        timeago.format(post.createdAt),
                        style: GoogleFonts.lato(
                            fontSize: 11, color: mutedColor),
                      ),
                    ],
                    ),
                  ),
                ),
                // Support button
                GestureDetector(
                  onTap: () => _showTip(context, post.author.displayName),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.surfaceVariant,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTip(BuildContext context, String authorName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _TipSheet(authorName: authorName),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini audio player (static UI — progress + play controls)
// ─────────────────────────────────────────────────────────────────────────────

class _MiniPlayer extends StatelessWidget {
  final bool isDark;
  const _MiniPlayer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(
        children: [
          // Play button
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          // Progress bar
          Expanded(
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2.5,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: AppColors.accent,
                    inactiveTrackColor:
                        isDark ? AppColors.darkDivider : AppColors.divider,
                    thumbColor: AppColors.accent,
                  ),
                  child: Slider(value: 0.0, onChanged: (_) {}),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0:00',
                          style: GoogleFonts.lato(
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.textMuted)),
                      Text('–:––',
                          style: GoogleFonts.lato(
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Engagement row — Like, Comment, Share, Favourite
// ─────────────────────────────────────────────────────────────────────────────

class _EngagementRow extends StatelessWidget {
  final Post post;
  final bool isDark;
  final WidgetRef ref;
  const _EngagementRow(
      {required this.post, required this.isDark, required this.ref});

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          _Btn(
            icon: post.isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            label: _fmt(post.likesCount),
            color: post.isLiked ? AppColors.like : muted,
            onTap: () =>
                ref.read(postsNotifierProvider.notifier).toggleLike(post.id),
          ),
          _Btn(
            icon: Icons.chat_bubble_outline_rounded,
            label: _fmt(post.commentsCount),
            color: muted,
            onTap: () => showCommentsSheet(context, post.id),
          ),
          _Btn(
            icon: Icons.share_outlined,
            label: _fmt(post.sharesCount),
            color: muted,
            onTap: () => sharePost(context, ref, post),
          ),
          const Spacer(),
          _Btn(
            icon: post.isFavourited
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            label: '',
            color: post.isFavourited ? AppColors.bookmark : muted,
            onTap: () => ref
                .read(postsNotifierProvider.notifier)
                .toggleFavourite(post.id),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Btn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

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
              Text(label,
                  style: GoogleFonts.lato(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.w500)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tip sheet (reused from post_card.dart pattern)
// ─────────────────────────────────────────────────────────────────────────────

class _TipSheet extends StatefulWidget {
  final String authorName;
  const _TipSheet({required this.authorName});

  @override
  State<_TipSheet> createState() => _TipSheetState();
}

class _TipSheetState extends State<_TipSheet> {
  int _selectedAmount = 2;
  static const _amounts = [1, 2, 5, 10, 20];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Support ${widget.authorName}',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text('Send a tip to show your appreciation',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _amounts.map((amt) {
              final sel = amt == _selectedAmount;
              return GestureDetector(
                onTap: () => setState(() => _selectedAmount = amt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 58,
                  height: 48,
                  decoration: BoxDecoration(
                    color: sel ? AppColors.accent : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text('\$$amt',
                        style: GoogleFonts.lato(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: sel
                                ? Colors.white
                                : AppColors.textSecondary)),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Tip of \$$_selectedAmount sent! ✨'),
                  behavior: SnackBarBehavior.floating,
                ));
              },
              child: Text('Send \$$_selectedAmount tip',
                  style: GoogleFonts.lato(
                      fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
