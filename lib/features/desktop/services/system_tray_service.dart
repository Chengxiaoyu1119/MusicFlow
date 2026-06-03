import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';

import '../../../core/constants/platform_helper.dart';

import '../../../audio/audio_handler.dart';

/// System tray service for desktop platforms.
///
/// Provides a system tray/menu bar icon with playback controls.
class SystemTrayService with TrayListener {
  final MusicAudioHandler _audioHandler;
  bool _initialized = false;

  static bool get isSupported => PlatformHelper.isDesktop;

  SystemTrayService(this._audioHandler);

  Future<void> init() async {
    if (_initialized || !isSupported) return;

    try {
      trayManager.setToolTip('MusicFlow');
      trayManager.addListener(this);

      // Set tray icon (use app icon from platform assets)
      if (PlatformHelper.isMacOS) {
        trayManager.setIcon(
          'macos/Runner/Assets.xcassets/AppIcon.appiconset/icon_256x256.png',
        );
      } else {
        trayManager.setIcon('assets/icon.png');
      }

      await _updateMenu();
      _initialized = true;
      debugPrint('System tray initialized');
    } catch (e) {
      debugPrint('Failed to initialize system tray: $e');
    }
  }

  Future<void> _updateMenu() async {
    final isPlaying = _audioHandler.isPlaying;
    final current = _audioHandler.currentMusic;

    final nowPlaying = current != null
        ? '${current.title} - ${current.artist}'
        : 'No music playing';

    final title = nowPlaying.length > 40
        ? '${nowPlaying.substring(0, 40)}...'
        : nowPlaying;

    await trayManager.setContextMenu(Menu(
      items: [
        MenuItem(label: title, disabled: true),
        MenuItem.separator(),
        MenuItem(
          key: 'play_pause',
          label: isPlaying ? 'Pause' : 'Play',
        ),
        MenuItem(key: 'next', label: 'Next Track'),
        MenuItem(key: 'previous', label: 'Previous Track'),
        MenuItem.separator(),
        MenuItem(key: 'show', label: 'Show Window'),
        MenuItem(key: 'quit', label: 'Quit'),
      ],
    ));
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'play_pause':
        _audioHandler.togglePlayPause();
        break;
      case 'next':
        _audioHandler.skipToNext();
        break;
      case 'previous':
        _audioHandler.skipToPrevious();
        break;
      case 'quit':
        _audioHandler.stop();
        break;
    }
    _updateMenu();
  }

  @override
  void onTrayIconMouseDown() {
    // Click tray icon to show window
  }

  /// Call this when playback state changes to update tray menu.
  Future<void> onPlaybackChanged() => _updateMenu();

  Future<void> dispose() async {
    if (_initialized) {
      trayManager.removeListener(this);
      trayManager.destroy();
      _initialized = false;
    }
  }
}
