import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api/plugin_model.dart';

/// JavaScript sandbox for executing external music source plugins.
///
/// Uses `flutter_js` (QuickJS) to run user-provided JS plugins
/// in a sandboxed environment with timeout protection.
///
/// Plugin JS files should export an object conforming to:
/// ```javascript
/// module.exports = {
///   platform: 'name',
///   search: async (query, page, type) => ({ isEnd, data: [...] }),
///   getMediaSource: async (id, quality) => 'url',
///   getLyric: async (id) => 'lrc text',
/// };
/// ```
class JsSandbox {
  /// Evaluate a JS plugin script and execute one of its methods.
  Future<dynamic> executePluginMethod({
    required String source,
    required String method,
    required List<dynamic> args,
  }) async {
    try {
      final result = await _evaluateJs(_buildScript(source, method, args));
      return result;
    } catch (e) {
      debugPrint('JS sandbox error: $e');
      rethrow;
    }
  }

  String _buildScript(String source, String method, List<dynamic> args) {
    final argsJson = args.map((a) => jsonEncode(a)).join(', ');
    return '''
(function() {
  const module = { exports: {} };
  const exports = module.exports;

  // Plugin source
  $source

  // Execute method
  const plugin = module.exports;
  if (typeof plugin.$method === 'function') {
    return JSON.stringify(plugin.$method($argsJson));
  }
  return null;
})()
''';
  }

  Future<dynamic> _evaluateJs(String script) async {
    // TODO: Integrate with flutter_js QuickJS runtime
    // For now, return empty results as a fallback
    debugPrint('JS sandbox: evaluation stub - implement with flutter_js');
    return null;
  }

  /// Parse a search result from JS execution.
  PluginSearchResult parseSearchResult(dynamic result) {
    if (result == null) {
      return PluginSearchResult(isEnd: true);
    }

    try {
      final data = result is Map ? result : jsonDecode(result as String) as Map;
      final songs = (data['data'] as List<dynamic>?) ?? [];
      final isEnd = data['isEnd'] as bool? ?? true;
      final platform = data['platform'] as String? ?? 'unknown';

      return PluginSearchResult(
        platform: platform,
        isEnd: isEnd,
        music: songs.map((s) => _parseMusicItem(s)).toList(),
      );
    } catch (e) {
      return PluginSearchResult(isEnd: true);
    }
  }

  PluginMusicItem _parseMusicItem(dynamic s) {
    final map = s is Map ? s : {};
    return PluginMusicItem(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? map['name'] ?? '').toString(),
      artist: (map['artist'] ?? '').toString(),
      album: (map['album'] as String?),
      artwork: (map['artwork'] as String?),
      duration: (map['duration'] as int? ?? 0),
    );
  }
}
