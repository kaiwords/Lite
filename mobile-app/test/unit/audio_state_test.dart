import 'package:flutter_test/flutter_test.dart';
import 'package:literature/models/post.dart';
import 'package:literature/models/user.dart';
import 'package:literature/providers/audio_provider.dart';

const _t1 = AudioTrack(
    id: 'a', title: 'A', subtitle: 's', coverInitial: 'A', url: 'u1');
const _t2 = AudioTrack(
    id: 'b', title: 'B', subtitle: 's', coverInitial: 'B', url: 'u2');
const _t3 = AudioTrack(
    id: 'c', title: 'C', subtitle: 's', coverInitial: 'C', url: 'u3');

AudioPlayerState _state({
  List<AudioTrack> queue = const [_t1, _t2, _t3],
  int index = 1,
  Duration position = Duration.zero,
  Duration duration = Duration.zero,
  String? error,
}) =>
    AudioPlayerState(
      queue: queue,
      index: index,
      isPlaying: false,
      isLoading: false,
      position: position,
      duration: duration,
      error: error,
    );

void main() {
  group('AudioPlayerState', () {
    test('idle state has no current track and zero progress', () {
      const s = AudioPlayerState.idle();
      expect(s.current, isNull);
      expect(s.trackId, isNull);
      expect(s.hasNext, isFalse);
      expect(s.hasPrevious, isFalse);
      expect(s.progress, 0.0);
    });

    test('current is null when index is out of range', () {
      expect(_state(index: 3).current, isNull);
      expect(_state(index: -1).current, isNull);
    });

    test('hasNext/hasPrevious reflect queue position', () {
      expect(_state(index: 0).hasPrevious, isFalse);
      expect(_state(index: 0).hasNext, isTrue);
      expect(_state(index: 1).hasPrevious, isTrue);
      expect(_state(index: 1).hasNext, isTrue);
      expect(_state(index: 2).hasNext, isFalse);
    });

    test('progress is 0 for zero/unknown duration (no divide-by-zero)', () {
      expect(
        _state(position: const Duration(seconds: 5)).progress,
        0.0,
      );
    });

    test('progress is clamped to 1.0 when position overshoots duration', () {
      final s = _state(
        position: const Duration(seconds: 90),
        duration: const Duration(seconds: 60),
      );
      expect(s.progress, 1.0);
    });

    test('progress computes the played fraction', () {
      final s = _state(
        position: const Duration(seconds: 30),
        duration: const Duration(seconds: 120),
      );
      expect(s.progress, 0.25);
    });

    test('copyWith keeps the existing error when the field is omitted', () {
      final s = _state(error: 'boom').copyWith(isPlaying: true);
      expect(s.error, 'boom');
    });

    test('copyWith can explicitly clear the error with null', () {
      final s = _state(error: 'boom').copyWith(error: null);
      expect(s.error, isNull);
    });
  });

  group('AudioTrack.fromPost', () {
    Post post({String title = 'Title', String? audioUrl}) => Post(
          id: 'p-x',
          author: mockUsers[0],
          title: title,
          content: 'c',
          category: ContentCategory.poem,
          createdAt: DateTime(2026, 1, 1),
          audioUrl: audioUrl,
        );

    test('uses the post title initial and author name', () {
      final t = AudioTrack.fromPost(post(audioUrl: 'https://x/a.mp3'));
      expect(t.coverInitial, 'T');
      expect(t.subtitle, mockUsers[0].displayName);
      expect(t.url, 'https://x/a.mp3');
    });

    test('empty title falls back to "?" instead of crashing', () {
      final t = AudioTrack.fromPost(post(title: '', audioUrl: 'u'));
      expect(t.coverInitial, '?');
    });

    test('missing audioUrl falls back to a deterministic demo URL', () {
      final a = AudioTrack.fromPost(post());
      final b = AudioTrack.fromPost(post());
      expect(a.url, isNotEmpty);
      expect(a.url, b.url); // deterministic per id
      expect(a.url, demoAudioUrlFor('p-x'));
    });
  });

  group('formatAudioTime', () {
    test('formats M:SS with zero-padded seconds', () {
      expect(formatAudioTime(Duration.zero), '0:00');
      expect(formatAudioTime(const Duration(seconds: 5)), '0:05');
      expect(formatAudioTime(const Duration(seconds: 65)), '1:05');
      expect(formatAudioTime(const Duration(minutes: 60)), '60:00');
    });
  });
}
