import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../audio/audio_provider.dart';
import '../../data/models/music.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final music = ref.watch(currentMusicProvider).valueOrNull;
    final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;
    final position = ref.watch(playerPositionProvider).valueOrNull ?? Duration.zero;
    final duration = ref.watch(playerDurationProvider).valueOrNull ?? Duration.zero;
    final handler = ref.watch(audioHandlerProvider);

    if (music == null) return const SizedBox.shrink();

    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: () => context.push('/player'),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              color: Theme.of(context).colorScheme.primary,
              minHeight: 2,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    // Album art
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: _ArtworkImage(music: music),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Track info
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            music.title,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            music.artist,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Controls
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 28,
                      ),
                      onPressed: () => handler.togglePlayPause(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, size: 28),
                      onPressed: () => handler.skipToNext(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtworkImage extends StatelessWidget {
  final Music music;

  const _ArtworkImage({required this.music});

  @override
  Widget build(BuildContext context) {
    if (music.artworkUrl != null) {
      return CachedNetworkImage(
        imageUrl: music.artworkUrl!,
        placeholder: (_, __) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        errorWidget: (_, __, ___) => _placeholder(context),
        fit: BoxFit.cover,
      );
    }
    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(
        Icons.music_note_rounded,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        size: 24,
      ),
    );
  }
}
