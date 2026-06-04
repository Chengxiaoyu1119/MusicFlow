import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/platform_helper.dart';
import '../models/music.dart';

/// 音乐库服务 — 支持文件夹导入、元数据解析、艺术家/专辑分类
class LibraryService {
  List<Music> _localMusic = [];
  bool _isScanning = false;
  int _scanProgress = 0;
  int _scanTotal = 0;

  List<Music> get localMusic => List.unmodifiable(_localMusic);
  bool get isScanning => _isScanning;
  int get scanProgress => _scanProgress;
  int get scanTotal => _scanTotal;

  // ===================== 按艺术家/专辑分类 =====================

  Map<String, List<Music>> get musicByArtist {
    final map = <String, List<Music>>{};
    for (final m in _localMusic) {
      map.putIfAbsent(m.artist, () => []);
      map[m.artist]!.add(m);
    }
    return map;
  }

  Map<String, List<Music>> get musicByAlbum {
    final map = <String, List<Music>>{};
    for (final m in _localMusic) {
      final key = m.album.isNotEmpty ? m.album : '未知专辑';
      map.putIfAbsent(key, () => []);
      map[key]!.add(m);
    }
    return map;
  }

  List<String> get artists => musicByArtist.keys.toList()..sort();
  List<String> get albums => musicByAlbum.keys.toList()..sort();

  // ===================== 扫描本地音乐 =====================

  Future<List<Music>> scanLocalMusic() async {
    if (_isScanning) return _localMusic;
    _isScanning = true;
    _scanProgress = 0;

    try {
      if (PlatformHelper.isMobile) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }
      }

      // 扫描常见音乐目录
      final home = Platform.environment['HOME'] ?? '/';
      final dirs = [
        '${home}/Music',
        '${home}/Downloads',
        '${home}/Desktop',
      ];

      // 收集所有文件
      final allFiles = <File>[];
      for (final dirPath in dirs) {
        final dir = Directory(dirPath);
        if (await dir.exists()) {
          try {
            await for (final entity in dir.list(recursive: true)) {
              if (entity is File) {
                final path = entity.path.toLowerCase();
                if (AppConstants.audioExtensions.any((ext) => path.endsWith(ext))) {
                  allFiles.add(entity);
                }
              }
            }
          } catch (_) {}
        }
      }

      _scanTotal = allFiles.length;

      // 并发解析元数据（每次 5 个）
      final batches = allFiles.length ~/ 5 + 1;
      for (int b = 0; b < batches; b++) {
        final batch = allFiles.skip(b * 5).take(5).toList();
        await Future.wait(batch.map((file) async {
          final music = await _parseAudioFile(file);
          if (music != null && !_localMusic.any((m) => m.filePath == file.path)) {
            _localMusic.add(music);
          }
          _scanProgress++;
        }));
      }
    } catch (e) {
      debugPrint('Scan error: $e');
    } finally {
      _isScanning = false;
    }
    return _localMusic;
  }

  // ===================== 导入文件夹 =====================

  Future<List<Music>> pickMusicDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择音乐文件夹',
    );
    if (result == null) return [];

    final dir = Directory(result);
    if (!await dir.exists()) return [];

    _isScanning = true;
    final newMusic = <Music>[];

    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final path = entity.path.toLowerCase();
          if (AppConstants.audioExtensions.any((ext) => path.endsWith(ext))) {
            final music = await _parseAudioFile(entity);
            if (music != null && !_localMusic.any((m) => m.filePath == entity.path)) {
              _localMusic.add(music);
              newMusic.add(music);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Import error: $e');
    } finally {
      _isScanning = false;
    }
    return newMusic;
  }

  // ===================== 导入单个文件 =====================

  Future<List<Music>> pickMusicFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'flac', 'wav', 'aac', 'ogg', 'm4a', 'opus', 'ape'],
      allowMultiple: true,
    );
    if (result == null) return [];

    final newMusic = <Music>[];
    for (final file in result.files) {
      if (file.path != null) {
        final music = await _parseAudioFile(File(file.path!));
        if (music != null && !_localMusic.any((m) => m.filePath == file.path)) {
          _localMusic.add(music);
          newMusic.add(music);
        }
      }
    }
    return newMusic;
  }

  // ===================== 元数据解析 =====================

  Future<Music?> _parseAudioFile(File file) async {
    try {
      final name = file.uri.pathSegments.last;

      // 尝试从元数据读取
      String title = '';
      String artist = '未知艺术家';
      String album = '';
      Duration duration = Duration.zero;

      try {
        final metadata = readMetadata(file);
        title = metadata.title ?? '';
        artist = metadata.artist ?? '未知艺术家';
        album = metadata.album ?? '';
        duration = metadata.duration ?? Duration.zero;
      } catch (e) {
        // 元数据读取失败，文件名解析
        title = '';
      }

      // 文件名解析 fallback
      if (title.isEmpty) {
        final basename = name.replaceAll(RegExp(r'\.[^.]+$'), '');
        final dashIndex = basename.indexOf(' - ');
        if (dashIndex > 0) {
          artist = basename.substring(0, dashIndex).trim();
          title = basename.substring(dashIndex + 3).trim();
        } else {
          title = basename;
        }
      }

      return Music(
        id: 'local_${file.path.hashCode}',
        title: title,
        artist: artist,
        album: album,
        filePath: file.path,
        source: MusicSource.local,
        duration: duration,
      );
    } catch (e) {
      debugPrint('Parse error ${file.path}: $e');
      return null;
    }
  }

  // ===================== 持久化 =====================

  Future<void> savePlaylists(List<Playlist> playlists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.playlistsKey, jsonEncode(
      playlists.map((p) => p.toJson()).toList()));
  }

  Future<List<Playlist>> loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.playlistsKey) ?? '[]';
    try {
      final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
      return jsonList.map((j) => Playlist.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
}

final libraryServiceProvider = Provider<LibraryService>((ref) {
  return LibraryService();
});
