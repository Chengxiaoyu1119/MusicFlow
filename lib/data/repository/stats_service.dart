import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/music.dart';

/// Track play statistics.
class TrackStats {
  final String musicId;
  int playCount;
  int totalPlayTimeMs;
  int lastPlayedAt;

  TrackStats({
    required this.musicId,
    this.playCount = 0,
    this.totalPlayTimeMs = 0,
    int? lastPlayedAt,
  }) : lastPlayedAt = lastPlayedAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
    'musicId': musicId,
    'playCount': playCount,
    'totalPlayTimeMs': totalPlayTimeMs,
    'lastPlayedAt': lastPlayedAt,
  };

  factory TrackStats.fromJson(Map<String, dynamic> json) => TrackStats(
    musicId: json['musicId'] as String,
    playCount: json['playCount'] as int? ?? 0,
    totalPlayTimeMs: json['totalPlayTimeMs'] as int? ?? 0,
    lastPlayedAt: json['lastPlayedAt'] as int?,
  );
}

/// Service for tracking play statistics.
class StatsService {
  Box<String>? _statsBox;
  Map<String, TrackStats> _cache = {};
  int _sessionStartMs = 0;
  String? _currentMusicId;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _statsBox = await Hive.openBox<String>('stats');
    _loadCache();
    _initialized = true;
  }

  void _loadCache() {
    final box = _statsBox;
    if (box == null) return;
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw != null) {
        try {
          final stats = TrackStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
          _cache[key] = stats;
        } catch (_) {}
      }
    }
  }

  /// Call when a track starts playing.
  void trackStarted(Music music) {
    _sessionStartMs = DateTime.now().millisecondsSinceEpoch;
    _currentMusicId = music.id;

    final stats = _cache.putIfAbsent(music.id, () => TrackStats(musicId: music.id));
    stats.playCount++;
    stats.lastPlayedAt = _sessionStartMs;
    _save(music.id);
  }

  /// Call when a track pauses or changes.
  void trackStopped() {
    if (_currentMusicId == null || _sessionStartMs == 0) return;

    final elapsed = DateTime.now().millisecondsSinceEpoch - _sessionStartMs;
    final stats = _cache[_currentMusicId];
    if (stats != null) {
      stats.totalPlayTimeMs += elapsed;
      _save(_currentMusicId!);
    }

    _currentMusicId = null;
    _sessionStartMs = 0;
  }

  void _save(String id) {
    final stats = _cache[id];
    if (stats != null && _statsBox != null) {
      _statsBox!.put(id, jsonEncode(stats.toJson()));
    }
  }

  /// Get top played tracks (sorted by play count).
  List<TrackStats> getTopTracks({int limit = 20}) {
    final sorted = _cache.values.toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));
    return sorted.take(limit).toList();
  }

  /// Get total listening time in milliseconds.
  int get totalListeningTimeMs {
    return _cache.values.fold(0, (sum, s) => sum + s.totalPlayTimeMs);
  }

  /// Get total track plays.
  int get totalPlays => _cache.values.fold(0, (sum, s) => sum + s.playCount);

  /// Get number of unique tracks played.
  int get uniqueTracks => _cache.length;

  /// Get stats for a specific track.
  TrackStats? getStats(String musicId) => _cache[musicId];
}

final statsServiceProvider = Provider<StatsService>((ref) {
  return StatsService();
});
