import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/platform_helper.dart';
import '../models/music.dart';

class LibraryService {
  List<Music> _localMusic = [];
  bool _isScanning = false;

  List<Music> get localMusic => List.unmodifiable(_localMusic);
  bool get isScanning => _isScanning;

  /// Scan local directories for music files
  Future<List<Music>> scanLocalMusic() async {
    if (_isScanning) return _localMusic;

    _isScanning = true;

    try {
      // Request storage permissions
      if (PlatformHelper.isMobile) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }
      }

      final musicDir = await getExternalStorageDirectory();
      if (musicDir == null) {
        // Try common music directories
        final home = Platform.environment['HOME'] ?? '/';
        final commonDirs = [
          '${home}/Music',
          '${home}/Downloads',
        ];
        for (final dir in commonDirs) {
          await _scanDirectory(Directory(dir));
        }
      } else {
        await _scanDirectory(musicDir);
      }
    } catch (e) {
      debugPrint('Scan error: $e');
    } finally {
      _isScanning = false;
    }

    return _localMusic;
  }

  Future<void> _scanDirectory(Directory dir) async {
    if (!await dir.exists()) return;

    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final path = entity.path.toLowerCase();
          if (AppConstants.audioExtensions.any((ext) => path.endsWith(ext))) {
            final music = await _parseAudioFile(entity);
            if (music != null && !_localMusic.any((m) => m.filePath == entity.path)) {
              _localMusic.add(music);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning ${dir.path}: $e');
    }
  }

  Future<Music?> _parseAudioFile(File file) async {
    try {
      final name = file.uri.pathSegments.last;
      // Basic parsing: remove extension, split artist - title
      final basename = name.replaceAll(RegExp(r'\.[^.]+$'), '');
      String title = basename;
      String artist = 'Unknown Artist';

      // Try to parse "artist - title" pattern
      final dashIndex = basename.indexOf(' - ');
      if (dashIndex > 0) {
        artist = basename.substring(0, dashIndex).trim();
        title = basename.substring(dashIndex + 3).trim();
      }

      return Music(
        id: 'local_${file.path.hashCode}',
        title: title,
        artist: artist,
        filePath: file.path,
        source: MusicSource.local,
        duration: Duration.zero, // Will be updated by just_audio
      );
    } catch (e) {
      debugPrint('Error parsing ${file.path}: $e');
      return null;
    }
  }

  /// Pick music files using file picker
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

  Future<void> savePlaylists(List<Playlist> playlists) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = playlists.map((p) => p.toJson()).toList();
    await prefs.setString(AppConstants.playlistsKey, jsonEncode(jsonList));
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
