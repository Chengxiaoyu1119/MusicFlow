import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../api/plugin_model.dart';
import 'js_sandbox.dart';
import 'plugin_encryption.dart';

/// Engine that loads and executes music source plugins.
///
/// Supports two plugin types:
/// 1. Built-in Dart plugins (registered at compile time)
/// 2. External JS plugins (loaded from file system at runtime)
class PluginEngine {
  final List<MusicSourcePlugin> _builtinPlugins = [];
  final List<ExternalPlugin> _externalPlugins = [];
  bool _initialized = false;

  List<MusicSourcePlugin> get allPlugins =>
      [..._builtinPlugins, ..._externalPlugins];

  List<MusicSourcePlugin> get availablePlugins =>
      allPlugins.where((p) => p.isEnabled).toList();

  /// Register a built-in Dart plugin.
  void registerPlugin(MusicSourcePlugin plugin) {
    _builtinPlugins.add(plugin);
  }

  /// Initialize the engine, loading external plugins from storage.
  Future<void> init() async {
    if (_initialized) return;
    await _loadExternalPlugins();
    _initialized = true;
  }

  /// Load external JS plugins from the app's plugin directory.
  Future<void> _loadExternalPlugins() async {
    try {
      final dir = await _getPluginDir();
      if (!await dir.exists()) return;

      await for (final file in dir.list()) {
        if (file is File && file.path.endsWith('.js')) {
          try {
            final plugin = await _parseExternalPlugin(file);
            if (plugin != null) {
              _externalPlugins.add(plugin);
            }
          } catch (e) {
            debugPrint('Failed to load plugin ${file.path}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading external plugins: $e');
    }
  }

  Future<Directory> _getPluginDir() async {
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory('${appDir.path}/plugins');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<ExternalPlugin?> _parseExternalPlugin(File file) async {
    // Decrypt the file if encrypted
    final encryption = PluginEncryption();
    final content = await encryption.decryptFile(file.path) ?? await file.readAsString();
    final manifest = await _parseManifest(file);

    return ExternalPlugin(
      id: manifest['id'] ?? file.uri.pathSegments.last.replaceAll('.js', ''),
      name: manifest['name'] ?? file.uri.pathSegments.last,
      version: manifest['version'] ?? '1.0.0',
      description: manifest['description'] ?? '',
      author: manifest['author'],
      source: content,
      filePath: file.path,
    );
  }

  Future<Map<String, String>> _parseManifest(File file) async {
    final manifestFile = File(file.path.replaceAll('.js', '.json'));
    if (!await manifestFile.exists()) return {};
    try {
      final content = await manifestFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return json.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  /// Install a plugin from a URL.
  Future<ExternalPlugin?> installFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      final content = response.body;
      final uri = Uri.parse(url);
      final filename = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : 'plugin_${DateTime.now().millisecondsSinceEpoch}.js';

      final dir = await _getPluginDir();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(content);

      // Encrypt the plugin file for secure storage
      final encryption = PluginEncryption();
      await encryption.encryptFile(file.path);

      final plugin = await _parseExternalPlugin(file);
      if (plugin != null) {
        _externalPlugins.add(plugin);
      }
      return plugin;
    } catch (e) {
      debugPrint('Failed to install plugin from $url: $e');
      return null;
    }
  }

  /// Remove an external plugin.
  Future<void> removePlugin(String id) async {
    final index = _externalPlugins.indexWhere((p) => p.id == id);
    if (index >= 0) {
      final plugin = _externalPlugins.removeAt(index);
      try {
        final file = File(plugin.filePath);
        if (await file.exists()) await file.delete();

        final manifestFile = File(
          plugin.filePath.replaceAll('.js', '.json'),
        );
        if (await manifestFile.exists()) await manifestFile.delete();
      } catch (_) {}
    }
  }

  /// Search across all available plugins.
  Future<List<PluginSearchResult>> searchAll(
    String query, {
    int page = 1,
    String type = 'music',
  }) async {
    final results = <PluginSearchResult>[];
    final plugins = availablePlugins;

    for (final plugin in plugins) {
      try {
        final result = await plugin.search(query, page: page, type: type);
        results.add(result);
      } catch (e) {
        debugPrint('Search error in plugin ${plugin.platform}: $e');
      }
    }
    return results;
  }

  /// Get media source from a specific plugin.
  Future<String?> getMediaSource(
    String pluginId,
    String musicId, {
    String quality = 'standard',
  }) async {
    for (final plugin in allPlugins) {
      if (plugin.pluginId == pluginId || plugin.platform == pluginId) {
        return plugin.getMediaSource(musicId, quality: quality);
      }
    }
    throw Exception('Plugin not found: $pluginId');
  }
}

/// An external plugin loaded from a JS file at runtime.
class ExternalPlugin extends MusicSourcePlugin {
  @override
  final String platform;
  @override
  final String version;
  final String id;
  final String name;
  final String description;
  final String? author;
  final String source;
  final String filePath;
  @override
  bool isEnabled;

  ExternalPlugin({
    required this.id,
    required this.name,
    required this.version,
    this.description = '',
    this.author,
    required this.source,
    required this.filePath,
    this.isEnabled = true,
    String? platform,
  }) : platform = platform ?? name;

  @override
  String get pluginId => id;

  @override
  Future<PluginSearchResult> search(
    String query, {
    int page = 1,
    String type = 'music',
  }) async {
    try {
      final sandbox = JsSandbox();
      final result = await sandbox.executePluginMethod(
        source: source,
        method: 'search',
        args: [query, page, type],
      );
      if (result != null) {
        return sandbox.parseSearchResult(result);
      }
    } catch (e) {
      debugPrint('JS plugin $name search error: $e');
    }
    return PluginSearchResult(platform: platform, isEnd: true);
  }

  @override
  Future<String?> getMediaSource(String id, {String quality = 'standard'}) async {
    try {
      final sandbox = JsSandbox();
      final result = await sandbox.executePluginMethod(
        source: source,
        method: 'getMediaSource',
        args: [id, quality],
      );
      return result?.toString();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> getLyric(String id) async {
    try {
      final sandbox = JsSandbox();
      final result = await sandbox.executePluginMethod(
        source: source,
        method: 'getLyric',
        args: [id],
      );
      return result?.toString();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<PluginMusicItem>> getAlbumTracks(String albumId) async => [];

  @override
  Future<List<PluginMusicItem>> getSheetTracks(String sheetId) async => [];

  @override
  Future<List<PluginMusicItem>> getArtistTracks(String artistId, {int page = 1}) async => [];
}
