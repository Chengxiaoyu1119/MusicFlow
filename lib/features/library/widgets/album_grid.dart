import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../audio/audio_provider.dart';
import '../../../data/models/music.dart';
import '../../../data/repository/library_service.dart';

/// Browse music grouped by album in a grid view.
class AlbumGrid extends ConsumerWidget {
  const AlbumGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localMusic = ref.watch(libraryServiceProvider).localMusic;
    final theme = Theme.of(context);

    // Group by album
    final albums = <String, List<Music>>{};
    for (final music in localMusic) {
      final key = music.album.isNotEmpty ? music.album : 'Unknown Album';
      albums.putIfAbsent(key, () => []);
      albums[key]!.add(music);
    }

    final albumEntries = albums.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    if (albumEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.album_rounded, size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('暂无专辑', style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: albumEntries.length,
      itemBuilder: (context, index) {
        final entry = albumEntries[index];
        final firstTrack = entry.value.first;
        final trackCount = entry.value.length;

        return GestureDetector(
          onTap: () {
            final handler = ref.read(audioHandlerProvider);
            handler.setQueue(entry.value);
          },
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: firstTrack.artworkUrl != null
                        ? CachedNetworkImage(
                            imageUrl: firstTrack.artworkUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorWidget: (_, __, ___) => _placeholderAlbum(theme),
                          )
                        : _placeholderAlbum(theme),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600)),
                      Text('${trackCount} tracks · ${firstTrack.artist}',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _placeholderAlbum(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Icon(Icons.album_rounded, size: 48,
          color: theme.colorScheme.onPrimaryContainer),
      ),
    );
  }
}
