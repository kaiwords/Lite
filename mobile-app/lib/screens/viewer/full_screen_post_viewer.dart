import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/post.dart';
import '../../providers/feed_provider.dart';
import '../../providers/follow_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/post_paginator.dart';
import '../../utils/rich_text.dart';
import '../../widgets/comments_sheet.dart';
import '../../widgets/feed_filter_row.dart';
import '../../widgets/marketplace_badge.dart';
import '../../widgets/share_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen — owns focus-mode state and the vertical post PageView
// ─────────────────────────────────────────────────────────────────────────────

class FullScreenPostViewer extends ConsumerStatefulWidget {
  final int initialIndex;
  const FullScreenPostViewer({super.key, required this.initialIndex});

  @override
  ConsumerState<FullScreenPostViewer> createState() =>
      _FullScreenPostViewerState();
}

class _FullScreenPostViewerState extends ConsumerState<FullScreenPostViewer> {
  late final PageController _vController;
  bool _focusMode = false;

  @override
  void initState() {
    super.initState();
    _vController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _vController.dispose();
    super.dispose();
  }

  void _toggleFocus() => setState(() => _focusMode = !_focusMode);

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(filteredPostsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0A07) : AppColors.background;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Collapsible top chrome (back + filter row) ────────────────
            _CollapseSection(
              visible: !_focusMode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BackRow(isDark: isDark),
                  const FeedFilterRow(),
                ],
              ),
            ),

            // ── Vertical post swipe ───────────────────────────────────────
            Expanded(
              child: posts.isEmpty
                  ? const _EmptyState()
                  : PageView.builder(
                      controller: _vController,
                      scrollDirection: Axis.vertical,
                      itemCount: posts.length,
                      itemBuilder: (_, i) => _PostFullPage(
                        post: posts[i],
                        focusMode: _focusMode,
                        onToggleFocus: _toggleFocus,
                        isDark: isDark,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Smoothly collapses/expands a child by animating its height to zero.
class _CollapseSection extends StatelessWidget {
  final bool visible;
  final Widget child;
  const _CollapseSection({required this.visible, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        heightFactor: visible ? 1.0 : 0.0,
        child: child,
      ),
    );
  }
}

// Simple back-button row — shown inside the collapsible section.
class _BackRow extends StatelessWidget {
  final bool isDark;
  const _BackRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
          onPressed: () => context.pop(),
        ),
        Text(
          'Literature',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_stories_outlined, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'No posts in this category',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// One post — horizontal page swiper + engagement footer
// ─────────────────────────────────────────────────────────────────────────────

class _PostFullPage extends ConsumerStatefulWidget {
  final Post post;
  final bool focusMode;
  final VoidCallback onToggleFocus;
  final bool isDark;

  const _PostFullPage({
    required this.post,
    required this.focusMode,
    required this.onToggleFocus,
    required this.isDark,
  });

  @override
  ConsumerState<_PostFullPage> createState() => _PostFullPageState();
}

class _PostFullPageState extends ConsumerState<_PostFullPage> {
  final PageController _hController = PageController();
  int _pageIndex = 0;
  List<String> _pages = const [];
  Size? _bodySize;
  Size? _pendingSize;
  Timer? _reflowTimer;

  bool get _isPoetic =>
      widget.post.category == ContentCategory.poem ||
      widget.post.category == ContentCategory.haiku;

  TextStyle get _bodyStyle => _isPoetic
      ? GoogleFonts.lora(fontSize: 18, fontStyle: FontStyle.italic, height: 2.0)
      : GoogleFonts.lora(fontSize: 16, height: 1.85);

  @override
  void dispose() {
    _reflowTimer?.cancel();
    _hController.dispose();
    super.dispose();
  }

  List<String> _computePages(Size bodySize) {
    final post = widget.post;
    if (post.category == ContentCategory.joke) return [post.content.trim()];
    if (_isPoetic) return paginatePost(post); // one stanza per page
    return paginateTextToFit(post.content, _bodyStyle, bodySize);
  }

  void _applyPages(Size size) {
    final newPages = _computePages(size);
    final idx = _pageIndex.clamp(0, newPages.length - 1);
    setState(() {
      _bodySize = size;
      _pages = newPages;
      _pageIndex = idx;
    });
    if (_hController.hasClients && (_hController.page ?? 0).round() != idx) {
      _hController.jumpToPage(idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final livePost = ref
        .watch(postsNotifierProvider)
        .firstWhere((p) => p.id == widget.post.id, orElse: () => widget.post);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Content area (tap to toggle focus) ──────────────────────────
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onToggleFocus,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Running header (title + category + badge)
                Padding(
                  padding: const EdgeInsets.fromLTRB(26, 16, 26, 8),
                  child: _PostHeader(
                    post: widget.post,
                    isDark: widget.isDark,
                    focusMode: widget.focusMode,
                  ),
                ),

                // Paged body — measured so overflow flows to the next page
                Expanded(
                  child: LayoutBuilder(builder: (context, constraints) {
                    final size = Size(
                      constraints.maxWidth - 52, // 26 padding each side
                      constraints.maxHeight - 36, // 20 top + 16 bottom
                    );
                    if (_bodySize != size) {
                      if (_bodySize == null) {
                        // First layout → paginate immediately.
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _applyPages(size);
                        });
                      } else {
                        // Size is animating (focus toggle / chrome collapse) →
                        // debounce so we only re-paginate once it settles.
                        _pendingSize = size;
                        _reflowTimer?.cancel();
                        _reflowTimer = Timer(
                          const Duration(milliseconds: 300),
                          () {
                            if (mounted) _applyPages(_pendingSize!);
                          },
                        );
                      }
                    }
                    if (_pages.isEmpty) return const SizedBox.shrink();
                    return PageView.builder(
                      controller: _hController,
                      scrollDirection: Axis.horizontal,
                      itemCount: _pages.length,
                      onPageChanged: (i) => setState(() => _pageIndex = i),
                      itemBuilder: (_, i) => _BodyPage(
                        text: _pages[i],
                        isPoetic: _isPoetic,
                        isDark: widget.isDark,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),

        // ── Page dots (multi-page only, hidden in focus mode) ────────────
        if (_pages.length > 1 && !widget.focusMode)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _PageDots(
              current: _pageIndex.clamp(0, _pages.length - 1),
              total: _pages.length,
              isDark: widget.isDark,
            ),
          ),

        // ── Engagement + author footer (collapses in focus mode) ─────────
        _CollapseSection(
          visible: !widget.focusMode,
          child: _PostFooter(post: livePost, isDark: widget.isDark),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Running header — category + title + marketplace badge (+ hint)
// ─────────────────────────────────────────────────────────────────────────────

class _PostHeader extends StatelessWidget {
  final Post post;
  final bool isDark;
  final bool focusMode;

  const _PostHeader({
    required this.post,
    required this.isDark,
    required this.focusMode,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!focusMode) ...[
          Text(
            'tap to focus · swipe ↕ posts · ← → pages',
            style: GoogleFonts.lato(
              fontSize: 11,
              color: mutedColor.withValues(alpha: 0.65),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          const SizedBox(height: 8),
        ],
        Text(
          post.title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: titleColor,
            height: 1.25,
          ),
        ),
        if (!focusMode && post.linkedListingId != null) ...[
          const SizedBox(height: 10),
          MarketplaceBadge(listingId: post.linkedListingId!, isDark: isDark),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body page — the text for one horizontal page
// ─────────────────────────────────────────────────────────────────────────────

class _BodyPage extends StatelessWidget {
  final String text;
  final bool isPoetic;
  final bool isDark;

  const _BodyPage({
    required this.text,
    required this.isPoetic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bodyColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final bodyStyle = isPoetic
        ? GoogleFonts.lora(
            fontSize: 18,
            fontStyle: FontStyle.italic,
            height: 2.0,
            color: bodyColor,
          )
        : GoogleFonts.lora(
            fontSize: 16,
            height: 1.85,
            color: bodyColor,
          );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 16),
      child: Text.rich(
        TextSpan(
          children: buildFormattedSpans(
            text,
            bodyStyle,
            accent: isDark ? AppColors.darkAccent : AppColors.accent,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page indicator dots
// ─────────────────────────────────────────────────────────────────────────────

class _PageDots extends StatelessWidget {
  final int current;
  final int total;
  final bool isDark;
  const _PageDots(
      {required this.current, required this.total, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final inactiveColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? activeColor
                : inactiveColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Post footer — engagement bar + author row
// ─────────────────────────────────────────────────────────────────────────────

class _PostFooter extends ConsumerWidget {
  final Post post;
  final bool isDark;
  const _PostFooter({required this.post, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final borderColor =
        isDark ? AppColors.darkDivider : AppColors.divider;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        top: 8,
        left: 6,
        right: 6,
        bottom: bottomPad + 10,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
        color: isDark ? AppColors.darkSurface : AppColors.surface,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _EngagementBar(post: post, isDark: isDark),
          const SizedBox(height: 6),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 8),
          _AuthorRow(post: post, isDark: isDark),
        ],
      ),
    );
  }
}

// ─── Engagement row ───────────────────────────────────────────────────────────

class _EngagementBar extends ConsumerWidget {
  final Post post;
  final bool isDark;
  const _EngagementBar({required this.post, required this.isDark});

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return Row(
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 5),
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

// ─── Author row ───────────────────────────────────────────────────────────────

class _AuthorRow extends ConsumerWidget {
  final Post post;
  final bool isDark;
  const _AuthorRow({required this.post, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followed = ref.watch(followNotifierProvider);
    final isFollowing = followed.contains(post.author.id);
    final nameColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.surfaceVariant,
            child: Text(
              post.author.displayName[0].toUpperCase(),
              style: GoogleFonts.playfairDisplay(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent),
            ),
          ),
          const SizedBox(width: 10),

          // Name + date
          Expanded(
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
                            color: nameColor),
                      ),
                    ),
                    if (post.author.isVerified) ...[
                      const SizedBox(width: 3),
                      Icon(Icons.verified_rounded,
                          size: 12, color: AppColors.accent),
                    ],
                  ],
                ),
                Text(
                  timeago.format(post.createdAt),
                  style: GoogleFonts.lato(fontSize: 11, color: muted),
                ),
              ],
            ),
          ),

          // Follow button — disappears permanently after tap
          if (!isFollowing) ...[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  ref.read(followNotifierProvider.notifier).follow(post.author.id),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Follow',
                  style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: nameColor),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Support / Tip
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showTip(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Support',
                style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTip(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _TipSheet(authorName: post.author.displayName),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tip sheet
// ─────────────────────────────────────────────────────────────────────────────

class _TipSheet extends StatefulWidget {
  final String authorName;
  const _TipSheet({required this.authorName});

  @override
  State<_TipSheet> createState() => _TipSheetState();
}

class _TipSheetState extends State<_TipSheet> {
  int _amount = 2;
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
                  borderRadius: BorderRadius.circular(2)),
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
              final sel = amt == _amount;
              return GestureDetector(
                onTap: () => setState(() => _amount = amt),
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
                  content: Text('Tip of \$$_amount sent! ✨'),
                  behavior: SnackBarBehavior.floating,
                ));
              },
              child: Text('Send \$$_amount tip',
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
