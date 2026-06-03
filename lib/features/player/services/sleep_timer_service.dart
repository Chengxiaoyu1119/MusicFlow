import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../audio/audio_handler.dart';
import '../../../audio/audio_provider.dart';

/// Sleep timer state.
class SleepTimerState {
  final Duration? remaining;
  final bool isActive;

  const SleepTimerState({this.remaining, this.isActive = false});

  SleepTimerState copyWith({Duration? remaining, bool? isActive}) {
    return SleepTimerState(
      remaining: remaining ?? this.remaining,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Sleep timer service that pauses playback after a set duration.
class SleepTimerService extends StateNotifier<SleepTimerState> {
  Timer? _timer;
  final MusicAudioHandler _audioHandler;

  SleepTimerService(this._audioHandler) : super(const SleepTimerState());

  static const List<int> presetMinutes = [15, 30, 45, 60];

  /// Start the timer with a given duration.
  void start(Duration duration) {
    _timer?.cancel();
    state = SleepTimerState(remaining: duration, isActive: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newRemaining = state.remaining! - const Duration(seconds: 1);

      if (newRemaining <= Duration.zero) {
        // Time's up — pause playback
        _audioHandler.pause();
        cancel();
        return;
      }

      state = state.copyWith(remaining: newRemaining);
    });
  }

  /// Cancel the sleep timer.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    state = const SleepTimerState();
  }

  /// Format remaining time as "MM:SS"
  String get formattedRemaining {
    final remaining = state.remaining;
    if (remaining == null) return '';

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Save last used preset to preferences.
  Future<void> savePreset(Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sleep_timer_minutes', duration.inMinutes);
  }

  /// Load last used preset.
  Future<int> loadPreset() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('sleep_timer_minutes') ?? 30;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final sleepTimerProvider = StateNotifierProvider<SleepTimerService, SleepTimerState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return SleepTimerService(handler);
});
