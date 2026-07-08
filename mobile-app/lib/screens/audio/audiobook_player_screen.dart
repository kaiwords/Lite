import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/marketplace.dart';
import '../../providers/audio_provider.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Audiobook player — plays an owned/authored audio listing's volumes as a queue
// using the shared AudioPlayerController. Volumes auto-advance; tap any volume
// to jump to it.
// ─────────────────────────────────────────────────────────────────────────────

class AudiobookPlayerScreen extends ConsumerStatefulWidget {
  final MarketplaceListing listing;
  const AudiobookPlayerScreen({super.key, required this.listing});

  @override
  ConsumerState<AudiobookPlayerScreen> createState() =>
      _AudiobookPlayerScreenState();
}

class _AudiobookPlayerScreenState extends ConsumerState<AudiobookPlayerScreen> {
  late final List<AudioTrack> _queue;

  @override
  void initState() {
    super.initState();
    final title = widget.listing.title;
    final initial = title.isEmpty ? '?' : title[0].toUpperCase();
    _queue = [
      for (var i = 0; i < widget.listing.audioVolumes.length; i++)
        AudioTrack(
          id: '${widget.listing.id}#vol$i',
          title: title,
          subtitle: 'Volume ${i + 1}',
          coverInitial: initial,
        ),
    ];
    // Start playback after the first frame so we don't mutate provider state
    // during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _queue.isNotEmpty) {
        ref.read(audioPlayerProvider.notifier).playQueue(_queue);
      }
    });
  }

  @override
  void dispose() {
    // Stop the shared player when leaving so it doesn't keep "playing" with no
    // visible controls.
    ref.read(audioPlayerProvider.notifier).stop();
    super.dispose();
  }

  bool _isMine(AudioPlayerState p) =>
      p.current != null && p.current!.id.startsWith('${widget.listing.id}#vol');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final titleColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    final player = ref.watch(audioPlayerProvider);
    final mine = _isMine(player);
    final activeIndex = mine ? player.index : -1;
    final isPlaying = mine && player.isPlaying;
    final progress = mine ? player.progress : 0.0;
    final position = mine ? player.position : Duration.zero;
    final duration = mine
        ? player.duration
        : (_queue.isEmpty ? Duration.zero : audioDurationFor(_queue.first.id));
    final volumeLabel = activeIndex >= 0
        ? 'Volume ${activeIndex + 1} of ${_queue.length}'
        : '${_queue.length} volume${_queue.length == 1 ? '' : 's'}';

    final notifier = ref.read(audioPlayerProvider.notifier);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Now Listening',
            style: Theme.of(context).appBarTheme.titleTextStyle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          // ── Cover art ──────────────────────────────────────────────────
          Center(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2A1A0A), AppColors.darkSurfaceVariant]
                      : [AppColors.accentSoft, AppColors.surfaceVariant],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkDivider : AppColors.divider,
                ),
              ),
              child: Center(
                child: Icon(Icons.headphones_rounded,
                    size: 64, color: AppColors.accent),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Title / author / volume ────────────────────────────────────
          Text(
            widget.listing.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
                fontSize: 22, fontWeight: FontWeight.w700, color: titleColor),
          ),
          const SizedBox(height: 4),
          Text(
            widget.listing.authorName,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: secondaryColor),
          ),
          const SizedBox(height: 2),
          Text(
            volumeLabel,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: 12, color: mutedColor),
          ),
          const SizedBox(height: 20),

          // ── Scrubber ───────────────────────────────────────────────────
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
              onChanged: (v) => notifier.seekFraction(v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatAudioTime(position),
                    style: GoogleFonts.lato(fontSize: 11, color: mutedColor)),
                Text(formatAudioTime(duration),
                    style: GoogleFonts.lato(fontSize: 11, color: mutedColor)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Transport controls ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                iconSize: 34,
                color: secondaryColor,
                onPressed: notifier.previous,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (mine) {
                    notifier.toggle();
                  } else {
                    notifier.playQueue(_queue);
                  }
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                      color: AppColors.accent, shape: BoxShape.circle),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                iconSize: 34,
                color: secondaryColor,
                onPressed: notifier.next,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Volume list ────────────────────────────────────────────────
          Text('Volumes',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          ..._queue.asMap().entries.map((e) {
            final i = e.key;
            final track = e.value;
            final active = i == activeIndex;
            return _VolumeRow(
              label: track.subtitle,
              fileName: widget.listing.audioVolumes[i],
              duration: formatAudioTime(audioDurationFor(track.id)),
              isActive: active,
              isPlaying: active && isPlaying,
              isDark: isDark,
              onTap: () => notifier.playQueue(_queue, startIndex: i),
            );
          }),
        ],
      ),
    );
  }
}

class _VolumeRow extends StatelessWidget {
  final String label;
  final String fileName;
  final String duration;
  final bool isActive;
  final bool isPlaying;
  final bool isDark;
  final VoidCallback onTap;

  const _VolumeRow({
    required this.label,
    required this.fileName,
    required this.duration,
    required this.isActive,
    required this.isPlaying,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.cardBorder;
    final titleColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.accent : borderColor,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
              color: isActive ? AppColors.accent : mutedColor,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isActive ? AppColors.accent : titleColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(fontSize: 11, color: mutedColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(duration,
                style: GoogleFonts.lato(fontSize: 12, color: mutedColor)),
          ],
        ),
      ),
    );
  }
}
