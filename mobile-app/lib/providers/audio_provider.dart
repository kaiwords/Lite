import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../models/post.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Real audio playback, backed by `just_audio`.
//
// A single shared `AudioPlayer` (below) is the one source of truth for
// playback across the whole app — the feed's Audio tab, the featured player,
// the mini-player, and the audiobook volume player all read/write through
// this same [AudioPlayerController]. Position, duration and playback state
// are driven by the player's own streams, not simulated.
//
// This app has no backend, so there are no real per-post audio files. Instead
// [demoAudioUrlFor] deterministically maps a track id to one of a small
// rotating set of freely-licensed SoundHelix demo tracks (the same URLs
// commonly used for audio-player development/testing). A given id always
// resolves to the same URL, so playback is stable across rebuilds.
// ─────────────────────────────────────────────────────────────────────────────

/// Placeholder demo audio — freely-licensed SoundHelix tracks, not real
/// content. Reused (rotated) across mock posts/volumes since this app has no
/// backend to host real per-post audio files.
const _demoAudioUrls = [
  'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
  'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
  'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
  'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
  'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
];

/// Deterministically maps a track id to one of [_demoAudioUrls], so a given
/// id always plays the same placeholder track.
String demoAudioUrlFor(String id) =>
    _demoAudioUrls[id.hashCode.abs() % _demoAudioUrls.length];

/// A single playable item — a feed audio post or one audiobook volume.
class AudioTrack {
  final String id;
  final String title;
  final String subtitle; // author name, or "Volume N"
  final String coverInitial;
  final String url;

  const AudioTrack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.coverInitial,
    required this.url,
  });

  /// Builds a track from a feed post. Falls back to a demo URL if the post
  /// somehow has none (callers should already filter to `audioUrl != null`).
  factory AudioTrack.fromPost(Post p) => AudioTrack(
        id: p.id,
        title: p.title,
        subtitle: p.author.displayName,
        coverInitial: p.title.isEmpty ? '?' : p.title[0].toUpperCase(),
        url: p.audioUrl ?? demoAudioUrlFor(p.id),
      );
}

class AudioPlayerState {
  final List<AudioTrack> queue;
  final int index; // current track in [queue]; -1 when nothing is loaded
  final bool isPlaying;
  final bool isLoading; // source is being fetched/decoded; duration unknown
  final Duration position;
  final Duration duration;
  final String? error; // set when the current track failed to load/play

  const AudioPlayerState({
    required this.queue,
    required this.index,
    required this.isPlaying,
    required this.isLoading,
    required this.position,
    required this.duration,
    this.error,
  });

  const AudioPlayerState.idle()
      : queue = const [],
        index = -1,
        isPlaying = false,
        isLoading = false,
        position = Duration.zero,
        duration = Duration.zero,
        error = null;

  AudioTrack? get current =>
      (index >= 0 && index < queue.length) ? queue[index] : null;
  String? get trackId => current?.id;
  bool get hasNext => index >= 0 && index < queue.length - 1;
  bool get hasPrevious => index > 0;
  double get progress => duration.inMilliseconds <= 0
      ? 0.0
      : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

  static const _unset = Object();

  AudioPlayerState copyWith({
    List<AudioTrack>? queue,
    int? index,
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    Object? error = _unset,
  }) =>
      AudioPlayerState(
        queue: queue ?? this.queue,
        index: index ?? this.index,
        isPlaying: isPlaying ?? this.isPlaying,
        isLoading: isLoading ?? this.isLoading,
        position: position ?? this.position,
        duration: duration ?? this.duration,
        error: identical(error, _unset) ? this.error : error as String?,
      );
}

class AudioPlayerController extends StateNotifier<AudioPlayerState> {
  AudioPlayerController() : super(const AudioPlayerState.idle()) {
    _positionSub = _player.positionStream.listen((pos) {
      // Ignore stray position ticks once we've moved past the track (avoids a
      // brief backwards flicker right as a new track starts loading).
      if (!mounted) return;
      state = state.copyWith(position: pos);
    });
    _durationSub = _player.durationStream.listen((d) {
      if (!mounted || d == null) return;
      state = state.copyWith(duration: d);
    });
    _playerStateSub = _player.playerStateStream.listen(_onPlayerStateChanged);
    _errorSub = _player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace st) {
        if (!mounted) return;
        state = state.copyWith(
          isLoading: false,
          isPlaying: false,
          error: 'Couldn\'t play this track. Check your connection.',
        );
      },
    );
  }

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<void>? _errorSub;

  void _onPlayerStateChanged(PlayerState ps) {
    if (!mounted) return;
    switch (ps.processingState) {
      case ProcessingState.idle:
        break;
      case ProcessingState.loading:
      case ProcessingState.buffering:
        state = state.copyWith(isLoading: true);
        break;
      case ProcessingState.ready:
        state = state.copyWith(isLoading: false, isPlaying: ps.playing);
        break;
      case ProcessingState.completed:
        _onTrackCompleted();
        break;
    }
  }

  void _onTrackCompleted() {
    if (state.hasNext) {
      playQueue(state.queue, startIndex: state.index + 1);
    } else {
      state = state.copyWith(isPlaying: false, position: state.duration);
    }
  }

  /// Play a single track (replaces the queue).
  void playSingle(AudioTrack track) => playQueue([track], startIndex: 0);

  /// Play a queue of tracks starting at [startIndex].
  Future<void> playQueue(List<AudioTrack> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;
    final i = startIndex.clamp(0, tracks.length - 1);
    final track = tracks[i];
    state = AudioPlayerState(
      queue: tracks,
      index: i,
      isPlaying: false,
      isLoading: true,
      position: Duration.zero,
      duration: Duration.zero,
      error: null,
    );
    try {
      await _player.setUrl(track.url);
      if (!mounted) return;
      // The queue/index may have changed while awaiting (e.g. rapid skips).
      if (state.trackId != track.id) return;
      await _player.play();
    } catch (_) {
      if (!mounted || state.trackId != track.id) return;
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        error: 'Couldn\'t load this track. Check your connection.',
      );
    }
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
    _player.pause();
  }

  void resume() {
    if (state.current == null) return;
    if (state.error != null) {
      // Retry loading the current track from scratch.
      playQueue(state.queue, startIndex: state.index);
      return;
    }
    if (_player.processingState == ProcessingState.completed) {
      _player.seek(Duration.zero);
    }
    _player.play();
  }

  void seekFraction(double fraction) {
    if (state.current == null || state.duration <= Duration.zero) return;
    final f = fraction.clamp(0.0, 1.0);
    _player.seek(
      Duration(milliseconds: (state.duration.inMilliseconds * f).round()),
    );
  }

  void next() {
    if (state.hasNext) playQueue(state.queue, startIndex: state.index + 1);
  }

  void previous() {
    // Restart the current track if we're >3s in or there's no earlier track.
    if (state.position.inSeconds > 3 || !state.hasPrevious) {
      _player.seek(Duration.zero);
    } else {
      playQueue(state.queue, startIndex: state.index - 1);
    }
  }

  void stop() {
    _player.stop();
    state = const AudioPlayerState.idle();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _errorSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}

final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerController, AudioPlayerState>(
        (ref) => AudioPlayerController());

/// Formats a duration as `M:SS`.
String formatAudioTime(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
