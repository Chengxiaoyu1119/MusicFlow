import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../../../audio/audio_handler.dart';
import '../../../core/constants/platform_helper.dart';

/// Registers global media key shortcuts for desktop platforms.
///
/// Supported keys:
/// - Media Play/Pause: toggle playback
/// - Media Next: skip to next track
/// - Media Previous: skip to previous track
///
/// Only initializes on macOS, Windows, and Linux.
class GlobalShortcutsService {
  bool _initialized = false;

  static bool get isSupported => PlatformHelper.isDesktop;

  Future<void> init(MusicAudioHandler handler) async {
    if (_initialized || !isSupported) return;

    try {
      // Media Play/Pause
      await hotKeyManager.register(
        HotKey(
          key: LogicalKeyboardKey.mediaPlayPause,
          scope: HotKeyScope.system,
        ),
        keyDownHandler: (_) => handler.togglePlayPause(),
      );

      // Media Next Track
      await hotKeyManager.register(
        HotKey(
          key: LogicalKeyboardKey.mediaTrackNext,
          scope: HotKeyScope.system,
        ),
        keyDownHandler: (_) => handler.skipToNext(),
      );

      // Media Previous Track
      await hotKeyManager.register(
        HotKey(
          key: LogicalKeyboardKey.mediaTrackPrevious,
          scope: HotKeyScope.system,
        ),
        keyDownHandler: (_) => handler.skipToPrevious(),
      );

      // Fallback: Ctrl+Shift+Space on keyboards without media keys
      await hotKeyManager.register(
        HotKey(
          key: LogicalKeyboardKey.space,
          modifiers: [HotKeyModifier.control, HotKeyModifier.shift],
          scope: HotKeyScope.system,
        ),
        keyDownHandler: (_) => handler.togglePlayPause(),
      );

      _initialized = true;
      debugPrint('Global shortcuts registered');
    } catch (e) {
      debugPrint('Failed to register global shortcuts: $e');
    }
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    await hotKeyManager.unregisterAll();
    _initialized = false;
  }
}
