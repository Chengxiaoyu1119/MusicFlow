import 'package:dio/dio.dart';

import '../api/plugin_model.dart';

/// Built-in plugin for QQ Music.
///
/// Uses a self-hosted or public QQ Music API backend.
/// Set [apiBaseUrl] to point to your own API instance.
///
/// API spec: https://github.com/jsososo/QQMusicApi
class QQMusicPlugin extends MusicSourcePlugin {
  @override
  final String platform = 'qq';
  @override
  final String version = '1.0.0';
  @override
  final String pluginId = 'qq';
  @override
  final bool isEnabled = true;

  final Dio _dio;
  final String apiBaseUrl;

  QQMusicPlugin({
    this.apiBaseUrl = 'http://localhost:3300',
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
      final response = await _dio.get(
        '$apiBaseUrl/search',
        queryParameters: {
          'key': query,
          'pageNo': page,
          'pageSize': 30,
          'type': _searchTypeToCode(type),
        },
      );

      final data = response.data;
      if (data['code'] != 0) {
        return PluginSearchResult(platform: platform, isEnd: true);
      }

      final result = data['data'];
      if (result == null) return PluginSearchResult(platform: platform, isEnd: true);

      final songList = result['list'] as List<dynamic>? ?? [];
      final total = result['total'] as int? ?? 0;
      final hasMore = total > page * 30;

      return PluginSearchResult(
        platform: platform,
        isEnd: !hasMore,
        music: songList.map((s) => _parseSong(s)).toList(),
      );
    } catch (e) {
      return PluginSearchResult(platform: platform, isEnd: true);
    }
  }

  @override
  Future<String?> getMediaSource(String id, {String quality = 'standard'}) async {
    try {
      final qualityMap = {
        'low': '128',
        'standard': '192',
        'high': '320',
        'lossless': 'flac',
        'master': 'master',
      };
      final q = qualityMap[quality] ?? '192';

      final response = await _dio.get(
        '$apiBaseUrl/song/url',
        queryParameters: {
          'id': id,
          'quality': q,
          'type': 'json',
        },
      );

      final data = response.data;
      if (data['code'] != 0) return null;

      final url = data['data'] as String?;
      return url;
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
      if (data['code'] != 0) return null;

      final lyric = data['data']['lyric'] as String?;
      return lyric;
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
      if (data['code'] != 0) return [];

      final list = data['data']['list'] as List<dynamic>? ?? [];
      return list.map((s) => _parseSong(s)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<PluginMusicItem>> getSheetTracks(String sheetId) async {
    try {
      final response = await _dio.get(
        '$apiBaseUrl/songlist',
        queryParameters: {'id': sheetId},
      );

      final data = response.data;
      if (data['code'] != 0) return [];

      final list = data['data']['songlist'] as List<dynamic>? ?? [];
      return list.map((s) => _parseSong(s)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<PluginMusicItem>> getArtistTracks(String artistId, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '$apiBaseUrl/singer/songs',
        queryParameters: {
          'id': artistId,
          'pageNo': page,
          'pageSize': 50,
        },
      );

      final data = response.data;
      if (data['code'] != 0) return [];

      final list = data['data']['list'] as List<dynamic>? ?? [];
      return list.map((s) => _parseSong(s)).toList();
    } catch (e) {
      return [];
    }
  }

  PluginMusicItem _parseSong(dynamic s) {
    final singers = (s['singer'] ?? s['singers'] ?? []) as List<dynamic>;
    final albumData = s['album'] as Map<String, dynamic>?;

    return PluginMusicItem(
      id: (s['id'] ?? s['mid'] ?? s['songmid']).toString(),
      title: s['title'] ?? s['songname'] ?? s['name'] ?? '',
      artist: singers
          .map((a) => a is Map ? (a['name'] as String? ?? '') : '')
          .join(', '),
      album: albumData?['title'] ?? albumData?['name'] ?? s['albumname'] as String? ?? '',
      artwork: albumData?['cover'] as String?,
      duration: (s['interval'] ?? s['duration'] as int? ?? 0) * 1000,
      qualities: {'standard': '192', 'high': '320', 'lossless': 'flac'},
    );
  }

  int _searchTypeToCode(String type) {
    return switch (type) {
      'album' => 8,
      'artist' => 9,
      'sheet' => 10,
      _ => 0, // music
    };
  }
}
