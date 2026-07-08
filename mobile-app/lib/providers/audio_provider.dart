import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post.dart';

// ─────────────────────────────────────────────────────────────────────────────
// A simulated-but-functional audio player.
//
// There are no real audio files in this mock app, so instead of decoding media
// this engine runs a real clock: a periodic timer advances [position] in real
// time toward a deterministic per-track [duration]. Play / pause / seek / skip
// and auto-advance through a queue all behave like a real player, which is what
// the UI (feed audio + audiobook volumes) binds to.
// ─────────────────────────────────────────────────────────────────────────────

/// A single playable item — a feed audio post or one audiobook volume.
class AudioTrack {
  final String id;
  final String title;
  final String subtitle; // author name, or "Volume N"
  final String coverInitial;

  const AudioTrack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.coverInitial,
  });

  factory AudioTrack.fromPost(Post p) => AudioTrack(
        id: p.id,
        title: p.title,
        subtitle: p.author.displayName,
        coverInitial: p.title.isEmpty ? '?' : p.title[0].toUpperCase(),
      );
}

class AudioPlayerState {
  final List<AudioTrack> queue;
  final int index; // current track in [queue]; -1 when nothing is loaded
  final bool isPlaying;
  final Duration position;
  final Duration duration;

  const AudioPlayerState({
    required this.queue,
    required this.index,
    required this.isPlaying,
    required this.position,
    required this.duration,
  });

  const AudioPlayerState.idle()
      : queue = const [],
        index = -1,
        isPlaying = false,
        position = Duration.zero,
        duration = Duration.zero;

  AudioTrack? get current =>
      (index >= 0 && index < queue.length) ? queue[index] : null;
  String? get trackId => current?.id;
  bool get hasNext => index >= 0 && index < queue.length - 1;
  bool get hasPrevious => index > 0;
  double get progress => duration.inMilliseconds <= 0
      ? 0.0
      : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

  AudioPlayerState copyWith({
    List<AudioTrack>? queue,
    int? index,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
  }) =>
      AudioPlayerState(
        queue: queue ?? this.queue,
        index: index ?? this.index,
        isPlaying: isPlaying ?? this.isPlaying,
        position: position ?? this.position,
        duration: duration ?? this.duration,
      );
}

class AudioPlayerController extends StateNotifier<AudioPlayerState> {
  AudioPlayerController() : super(const AudioPlayerState.idle());

  static const _tick = Duration(milliseconds: 250);
  Timer? _timer;

  /// Play a single track (replaces the queue).
  void playSingle(AudioTrack track) => playQueue([track], startIndex: 0);

  /// Play a queue of tracks starting at [startIndex].
  void playQueue(List<AudioTrack> tracks, {int startIndex = 0}) {
    if (tracks.isEmpty) return;
    final i = startIndex.clamp(0, tracks.length - 1);
    state = AudioPlayerState(
      queue: tracks,
      index: i,
      isPlaying: true,
      position: Duration.zero,
      duration: audioDurationFor(tracks[i].id),
    );
    _run();
  }

  void toggle() {
    if (state.current == null) return;
    if (state.isPlaying) {
      pause();
    } else {
      resume();
    }
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isPlaying: false);
  }

  void resume() {
    if (state.current == null) return;
    // If the track had finished, restart it from the beginning.
    final pos =
        state.position >= state.duration ? Duration.zero : state.position;
    state = state.copyWith(isPlaying: true, position: pos);
    _run();
  }

  void seekFraction(double fraction) {
    if (state.current == null) return;
    final f = fraction.clamp(0.0, 1.0);
    state = state.copyWith(
      position:
          Duration(milliseconds: (state.duration.inMilliseconds * f).round()),
    );
  }

  void next() {
    if (state.hasNext) playQueue(state.queue, startIndex: state.index + 1);
  }

  void previous() {
    // Restart the current track if we're >3s in or there's no earlier track.
    if (state.position.inSeconds > 3 || !state.hasPrevious) {
      state = state.copyWith(position: Duration.zero);
      if (state.isPlaying) _run();
    } else {
      playQueue(state.queue, startIndex: state.index - 1);
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    state = const AudioPlayerState.idle();
  }

  void _run() {
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) {
      if (!state.isPlaying) return;
      final next = state.position + _tick;
      if (next >= state.duration) {
        if (state.hasNext) {
          playQueue(state.queue, startIndex: state.index + 1);
        } else {
          _timer?.cancel();
          _timer = null;
          state = state.copyWith(position: state.duration, isPlaying: false);
        }
      } else {
        state = state.copyWith(position: next);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerController, AudioPlayerState>(
        (ref) => AudioPlayerController());

/// Deterministic, plausible track length (2:30–6:29) derived from the track id
/// so a given track always reports the same duration across rebuilds.
Duration audioDurationFor(String id) =>
    Duration(seconds: 150 + (id.hashCode.abs() % 240));

/// Formats a duration as `M:SS`.
String formatAudioTime(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
