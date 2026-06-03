import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/music.dart';

/// Service for managing persistent data storage (playlists, settings, cache).
class HiveStorageService {
  static const String _playlistBoxName = 'playlists';
  static const String _cacheBoxName = 'cache';
  static const String _recentBoxName = 'recent';

  Box<String>? _playlistBox;
  Box<String>? _cacheBox;
  Box<String>? _recentBox;

  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;

    _playlistBox = await Hive.openBox<String>(_playlistBoxName);
    _cacheBox = await Hive.openBox<String>(_cacheBoxName);
    _recentBox = await Hive.openBox<String>(_recentBoxName);
    _initialized = true;
  }

  Future<void> ensureInitialized() async {
    if (!_initialized) await init();
  }

  // ====================
  //  Playlist Storage
  // ====================

  Future<void> savePlaylist(Playlist playlist) async {
    final box = _playlistBox;
    if (box == null) return;
    await box.put(playlist.id, jsonEncode(playlist.toJson()));
  }

  Future<void> savePlaylists(List<Playlist> playlists) async {
    final box = _playlistBox;
    if (box == null) return;
    for (final playlist in playlists) {
      await box.put(playlist.id, jsonEncode(playlist.toJson()));
    }
  }

  List<Playlist> loadPlaylists() {
    final box = _playlistBox;
    if (box == null) return [];
    return box.values.map((raw) {
      try {
        return Playlist.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<Playlist>().toList();
  }

  Future<void> deletePlaylist(String id) async {
    await _playlistBox?.delete(id);
  }

  // ====================
  //  Cache Storage
  // ====================

  Future<void> setCache(String key, String value) async {
    await _cacheBox?.put(key, value);
  }

  String? getCache(String key) => _cacheBox?.get(key);

  Future<void> clearCache() async {
    await _cacheBox?.clear();
  }

  // ====================
  //  Recent Plays
  // ====================

  Future<void> addRecentPlay(Music music) async {
    final box = _recentBox;
    if (box == null) return;

    // Remove duplicate if exists
    final existingKey = box.keys.firstWhere(
      (k) {
        final raw = box.get(k);
        if (raw == null) return false;
        try {
          return Music.fromJson(jsonDecode(raw) as Map<String, dynamic>).id == music.id;
        } catch (_) {
          return false;
        }
      },
      orElse: () => '',
    );
    if (existingKey.isNotEmpty) {
      await box.delete(existingKey);
    }

    // Add to front using timestamp as key
    await box.put(
      DateTime.now().millisecondsSinceEpoch.toString(),
      jsonEncode(music.toJson()),
    );

    // Keep only last 50
    while (box.length > 50) {
      final oldestKey = box.keys.first;
      await box.delete(oldestKey);
    }
  }

  List<Music> loadRecentPlays() {
    final box = _recentBox;
    if (box == null) return [];

    final keys = box.keys.map((k) => int.tryParse(k) ?? 0).toList()
      ..sort((a, b) => b.compareTo(a));

    return keys.map((key) {
      final raw = box.get(key.toString());
      if (raw == null) return null;
      try {
        return Music.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<Music>().toList();
  }
}

// ====================
//  Theme Mode Storage
// ====================

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(AppConstants.themeModeKey) ?? 'system';
    state = switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await prefs.setString(AppConstants.themeModeKey, value);
  }
}

final hiveStorageProvider = Provider<HiveStorageService>((ref) {
  return HiveStorageService();
});
