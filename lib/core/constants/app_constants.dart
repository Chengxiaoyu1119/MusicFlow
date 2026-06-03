import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'MusicFlow';
  static const String appVersion = '1.0.0';

  // Storage keys
  static const String themeModeKey = 'theme_mode';
  static const String lastPlayedKey = 'last_played';
  static const String playlistsKey = 'playlists';

  // Animation durations
  static const Duration fastAnim = Duration(milliseconds: 200);
  static const Duration mediumAnim = Duration(milliseconds: 350);
  static const Duration slowAnim = Duration(milliseconds: 600);

  // Player defaults
  static const double defaultVolume = 0.8;
  static const Duration seekStep = Duration(seconds: 10);

  // UI
  static const double miniPlayerHeight = 64;
  static const double bottomNavHeight = 80;
  static const double expandedPlayerHeight = 64;
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
  );

  // Supported audio extensions
  static const List<String> audioExtensions = [
    '.mp3', '.flac', '.wav', '.aac', '.ogg', '.wma',
    '.m4a', '.opus', '.ape', '.aiff',
  ];
}
