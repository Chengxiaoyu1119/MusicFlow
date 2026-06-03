import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'api/plugin_model.dart';

/// Result of a download request.
class DownloadResult {
  final String id;
  final String title;
  final String? filePath;
  final bool success;
  final String? error;

  const DownloadResult({
    required this.id,
    required this.title,
    this.filePath,
    this.success = true,
    this.error,
  });
}

/// Download state for a track.
enum DownloadState { idle, downloading, completed, failed }

/// Tracks download progress.
class DownloadTask {
  final String musicId;
  final String title;
  final String artist;
  final String? artworkUrl;
  String url;
  final String? pluginId;
  DownloadState state;
  double progress;
  String? filePath;
  String? error;

  DownloadTask({
    required this.musicId,
    required this.title,
    required this.artist,
    this.artworkUrl,
    required this.url,
    this.pluginId,
    this.state = DownloadState.idle,
    this.progress = 0,
    this.filePath,
    this.error,
  });
}

/// Service for downloading music from plugins.
class DownloadService {
  final List<DownloadTask> _tasks = [];

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);

  DownloadService();

  /// Request a download URL from a plugin and start downloading.
  Future<DownloadResult?> download({
    required MusicSourcePlugin plugin,
    required PluginMusicItem item,
    String quality = 'standard',
  }) async {
    final task = DownloadTask(
      musicId: item.id,
      title: item.title,
      artist: item.artist,
      artworkUrl: item.artwork,
      url: '',
      pluginId: plugin.pluginId,
      state: DownloadState.downloading,
    );
    _tasks.add(task);

    try {
      // Get the actual audio URL from the plugin
      final url = await plugin.getMediaSource(item.id, quality: quality);
      if (url == null || url.isEmpty) {
        task.state = DownloadState.failed;
        task.error = 'Failed to get media source';
        return DownloadResult(id: item.id, title: item.title, success: false, error: task.error);
      }

      task.url = url;

      // Determine file extension
      final ext = _getExtension(url);
      final dir = await getDownloadDirectory();
      final now = DateTime.now();
      final filename = '${item.title} - ${item.artist} ${now.millisecondsSinceEpoch}.$ext';
      final file = File('${dir.path}/$filename');

      // Download with progress tracking
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        final contentLength = response.contentLength;
        final fileSink = file.openWrite();
        int bytesReceived = 0;

        await for (final chunk in response) {
          fileSink.add(chunk);
          bytesReceived += chunk.length;
          if (contentLength > 0) {
            task.progress = bytesReceived / contentLength;
          }
        }

        await fileSink.flush();
        await fileSink.close();

        task.state = DownloadState.completed;
        task.filePath = file.path;
        task.progress = 1.0;

        return DownloadResult(
          id: item.id,
          title: item.title,
          filePath: file.path,
          success: true,
        );
      } catch (e) {
        task.state = DownloadState.failed;
        task.error = e.toString();
        return DownloadResult(id: item.id, title: item.title, success: false, error: e.toString());
      } finally {
        client.close();
      }
    } catch (e) {
      task.state = DownloadState.failed;
      task.error = e.toString();
      return DownloadResult(id: item.id, title: item.title, success: false, error: e.toString());
    }
  }

  /// Get the download directory path.
  Future<Directory> getDownloadDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${dir.path}/MusicFlow Downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }

  String _getExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final ext = path.split('.').last;
      if (['mp3', 'flac', 'wav', 'aac', 'ogg', 'm4a'].contains(ext.toLowerCase())) {
        return ext;
      }
    } catch (_) {}
    return 'mp3';
  }
}
