import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/plugin_model.dart';
import 'download_service.dart';

/// Wraps DownloadService with Riverpod state management.
class DownloadManager extends StateNotifier<List<DownloadTask>> {
  final DownloadService _service;

  DownloadManager() : _service = DownloadService(), super([]);

  List<DownloadTask> get tasks => state;

  Future<void> download({
    required MusicSourcePlugin plugin,
    required PluginMusicItem item,
    String quality = 'standard',
  }) async {
    // Check if already downloading
    if (state.any((t) => t.musicId == item.id && t.state == DownloadState.downloading)) {
      return;
    }

    final task = DownloadTask(
      musicId: item.id,
      title: item.title,
      artist: item.artist,
      artworkUrl: item.artwork,
      url: '',
      pluginId: plugin.pluginId,
      state: DownloadState.downloading,
    );
    state = [...state, task];

    final result = await _service.download(
      plugin: plugin,
      item: item,
      quality: quality,
    );

    // Update task state
    state = state.map((t) {
      if (t.musicId == item.id) {
        return DownloadTask(
          musicId: t.musicId,
          title: t.title,
          artist: t.artist,
          artworkUrl: t.artworkUrl,
          url: t.url,
          pluginId: t.pluginId,
          state: result?.success == true ? DownloadState.completed : DownloadState.failed,
          progress: result?.success == true ? 1.0 : 0.0,
          filePath: result?.filePath,
          error: result?.error,
        );
      }
      return t;
    }).toList();
  }

  void removeTask(String musicId) {
    state = state.where((t) => t.musicId != musicId).toList();
  }

  void clearCompleted() {
    state = state.where((t) => t.state != DownloadState.completed).toList();
  }

  List<DownloadTask> get completedTasks =>
      state.where((t) => t.state == DownloadState.completed).toList();
}

final downloadManagerProvider = StateNotifierProvider<DownloadManager, List<DownloadTask>>((ref) {
  return DownloadManager();
});
