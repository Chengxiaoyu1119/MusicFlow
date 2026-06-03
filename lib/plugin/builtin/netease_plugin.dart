import 'package:dio/dio.dart';

import '../api/plugin_model.dart';

/// Built-in plugin for Netease Cloud Music.
///
/// Uses an instance of Binaryify/NeteaseCloudMusicApi as the backend.
/// Set [apiBaseUrl] to your own API instance for production use.
///
/// Example API: https://github.com/Binaryify/NeteaseCloudMusicApi
class NeteaseMusicPlugin extends MusicSourcePlugin {
  @override
  final String platform = 'netease';
  @override
  final String version = '1.0.0';
  @override
  final String pluginId = 'netease';
  @override
  final bool isEnabled = true;

  final Dio _dio;
  final String apiBaseUrl;

  NeteaseMusicPlugin({
    this.apiBaseUrl = 'http://localhost:3000',
    Dio? dio,
  }) : _dio = dio ?? Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  @override
  Future<PluginSearchResult> search(
    String query, {
    int page = 1,
    String type = 'music',
  }) async {
    try {
      final offset = (page - 1) * 30;
      final response = await _dio.get(
        '$apiBaseUrl/cloudsearch',
        queryParameters: {
          'keywords': query,
          'type': _searchTypeToCode(type),
          'offset': offset,
          'limit': 30,
        },
      );

      final data = response.data;
      if (data['code'] != 200) {
        return PluginSearchResult(platform: platform, isEnd: true);
      }

      final result = data['result'];
      if (result == null) {
        return PluginSearchResult(platform: platform, isEnd: true);
      }

      final songs = (result['songs'] as List<dynamic>?) ?? [];
      final total = result['songCount'] as int? ?? 0;
      final hasMore = total > offset + 30;

      return PluginSearchResult(
        platform: platform,
        isEnd: !hasMore,
        music: songs.map((s) => _parseSong(s)).toList(),
      );
    } catch (e) {
      return PluginSearchResult(platform: platform, isEnd: true);
    }
  }

  @override
  Future<String?> getMediaSource(String id, {String quality = 'standard'}) async {
    try {
      final response = await _dio.get(
        '$apiBaseUrl/song/url/v1',
        queryParameters: {
          'id': id,
          'level': quality,
        },
      );

      final data = response.data;
      if (data['code'] != 200) return null;

      final songs = data['data'] as List<dynamic>? ?? [];
      if (songs.isEmpty) return null;

      return songs[0]['url'] as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> getLyric(String id) async {
    try {
      final response = await _dio.get(
        '$apiBaseUrl/lyric',
        queryParameters: {'id': id},
      );

      final data = response.data;
      if (data['code'] != 200) return null;

      final lrc = data['lrc'] as Map<String, dynamic>?;
      return lrc?['lyric'] as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<PluginMusicItem>> getAlbumTracks(String albumId) async {
    try {
      final response = await _dio.get(
        '$apiBaseUrl/album',
        queryParameters: {'id': albumId},
      );

      final data = response.data;
      if (data['code'] != 200) return [];

      final songs = (data['songs'] as List<dynamic>?) ?? [];
      return songs.map((s) => _parseSong(s)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<PluginMusicItem>> getSheetTracks(String sheetId) async {
    try {
      final response = await _dio.get(
        '$apiBaseUrl/playlist/track/all',
        queryParameters: {
          'id': sheetId,
          'limit': 1000,
        },
      );

      final data = response.data;
      if (data['code'] != 200) return [];

      final songs = (data['songs'] as List<dynamic>?) ?? [];
      return songs.map((s) => _parseSong(s)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<PluginMusicItem>> getArtistTracks(String artistId, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '$apiBaseUrl/artist/songs',
        queryParameters: {
          'id': artistId,
          'offset': (page - 1) * 50,
          'limit': 50,
        },
      );

      final data = response.data;
      if (data['code'] != 200) return [];

      final songs = (data['songs'] as List<dynamic>?) ?? [];
      return songs.map((s) => _parseSong(s)).toList();
    } catch (e) {
      return [];
    }
  }

  PluginMusicItem _parseSong(dynamic s) {
    final artists = (s['artists'] ?? s['ar']) as List<dynamic>? ?? [];
    final albumData = s['album'] ?? s['al'];
    String? artwork;
    if (albumData is Map) {
      artwork = albumData['picUrl'] as String? ?? albumData['pic_url'] as String?;
    }

    return PluginMusicItem(
      id: s['id'].toString(),
      title: s['name'] as String? ?? '',
      artist: artists.map((a) => a is Map ? a['name'] as String? ?? '' : '').join(', '),
      album: albumData is Map ? albumData['name'] as String? ?? '' : '',
      artwork: artwork,
      duration: (s['duration'] ?? s['dt'] ?? 0) ~/ 1000,
      qualities: {'standard': '128000', 'high': '320000', 'lossless': '999000'},
    );
  }

  int _searchTypeToCode(String type) {
    return switch (type) {
      'album' => 10,
      'artist' => 100,
      'sheet' => 1000,
      _ => 1,
    };
  }
}
