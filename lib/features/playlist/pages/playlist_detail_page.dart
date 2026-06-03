import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../audio/audio_provider.dart';
import '../../../data/database/hive_service.dart';
import '../../../data/models/music.dart';
import '../../../data/repository/library_service.dart';
import '../../../shared/widgets/music_tile.dart';

class PlaylistDetailPage extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailPage({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(hiveStorageProvider);
    final playlists = storage.loadPlaylists();
    final playlist = playlists.where((p) => p.id == playlistId).firstOrNull;
    final localMusic = ref.watch(libraryServiceProvider).localMusic;

    // Resolve music IDs to Music objects
    final tracks = playlist?.musicIds
        .map((id) => localMusic.where((m) => m.id == id).firstOrNull)
        .whereType<Music>()
        .toList() ?? [];

    if (playlist == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Playlist')),
        body: const Center(child: Text('Playlist not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          if (tracks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_arrow_rounded),
              onPressed: () {
                final handler = ref.read(audioHandlerProvider);
                handler.setQueue(tracks);
              },
            ),
        ],
      ),
      body: tracks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.playlist_add_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This playlist is empty',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add songs from your library',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final music = tracks[index];
                return MusicTile(
                  music: music,
                  onTap: () {
                    final handler = ref.read(audioHandlerProvider);
                    handler.setQueue(tracks, startIndex: index);
                  },
                );
              },
            ),
    );
  }
}
