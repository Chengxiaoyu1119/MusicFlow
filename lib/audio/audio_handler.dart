import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../core/constants/platform_helper.dart';
import '../data/models/music.dart';

class MusicAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final List<Music> _queue = [];
  int? _currentIndex;
  bool _isInitialized = false;

  // Stream for current music info
  final BehaviorSubject<Music?> _currentMusic =
      BehaviorSubject<Music?>.seeded(null);
  Stream<Music?> get currentMusicStream => _currentMusic.stream;
  Music? get currentMusic => _currentMusic.value;

  // Stream for shuffle mode
  final BehaviorSubject<bool> _shuffleMode =
      BehaviorSubject<bool>.seeded(false);
  Stream<bool> get shuffleModeStream => _shuffleMode.stream;

  // Stream for repeat mode (0=none, 1=all, 2=one)
  final BehaviorSubject<int> _repeatMode =
      BehaviorSubject<int>.seeded(0);
  Stream<int> get repeatModeStream => _repeatMode.stream;

  // Queue of indices for shuffle order
  List<int> _shuffleIndices = [];
  final Random _random = Random();

  /// Get the queue of music items (use getMusicList to avoid conflict with QueueHandler's queue)
  List<Music> getMusicList() => List.unmodifiable(_queue);

  /// Get current index in queue
  int? get currentIndex => _currentIndex;

  /// Get queue length
  int get queueLength => _queue.length;

  MusicAudioHandler() {
    _setupPlayerListeners();
  }

  void _setupPlayerListeners() {
    _player.playbackEventStream.listen(_onPlaybackEvent);

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _onTrackComplete();
      }
    });

    _player.positionStream.listen((position) {
      if (_currentIndex != null && _currentIndex! < _queue.length) {
        playbackState.add(playbackState.value.copyWith(
          updatePosition: position,
          playing: _player.playing,
        ));
      }
    });

    _player.durationStream.listen((duration) {
      if (_currentIndex != null && _currentIndex! < _queue.length) {
        final music = _queue[_currentIndex!];
        mediaItem.add(MediaItem(
          id: music.id,
          album: music.album,
          title: music.title,
          artist: music.artist,
          duration: duration ?? music.duration,
          artUri: music.artworkUrl != null ? Uri.tryParse(music.artworkUrl!) : null,
        ));
      }
    });
  }

  void _onPlaybackEvent(PlaybackEvent event) {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[event.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: event.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
    ));
  }

  void _onTrackComplete() {
    if (_repeatMode.value == 2) {
      seek(Duration.zero);
      play();
    } else if (_repeatMode.value == 1) {
      skipToNext();
    } else {
      if (_currentIndex != null && _currentIndex! < _queue.length - 1) {
        skipToNext();
      } else {
        _player.pause();
        seek(Duration.zero);
      }
    }
  }

  /// Initialize the audio handler (call once)
  Future<void> init() async {
    if (_isInitialized) return;
    // audio_service does not support web — skip init on web
    if (!PlatformHelper.isWeb) {
      await AudioService.init(
        builder: () => this,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.musicplayer.channel.audio',
          androidNotificationChannelName: 'Music Playback',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
          androidNotificationIcon: 'mipmap/ic_launcher',
        ),
      );
    }
    _isInitialized = true;
  }

  /// Set the queue of music items
  Future<void> setQueue(List<Music> items, {int? startIndex}) async {
    _queue.clear();
    _queue.addAll(items);
    _shuffleIndices = List.generate(_queue.length, (i) => i);

    if (items.isEmpty) {
      _currentIndex = null;
      _currentMusic.add(null);
      return;
    }

    final index = startIndex ?? 0;
    await _playAtIndex(index);
  }

  /// Add items to the queue
  Future<void> addToQueue(List<Music> items) async {
    final wasEmpty = _queue.isEmpty;
    _queue.addAll(items);
    if (wasEmpty && _queue.isNotEmpty) {
      await _playAtIndex(0);
    }
  }

  /// Insert next (play next)
  Future<void> insertNext(Music music) async {
    if (_currentIndex == null) {
      _queue.add(music);
      await _playAtIndex(_queue.length - 1);
    } else {
      _queue.insert(_currentIndex! + 1, music);
    }
  }

  /// Remove item from queue at index
  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _queue.length) return;

    if (index == _currentIndex) {
      if (_queue.length == 1) {
        _queue.clear();
        _currentIndex = null;
        _currentMusic.add(null);
        await _player.stop();
        return;
      }
      _queue.removeAt(index);
      await _playAtIndex(index.clamp(0, _queue.length - 1));
    } else {
      _queue.removeAt(index);
      if (index < _currentIndex!) {
        _currentIndex = _currentIndex! - 1;
      }
    }
  }

  /// Clear the queue
  Future<void> clearQueue() async {
    _queue.clear();
    _currentIndex = null;
    _currentMusic.add(null);
    await _player.stop();
  }

  Future<void> _playAtIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;

    _currentIndex = index;
    final music = _queue[index];

    mediaItem.add(MediaItem(
      id: music.id,
      album: music.album,
      title: music.title,
      artist: music.artist,
      duration: music.duration,
      artUri: music.artworkUrl != null ? Uri.tryParse(music.artworkUrl!) : null,
    ));
    _currentMusic.add(music);

    final source = _getAudioSource(music);

    try {
      await _player.setAudioSource(source);
      await _player.play();
    } catch (e) {
      skipToNext();
    }
  }

  AudioSource _getAudioSource(Music music) {
    if (music.filePath != null) {
      return AudioSource.file(music.filePath!);
    }
    if (music.url != null) {
      return AudioSource.uri(Uri.parse(music.url!));
    }
    throw Exception('No audio source available');
  }

  /// Get the effective queue order (considering shuffle)
  List<int> get effectiveOrder {
    if (_shuffleMode.value) {
      return _shuffleIndices;
    }
    return List.generate(_queue.length, (i) => i);
  }

  int? _getNextIndex() {
    if (_queue.isEmpty) return null;
    if (_shuffleMode.value) return _nextShuffleIndex();

    if (_currentIndex == null) return 0;
    final next = _currentIndex! + 1;
    if (next >= _queue.length) {
      return _repeatMode.value > 0 ? 0 : null;
    }
    return next;
  }

  int _nextShuffleIndex() {
    if (_shuffleIndices.isEmpty) {
      _shuffleIndices = List.generate(_queue.length, (i) => i);
    }
    if (_currentIndex == null) return _shuffleIndices.removeAt(0);

    final currentPos = _shuffleIndices.indexOf(_currentIndex!);
    if (currentPos >= 0 && currentPos < _shuffleIndices.length - 1) {
      return _shuffleIndices[currentPos + 1];
    }
    if (_repeatMode.value > 0) {
      _shuffleIndices = List.generate(_queue.length, (i) => i)..shuffle(_random);
      return _shuffleIndices.isNotEmpty ? _shuffleIndices[0] : 0;
    }
    return 0;
  }

  // =======================
  //  AudioService Overrides
  // =======================

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    final next = _getNextIndex();
    if (next != null && next < _queue.length) {
      await _playAtIndex(next);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
      return;
    }

    if (_currentIndex == null || _currentIndex! <= 0) return;
    await _playAtIndex(_currentIndex! - 1);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode mode) async {
    _repeatMode.add(mode == AudioServiceRepeatMode.one ? 2
        : mode == AudioServiceRepeatMode.all ? 1 : 0);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode mode) async {
    final shuffle = mode == AudioServiceShuffleMode.all;
    _shuffleMode.add(shuffle);
    if (shuffle && _shuffleIndices.length < _queue.length) {
      _shuffleIndices = List.generate(_queue.length, (i) => i)..shuffle(_random);
    }
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> seekForward(bool begin) {
    if (begin) return seek(_player.position + const Duration(seconds: 10));
    return Future.value();
  }

  @override
  Future<void> seekBackward(bool begin) {
    if (begin) return seek(_player.position - const Duration(seconds: 10));
    return Future.value();
  }

  // =======================
  //  Custom Methods
  // =======================

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> toggleShuffle() async {
    final newMode = !_shuffleMode.value;
    _shuffleMode.add(newMode);
    if (newMode) {
      _shuffleIndices = List.generate(_queue.length, (i) => i)..shuffle(_random);
    }
  }

  void cycleRepeatMode() {
    final current = _repeatMode.value;
    _repeatMode.add((current + 1) % 3);
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;
  bool get isPlaying => _player.playing;
  double get volume => _player.volume;
  double get speed => _player.speed;

  Future<void> setVolume(double volume) => _player.setVolume(volume);

  void shutdown() {
    _currentMusic.close();
    _shuffleMode.close();
    _repeatMode.close();
    _player.dispose();
  }
}
