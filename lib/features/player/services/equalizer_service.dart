import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/platform_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Equalizer preset with frequency band gains.
class EqualizerPreset {
  final String name;
  final List<double> gains; // -12 to +12 dB for each band

  const EqualizerPreset({required this.name, required this.gains});
}

/// Equalizer state.
class EqualizerState {
  final List<double> gains;
  final String presetName;
  final bool isEnabled;

  const EqualizerState({
    this.gains = const [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    this.presetName = 'Flat',
    this.isEnabled = false,
  });

  EqualizerState copyWith({
    List<double>? gains,
    String? presetName,
    bool? isEnabled,
  }) {
    return EqualizerState(
      gains: gains ?? this.gains,
      presetName: presetName ?? this.presetName,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

/// Equalizer service managing gain levels and presets.
class EqualizerService extends StateNotifier<EqualizerState> {
  EqualizerService() : super(const EqualizerState());

  /// Whether the platform supports native EQ.
  static bool get isSupported => PlatformHelper.isAndroid;

  /// Available presets.
  static const List<EqualizerPreset> presets = [
    EqualizerPreset(name: 'Flat', gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
    EqualizerPreset(name: 'Rock', gains: [5, 4, 3, 1, 0, -1, 1, 3, 4, 5]),
    EqualizerPreset(name: 'Pop', gains: [-1, 2, 4, 5, 3, 1, -1, -1, 2, 3]),
    EqualizerPreset(name: 'Jazz', gains: [4, 3, 2, 1, 0, 1, 2, 3, 4, 5]),
    EqualizerPreset(name: 'Classical', gains: [4, 3, 2, 1, 0, 0, 1, 2, 3, 4]),
    EqualizerPreset(name: 'Dance', gains: [3, 4, 5, 3, 1, 0, -1, -1, 1, 2]),
    EqualizerPreset(name: 'Acoustic', gains: [3, 3, 2, 1, 0, -1, 0, 1, 2, 3]),
    EqualizerPreset(name: 'Bass Boost', gains: [6, 5, 4, 2, 0, -1, -2, -2, -1, 0]),
    EqualizerPreset(name: 'Treble Boost', gains: [-2, -1, 0, 1, 2, 3, 4, 5, 6, 6]),
  ];

  /// Apply a preset.
  void applyPreset(EqualizerPreset preset) {
    state = EqualizerState(
      gains: preset.gains,
      presetName: preset.name,
      isEnabled: true,
    );
  }

  /// Toggle EQ on/off.
  void toggle() {
    state = state.copyWith(isEnabled: !state.isEnabled);
  }

  /// Update a single band gain.
  void updateBand(int index, double gain) {
    final newGains = [...state.gains];
    if (index >= 0 && index < newGains.length) {
      newGains[index] = gain.clamp(-12.0, 12.0);
    }
    state = EqualizerState(gains: newGains, presetName: 'Custom', isEnabled: true);
  }

  /// Reset to flat.
  void reset() {
    state = const EqualizerState();
  }

  /// Load saved EQ settings.
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('eq_enabled') ?? false;
    final presetName = prefs.getString('eq_preset') ?? 'Flat';
    final gains = prefs.getString('eq_gains');

    if (gains != null) {
      final parts = gains.split(',').map((s) => double.tryParse(s) ?? 0).toList();
      if (parts.length == 10) {
        state = EqualizerState(gains: parts, presetName: presetName, isEnabled: enabled);
        return;
      }
    }
    state = const EqualizerState();
  }

  /// Save EQ settings.
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('eq_enabled', state.isEnabled);
    await prefs.setString('eq_preset', state.presetName);
    await prefs.setString('eq_gains', state.gains.join(','));
  }
}

final equalizerProvider = StateNotifierProvider<EqualizerService, EqualizerState>((ref) {
  return EqualizerService();
});
