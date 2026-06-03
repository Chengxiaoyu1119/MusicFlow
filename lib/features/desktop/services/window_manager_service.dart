import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/constants/platform_helper.dart';

/// Manages window state (size, position, close behavior) for desktop platforms.
///
/// Features:
/// - Remembers window size and position between sessions
/// - Sets minimum window size
/// - Intercepts close to minimize to tray instead of quitting
class WindowManagerService with WidgetsBindingObserver {
  static const double _minWidth = 800;
  static const double _minHeight = 600;
  static const String _sizeKey = 'window_size';
  static const String _posKey = 'window_position';

  static bool get isSupported => PlatformHelper.isDesktop;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || !isSupported) return;

    try {
      await windowManager.ensureInitialized();

      // Restore saved window state
      final prefs = await SharedPreferences.getInstance();
      final savedSize = prefs.getString(_sizeKey);
      final savedPos = prefs.getString(_posKey);

      final defaultSize = const Size(1024, 720);
      final defaultPos = const Offset(200, 100);

      if (savedSize != null) {
        final parts = savedSize.split(',');
        final w = double.tryParse(parts[0]) ?? defaultSize.width;
        final h = double.tryParse(parts[1]) ?? defaultSize.height;
        await windowManager.setSize(Size(w.clamp(_minWidth, 9999), h.clamp(_minHeight, 9999)));
      } else {
        await windowManager.setSize(defaultSize);
      }

      if (savedPos != null) {
        final parts = savedPos.split(',');
        final x = double.tryParse(parts[0]) ?? defaultPos.dx;
        final y = double.tryParse(parts[1]) ?? defaultPos.dy;
        await windowManager.setPosition(Offset(x.clamp(0, 9999), y.clamp(0, 9999)));
      } else {
        await windowManager.setPosition(defaultPos);
      }

      await windowManager.setMinimumSize(const Size(_minWidth, _minHeight));
      await windowManager.setTitle('MusicFlow');
      await windowManager.setPreventClose(true);

      // Listen for window events
      windowManager.addListener(_WindowListener(this));
      WidgetsBinding.instance.addObserver(this);

      _initialized = true;
      debugPrint('Window manager initialized');
    } catch (e) {
      debugPrint('Failed to initialize window manager: $e');
    }
  }

  Future<void> saveWindowState() async {
    if (!_initialized || !isSupported) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final size = await windowManager.getSize();
      final position = await windowManager.getPosition();

      await prefs.setString(_sizeKey, '${size.width},${size.height}');
      await prefs.setString(_posKey, '${position.dx},${position.dy}');
    } catch (e) {
      // Silently handle
    }
  }

  Future<void> onWindowClose() async {
    await saveWindowState();
    await windowManager.hide();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      saveWindowState();
    }
  }

  Future<void> show() => windowManager.show();
  Future<void> hide() => windowManager.hide();

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

class _WindowListener implements WindowListener {
  final WindowManagerService _service;

  _WindowListener(this._service);

  @override
  void onWindowClose() => _service.onWindowClose();

  @override
  void onWindowResize() => _service.saveWindowState();

  @override
  void onWindowMove() => _service.saveWindowState();

  @override
  void onWindowMinimize() {}

  @override
  void onWindowMaximize() {}

  @override
  void onWindowUnmaximize() {}

  @override
  void onWindowRestore() {}

  @override
  void onWindowFocus() {}

  @override
  void onWindowBlur() {}

  @override
  void onWindowResized() => _service.saveWindowState();

  @override
  void onWindowMoved() => _service.saveWindowState();

  @override
  void onWindowEnterFullScreen() {}

  @override
  void onWindowLeaveFullScreen() {}

  @override
  void onWindowDocked() {}

  @override
  void onWindowUndocked() {}

  @override
  void onWindowEvent(String eventName) {}
}
