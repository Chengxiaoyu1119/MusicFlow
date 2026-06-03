import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/lyrics_model.dart';
import '../plugin/plugin_manager.dart';
import 'audio_provider.dart';

/// Provides parsed lyrics for the currently playing track.
///
/// Watches the current music and fetches lyrics from available plugins.
final lyricsProvider = FutureProvider.autoDispose<Lyrics?>((ref) async {
  final music = ref.watch(currentMusicProvider).valueOrNull;
  if (music == null) return null;

  // Try to get lyrics from plugins
  final pluginManager = ref.watch(pluginManagerProvider.notifier);
  final engine = pluginManager.engine;

  for (final plugin in engine.availablePlugins) {
    if (music.pluginId != null && music.pluginId != plugin.pluginId) continue;

    try {
      final lrcText = await plugin.getLyric(music.id);
      if (lrcText != null && lrcText.isNotEmpty) {
        return Lyrics.fromLrc(lrcText);
      }
    } catch (_) {
      continue;
    }
  }

  return null;
});
