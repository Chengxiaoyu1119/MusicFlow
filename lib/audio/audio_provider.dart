import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/music.dart';
import 'audio_handler.dart';

/// Global instance of the audio handler
MusicAudioHandler? _audioHandler;

/// Provider for the audio handler
final audioHandlerProvider = Provider<MusicAudioHandler>((ref) {
  _audioHandler ??= MusicAudioHandler();
  return _audioHandler!;
});

/// Provider for current music
final currentMusicProvider = StreamProvider<Music?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.currentMusicStream;
});

/// Provider for playing state
final isPlayingProvider = StreamProvider<bool>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.playingStream;
});

/// Provider for player position
final playerPositionProvider = StreamProvider<Duration>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.positionStream;
});

/// Provider for player duration
final playerDurationProvider = StreamProvider<Duration?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.durationStream;
});

/// Provider for shuffle mode
final shuffleModeProvider = StreamProvider<bool>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.shuffleModeStream;
});

/// Provider for repeat mode (0=none, 1=all, 2=one)
final repeatModeProvider = StreamProvider<int>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.repeatModeStream;
});

/// Provider for queue
final queueProvider = Provider<List<Music>>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.getMusicList();
});

/// Provider for current index
final currentIndexProvider = Provider<int?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.currentIndex;
});
