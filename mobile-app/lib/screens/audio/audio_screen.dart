import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/post.dart';
import '../../providers/audio_provider.dart';
import '../../providers/feed_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/comments_sheet.dart';
import '../../widgets/share_sheet.dart';

const _kAudioPageSize = 6;

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AudioScreen extends ConsumerStatefulWidget {
  final String? initialPostId;
  const AudioScreen({super.key, this.initialPostId});

  @override
  ConsumerState<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends ConsumerState<AudioScreen> {
  final _scrollController = ScrollController();
  int _visibleCount = _kAudioPageSize;
  String? _featuredId; // null = use first audio post

  @override
  void initState() {
    super.initState();
    _featuredId = widget.initialPostId;
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  void _loadMore() {
    final total = _filtered(
      ref.read(postsNotifierProvider),
      ref.read(audioCategoryProvider),
    ).length;
    if (_visibleCount < total) {
      setState(
          () => _visibleCount = (_visibleCount + _kAudioPageSize).clamp(0, total));
    }
  }

  // Promote a track to the featured player and start playing the whole list
  // as a queue, beginning at the chosen post (so skip ⏮/⏭ walks the list).
  void _selectFeatured(Post post, List<Post> audioPosts) {
    setState(() => _featuredId = post.id);
    _playFrom(post, audioPosts);
    // Scroll back to top so the featured player is visible.
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _playFrom(Post post, List<Post> audioPosts) {
    final idx = audioPosts.indexWhere((p) => p.id == post.id);
    ref.read(audioPlayerProvider.notifier).playQueue(
          audioPosts.map(AudioTrack.fromPost).toList(),
          startIndex: idx < 0 ? 0 : idx,
        );
  }

  List<Post> _filtered(List<Post> all, FeedCategory cat) {
    return all.where((p) {
      if (p.audioUrl == null) return false;
      if (cat == FeedCategory.all) return true;
      final cc = ContentCategory.values.firstWhere(
        (c) => c.name == cat.name,
        orElse: () => ContentCategory.poem,
      );
      return p.category == cc;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final category = ref.watch(audioCategoryProvider);
    final allPosts = ref.watch(postsNotifierProvider);
    final player = ref.watch(audioPlayerProvider);
    final playingId = player.trackId;

    ref.listen(audioCategoryProvider, (prev, next) {
      if (prev != next) {
        setState(() {
          _visibleCount = _kAudioPageSize;
          _featuredId = null; // reset to first post of new category
        });
        ref.read(audioPlayerProvider.notifier).stop();
      }
    });

    final audioPosts = _filtered(allPosts, category);
    // The featured player follows the actively-playing track while it belongs
    // to this list (so auto-advance keeps the right card on top); otherwise it
    // falls back to the last user pick, then the first post.
    final activeId = (playingId != null && audioPosts.any((p) => p.id == playingId))
        ? playingId
        : _featuredId;
    final featured = audioPosts.isEmpty
        ? null
        : audioPosts.firstWhere(
            (p) => p.id == activeId,
            orElse: () => audioPosts.first,
          );
    final rest = featured == null
        ? <Post>[]
        : audioPosts.where((p) => p.id != featured.id).toList();
    final visibleRest = rest.take(_visibleCount).toList();
    final hasMore = rest.length > _visibleCount;

    // Mini player shows currently playing track
    final playingPost = playingId == null
        ? null
        : allPosts.where((p) => p.id == playingId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text('Audio', style: Theme.of(context).appBarTheme.titleTextStyle),
        actions: [
          IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => context.push('/search')),
        ],
      ),
      bottomNavigationBar: const LiteratureBottomNavBar(currentIndex: 1),
      body: Column(
        children: [
          _AudioCategoryBar(isDark: isDark),

          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: playingPost != null
                ? _MiniPlayer(post: playingPost, isDark: isDark)
                : const SizedBox.shrink(),
          ),

          Expanded(
            child: audioPosts.isEmpty
                ? _EmptyState(
                    isDark: isDark,
                    filtered: category != FeedCategory.all,
                    label: category.label,
                  )
                : ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      _FeaturedPlayer(
                        post: featured!,
                        isDark: isDark,
                        onPlay: () => _playFrom(featured, audioPosts),
                      ),

                      if (rest.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                          child: Text('More Audio',
                              style: Theme.of(context).textTheme.headlineSmall),
                        ),
                        ...visibleRest.map((p) => _AudioListItem(
                              post: p,
                              isDark: isDark,
                              onSelect: () => _selectFeatured(p, audioPosts),
                            )),
                      ],

                      if (hasMore)
                        _LoadMoreButton(isDark: isDark, onTap: _loadMore)
                      else
                        const SizedBox(height: 32),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Audio filter bar — Following/Narrators + category chips
// ─────────────────────────────────────────────────────────────────────────────

class _AudioCategoryBar extends ConsumerWidget {
  final bool isDark;
  const _AudioCategoryBar({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(audioFilterProvider);
    final selectedCategory = ref.watch(audioCategoryProvider);
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final activeColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final inactiveColor =
        isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final activeBg =
        isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;

    return Container(
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Following / Narrators ──────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              _AudioFilterTab(
                label: 'Following',
                isSelected: selectedFilter == AudioFilter.following,
                activeColor: activeColor,
                activeBg: activeBg,
                inactiveColor: inactiveColor,
                onTap: () => ref
                    .read(audioFilterProvider.notifier)
                    .state = AudioFilter.following,
              ),
              const SizedBox(width: 8),
              _AudioFilterTab(
                label: 'Narrators',
                isSelected: selectedFilter == AudioFilter.narrators,
                activeColor: activeColor,
                activeBg: activeBg,
                inactiveColor: inactiveColor,
                onTap: () => ref
                    .read(audioFilterProvider.notifier)
                    .state = AudioFilter.narrators,
              ),
            ]),
          ),

          // ── Category chips ─────────────────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: FeedCategory.values.map((cat) {
                final isSel = cat == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 7),
                  child: GestureDetector(
                    onTap: () => ref
                        .read(audioCategoryProvider.notifier)
                        .state = cat,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSel
                            ? (isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary)
                            : (isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.surfaceVariant),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cat.label,
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight:
                              isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel
                              ? (isDark
                                  ? AppColors.darkBackground
                                  : Colors.white)
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Divider(height: 1, color: dividerColor),
        ],
      ),
    );
  }
}

class _AudioFilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color activeBg;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _AudioFilterTab({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.activeBg,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? activeColor : inactiveColor,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Persistent mini player — shown at top when a track is playing
// ─────────────────────────────────────────────────────────────────────────────

class _MiniPlayer extends ConsumerWidget {
  final Post post;
  final bool isDark;
  const _MiniPlayer({required this.post, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(audioPlayerProvider);
    final progress = player.progress;
    final isPlaying = player.isPlaying;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Container(
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Cover initial
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      post.title[0].toUpperCase(),
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Title + author
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: titleColor),
                      ),
                      Text(
                        post.author.displayName,
                        style: GoogleFonts.lato(fontSize: 11, color: mutedColor),
                      ),
                    ],
                  ),
                ),
                // Equalizer animation
                _AnimatedBars(
                  isPlaying: isPlaying,
                  color: AppColors.accent,
                  barWidth: 2.5,
                  maxHeight: 14,
                  count: 4,
                ),
                const SizedBox(width: 10),
                // Play/pause
                GestureDetector(
                  onTap: () => ref.read(audioPlayerProvider.notifier).toggle(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                        color: AppColors.accent, shape: BoxShape.circle),
                    child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20),
                  ),
                ),
              ],
            ),
          ),
          // Thin progress bar
          LinearProgressIndicator(
            value: progress,
            minHeight: 2,
            backgroundColor: borderColor,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Featured full-height player
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturedPlayer extends ConsumerStatefulWidget {
  final Post post;
  final bool isDark;
  final VoidCallback onPlay; // start playing this post (as part of the queue)
  const _FeaturedPlayer(
      {required this.post, required this.isDark, required this.onPlay});

  @override
  ConsumerState<_FeaturedPlayer> createState() => _FeaturedPlayerState();
}

class _FeaturedPlayerState extends ConsumerState<_FeaturedPlayer> {

  void _togglePlay() {
    final player = ref.read(audioPlayerProvider);
    if (player.trackId == widget.post.id) {
      ref.read(audioPlayerProvider.notifier).toggle();
    } else {
      widget.onPlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(audioPlayerProvider);
    final isCurrent = player.trackId == widget.post.id;
    final isPlaying = isCurrent && player.isPlaying;
    final progress = isCurrent ? player.progress : 0.0;
    final position = isCurrent ? player.position : Duration.zero;
    final duration =
        isCurrent ? player.duration : audioDurationFor(widget.post.id);

    final livePost = ref
        .watch(postsNotifierProvider)
        .firstWhere((p) => p.id == widget.post.id, orElse: () => widget.post);

    final screenH = MediaQuery.of(context).size.height;
    final cardH = screenH * 0.58;

    final isDark = widget.isDark;
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Container(
      height: cardH,
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A1A0A), AppColors.darkBackground]
              : [AppColors.accentSoft, AppColors.surfaceVariant],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Category + Now Playing pill ───────────────────────────
            Row(children: [
              _Pill(
                label: '${widget.post.category.emoji} ${widget.post.category.label}',
                isDark: isDark,
              ),
              if (isPlaying) ...[
                const SizedBox(width: 8),
                _Pill(label: '▶ Now Playing', isDark: isDark, accent: true),
              ],
            ]),

            const Spacer(),

            // ── Waveform visual ───────────────────────────────────────
            _AnimatedWaveform(isPlaying: isPlaying, progress: progress),

            const SizedBox(height: 16),

            // ── Title + author ────────────────────────────────────────
            Text(
              widget.post.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: titleColor),
            ),
            const SizedBox(height: 3),
            GestureDetector(
              onTap: () => context.push('/user/${widget.post.author.id}'),
              child: Row(children: [
                Text(
                  widget.post.author.displayName,
                  style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: secondaryColor),
                ),
                if (widget.post.author.isVerified) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.verified_rounded, size: 12, color: AppColors.accent),
                ],
                const SizedBox(width: 6),
                Text(
                  '· ${timeago.format(widget.post.createdAt)}',
                  style: GoogleFonts.lato(fontSize: 11, color: mutedColor),
                ),
              ]),
            ),

            const SizedBox(height: 16),

            // ── Progress slider ───────────────────────────────────────
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                activeTrackColor: AppColors.accent,
                inactiveTrackColor:
                    isDark ? AppColors.darkDivider : AppColors.divider,
                thumbColor: AppColors.accent,
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0),
                onChanged: isCurrent
                    ? (v) =>
                        ref.read(audioPlayerProvider.notifier).seekFraction(v)
                    : (v) {
                        widget.onPlay();
                        ref.read(audioPlayerProvider.notifier).seekFraction(v);
                      },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formatAudioTime(position),
                        style: GoogleFonts.lato(fontSize: 10, color: mutedColor)),
                    Text(formatAudioTime(duration),
                        style: GoogleFonts.lato(fontSize: 10, color: mutedColor)),
                  ]),
            ),

            const SizedBox(height: 4),

            // ── Playback controls ─────────────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                iconSize: 26,
                color: secondaryColor,
                onPressed: () =>
                    ref.read(audioPlayerProvider.notifier).previous(),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                      color: AppColors.accent, shape: BoxShape.circle),
                  child: Icon(
                    isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                iconSize: 26,
                color: secondaryColor,
                onPressed: () => ref.read(audioPlayerProvider.notifier).next(),
              ),
            ]),

            const SizedBox(height: 12),

            // ── Engagement row ────────────────────────────────────────
            _EngagementRow(
              post: livePost,
              isDark: isDark,
              enabled: isPlaying,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Engagement row — grayed & disabled when not playing
// ─────────────────────────────────────────────────────────────────────────────

class _EngagementRow extends ConsumerWidget {
  final Post post;
  final bool isDark;
  final bool enabled;
  const _EngagementRow(
      {required this.post, required this.isDark, required this.enabled});

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final dimmed = muted.withValues(alpha: 0.35);

    Color likeColor() {
      if (!enabled) return dimmed;
      return post.isLiked ? AppColors.like : muted;
    }

    Color bookmarkColor() {
      if (!enabled) return dimmed;
      return post.isFavourited ? AppColors.bookmark : muted;
    }

    return Row(children: [
      _EngBtn(
        icon: post.isLiked
            ? Icons.favorite_rounded
            : Icons.favorite_border_rounded,
        label: _fmt(post.likesCount),
        color: likeColor(),
        enabled: enabled,
        onTap: () =>
            ref.read(postsNotifierProvider.notifier).toggleLike(post.id),
      ),
      _EngBtn(
        icon: Icons.chat_bubble_outline_rounded,
        label: _fmt(post.commentsCount),
        color: enabled ? muted : dimmed,
        enabled: enabled,
        onTap: () => showCommentsSheet(context, post.id),
      ),
      _EngBtn(
        icon: Icons.share_outlined,
        label: _fmt(post.sharesCount),
        color: enabled ? muted : dimmed,
        enabled: enabled,
        onTap: () => sharePost(context, ref, post),
      ),
      const Spacer(),
      _EngBtn(
        icon: post.isFavourited
            ? Icons.bookmark_rounded
            : Icons.bookmark_border_rounded,
        label: '',
        color: bookmarkColor(),
        enabled: enabled,
        onTap: () =>
            ref.read(postsNotifierProvider.notifier).toggleFavourite(post.id),
      ),
      const SizedBox(width: 4),
      // Support — only tappable when playing
      GestureDetector(
        onTap: enabled ? () => _showTip(context, post.author.displayName) : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1.0 : 0.3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkAccent : AppColors.accent,
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
      ),
    ]);
  }

  void _showTip(BuildContext context, String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _TipSheet(authorName: name),
    );
  }
}

class _EngBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  const _EngBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20, color: color),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.lato(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w500)),
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Audio list item — shown after scrolling past featured player
// ─────────────────────────────────────────────────────────────────────────────

class _AudioListItem extends ConsumerWidget {
  final Post post;
  final bool isDark;
  final VoidCallback onSelect;
  const _AudioListItem({
    required this.post,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(audioPlayerProvider);
    final isPlaying = player.trackId == post.id && player.isPlaying;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.cardBorder;
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    final livePost = ref
        .watch(postsNotifierProvider)
        .firstWhere((p) => p.id == post.id, orElse: () => post);

    return GestureDetector(
      onTap: onSelect,
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPlaying ? AppColors.accent : borderColor,
          width: isPlaying ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Thumbnail
            GestureDetector(
              onTap: onSelect,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF2A1A0A), AppColors.darkSurfaceVariant]
                            : [AppColors.accentSoft, AppColors.surfaceVariant],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        post.title[0].toUpperCase(),
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent),
                      ),
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${post.category.emoji} ${post.category.label}',
                        style: GoogleFonts.lato(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: titleColor),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () => context.push('/user/${post.author.id}'),
                    child: Text(
                      post.author.displayName,
                      style: GoogleFonts.lato(
                          fontSize: 12,
                          color: secondaryColor,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (isPlaying) ...[
                    _AnimatedBars(
                      isPlaying: true,
                      color: AppColors.accent,
                      barWidth: 3,
                      maxHeight: 16,
                      count: 5,
                    ),
                    const SizedBox(height: 6),
                    _EngagementRow(
                        post: livePost, isDark: isDark, enabled: true),
                  ] else
                    Text(
                      '▶ Tap to play',
                      style: GoogleFonts.lato(fontSize: 11, color: mutedColor),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final bool isDark;
  final bool accent;
  const _Pill({required this.label, required this.isDark, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent
            ? AppColors.accent.withValues(alpha: 0.2)
            : AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: GoogleFonts.lato(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.accent)),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _LoadMoreButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                  color: isDark ? AppColors.darkDivider : AppColors.divider),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Load more',
                style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary)),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final bool filtered;
  final String label;
  const _EmptyState(
      {required this.isDark, required this.filtered, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.headphones_rounded,
            size: 56,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
        const SizedBox(height: 12),
        Text(
          filtered ? 'No audio posts in "$label"' : 'No audio posts yet',
          style: GoogleFonts.lato(
              fontSize: 14,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
        ),
      ]),
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
                            color: sel ? Colors.white : AppColors.textSecondary)),
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
                  style:
                      GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated equalizer bars — small, used in list item + mini player
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedBars extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  final double barWidth;
  final double maxHeight;
  final int count;

  const _AnimatedBars({
    required this.isPlaying,
    required this.color,
    this.barWidth = 3,
    this.maxHeight = 18,
    this.count = 4,
  });

  @override
  State<_AnimatedBars> createState() => _AnimatedBarsState();
}

class _AnimatedBarsState extends State<_AnimatedBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isPlaying) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(_AnimatedBars old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.isPlaying && _ctrl.isAnimating) {
      _ctrl.animateTo(0, duration: const Duration(milliseconds: 200));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(widget.count, (i) {
            final phase = i * (pi / widget.count) * 1.5;
            final t = _ctrl.value * 2 * pi + phase;
            final heightFactor = widget.isPlaying
                ? 0.25 + 0.75 * ((sin(t) + 1) / 2)
                : 0.15;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.barWidth * 0.4),
              child: Container(
                width: widget.barWidth,
                height: widget.maxHeight * heightFactor,
                decoration: BoxDecoration(
                  color: widget.isPlaying
                      ? widget.color
                      : widget.color.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(widget.barWidth),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated waveform — large, used in featured player
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedWaveform extends StatefulWidget {
  final bool isPlaying;
  final double progress;

  const _AnimatedWaveform({required this.isPlaying, required this.progress});

  @override
  State<_AnimatedWaveform> createState() => _AnimatedWaveformState();
}

class _AnimatedWaveformState extends State<_AnimatedWaveform>
    with SingleTickerProviderStateMixin {
  // Fixed shape profile — heights are normalised 0..1
  static const _shape = [
    0.30, 0.55, 0.85, 0.50, 0.70, 1.00, 0.40, 0.80, 0.60, 0.30,
    0.90, 0.50, 0.70, 0.40, 1.00, 0.60, 0.30, 0.80, 0.50, 0.70,
    0.90, 0.40, 0.60, 1.00, 0.30, 0.70, 0.50, 0.80, 0.40, 0.60,
    0.90, 0.30, 0.70, 1.00, 0.50, 0.80, 0.40, 0.60, 0.30, 0.90,
  ];

  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isPlaying) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(_AnimatedWaveform old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.isPlaying && _ctrl.isAnimating) {
      _ctrl.animateTo(0, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        return SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _shape.asMap().entries.map((e) {
              final idx = e.key;
              final baseH = e.value;

              // Animate height when playing
              double animH = baseH;
              if (widget.isPlaying) {
                final phase = idx * (pi / _shape.length) * 3;
                final wave = (sin(_ctrl.value * 2 * pi + phase) + 1) / 2;
                // blend base shape with wave
                animH = baseH * 0.5 + wave * 0.5;
              }

              final barProgress = idx / _shape.length;
              final isPast = barProgress < widget.progress && widget.isPlaying;

              return Container(
                width: 4,
                height: (56 * animH).clamp(4.0, 56.0),
                decoration: BoxDecoration(
                  color: isPast
                      ? AppColors.accent
                      : AppColors.accent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
