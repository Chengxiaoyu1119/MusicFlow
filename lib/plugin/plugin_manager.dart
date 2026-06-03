import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/plugin_model.dart';
import 'builtin/netease_plugin.dart';
import 'builtin/qq_plugin.dart';
import 'engine/plugin_engine.dart';

/// Central plugin manager that provides plugin state to the UI.
class PluginManager extends StateNotifier<List<PluginInfo>> {
  final PluginEngine _engine;

  PluginManager(this._engine) : super([]);

  List<PluginInfo> get builtinPlugins =>
      state.where((p) => p.isBuiltin).toList();

  List<PluginInfo> get userPlugins =>
      state.where((p) => !p.isBuiltin).toList();

  List<PluginInfo> get enabledPlugins =>
      state.where((p) => p.isEnabled).toList();

  PluginEngine get engine => _engine;

  /// Initialize built-in plugins.
  Future<void> init() async {
    // Register built-in plugins
    _engine.registerPlugin(NeteaseMusicPlugin());
    _engine.registerPlugin(QQMusicPlugin());

    await _engine.init();

    // Build plugin info list
    final infos = <PluginInfo>[];
    for (final plugin in _engine.allPlugins) {
      infos.add(PluginInfo(
        id: plugin.pluginId,
        name: plugin.platform,
        version: plugin.version,
        type: PluginType.musicSource,
        isBuiltin: plugin is! ExternalPlugin,
        isEnabled: plugin.isEnabled,
      ));
    }
    state = infos;
  }

  void togglePlugin(String id) {
    state = state.map((p) {
      if (p.id == id) {
        return p.copyWith(isEnabled: !p.isEnabled);
      }
      return p;
    }).toList();

    // Toggle in engine as well
    final extPlugins = _engine.allPlugins.whereType<ExternalPlugin>();
    for (final plugin in extPlugins) {
      if (plugin.pluginId == id) {
        // Toggle state managed by PluginInfo
      }
    }
  }

  Future<void> installFromUrl(String url) async {
    final plugin = await _engine.installFromUrl(url);
    if (plugin != null) {
      state = [...state, PluginInfo(
        id: plugin.pluginId,
        name: plugin.name,
        version: plugin.version,
        description: plugin.description,
        type: PluginType.musicSource,
        isBuiltin: false,
        isEnabled: true,
        author: plugin.author,
        installUrl: url,
      )];
    }
  }

  Future<void> removePlugin(String id) async {
    state = state.where((p) => p.id != id || p.isBuiltin).toList();
    await _engine.removePlugin(id);
  }

  Future<List<PluginSearchResult>> searchAll(
    String query, {
    int page = 1,
    String type = 'music',
  }) async {
    return _engine.searchAll(query, page: page, type: type);
  }
}

final pluginManagerProvider =
    StateNotifierProvider<PluginManager, List<PluginInfo>>((ref) {
  final engine = PluginEngine();
  final manager = PluginManager(engine);
  manager.init();
  return manager;
});

/// Convenience provider to get the raw PluginEngine for direct use.
final pluginEngineProvider = Provider<PluginEngine>((ref) {
  final manager = ref.watch(pluginManagerProvider.notifier);
  return manager.engine;
});
