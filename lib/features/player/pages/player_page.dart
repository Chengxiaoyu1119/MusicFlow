import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../audio/audio_handler.dart';
import '../../../audio/audio_provider.dart';
import '../../../audio/lyrics_provider.dart';
import '../../../data/models/lyrics_model.dart';
import '../../../data/models/music.dart';
import '../../../data/repository/favorites_provider.dart';
import '../../../shared/widgets/music_tile.dart';
import '../widgets/lyrics_widget.dart';
import '../widgets/spectrum_widget.dart';
import '../widgets/glassmorphic_art.dart';
import '../widgets/player_gesture_handler.dart';
import '../widgets/desktop_lyrics_overlay.dart';
import '../services/sleep_timer_service.dart';

class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({super.key});

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage>
    with SingleTickerProviderStateMixin {
  bool _showLyrics = false;
  bool _showVolume = false;
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
  }

  void _updateRotation(bool isPlaying) {
    if (isPlaying) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final music = ref.watch(currentMusicProvider).valueOrNull;
    final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;
    // Sync rotation animation with playback state
    _updateRotation(isPlaying);
    final position = ref.watch(playerPositionProvider).valueOrNull ?? Duration.zero;
    final duration = ref.watch(playerDurationProvider).valueOrNull ?? Duration.zero;
    final repeatMode = ref.watch(repeatModeProvider).valueOrNull ?? 0;
    final isShuffle = ref.watch(shuffleModeProvider).valueOrNull ?? false;
    final queue = ref.watch(queueProvider);
    final lyricsAsync = ref.watch(lyricsProvider);
    final sleepTimer = ref.watch(sleepTimerProvider);
    final handler = ref.watch(audioHandlerProvider);
    final theme = Theme.of(context);

    if (music == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_note_outlined, size: 80,
                color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text('暂无播放', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      );
    }

    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      body: Stack(
        children: [
          // Glassmorphic background
          GlassmorphicArt(
            imageUrl: music.artworkUrl,
            blurSigma: 35,
            opacity: 0.25,
          ),

          // Foreground content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            onPressed: () => context.pop(),
                          ),
                          // Sleep timer indicator
                          if (sleepTimer.isActive)
                            GestureDetector(
                              onTap: () => ref.read(sleepTimerProvider.notifier).cancel(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.timer_rounded, size: 14,
                                      color: theme.colorScheme.onTertiaryContainer),
                                    const SizedBox(width: 4),
                                    Text(
                                      ref.read(sleepTimerProvider.notifier).formattedRemaining,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onTertiaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text('正在播放',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                      Row(
                        children: [
                          if (DesktopLyricsOverlay.isSupported)
                            IconButton(
                              icon: Icon(
                                _showLyrics ? Icons.lyrics_rounded : Icons.lyrics_outlined,
                                color: _showLyrics ? theme.colorScheme.primary : null,
                              ),
                              onPressed: () => setState(() => _showLyrics = !_showLyrics),
                              tooltip: '切换歌词',
                            ),
                          IconButton(
                            icon: Icon(
                              _showVolume ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                            ),
                            onPressed: () => setState(() => _showVolume = !_showVolume),
                            tooltip: '音量',
                          ),
                          IconButton(
                            icon: const Icon(Icons.queue_music_rounded),
                            onPressed: () => _showQueue(context, queue, handler),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main content with gesture handler
                Expanded(
                  child: PlayerGestureHandler(
                    onNext: () => handler.skipToNext(),
                    onPrevious: () => handler.skipToPrevious(),
                    onSeekForward: () =>
                      handler.seek(position + const Duration(seconds: 10)),
                    onSeekBackward: () =>
                      handler.seek(position - const Duration(seconds: 10)),
                    child: GestureDetector(
                      onTap: () => setState(() => _showLyrics = !_showLyrics),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _showLyrics
                            ? _buildLyricsView(music, position, lyricsAsync, handler)
                            : _buildArtView(music, theme),
                      ),
                    ),
                  ),
                ),

                // Spectrum
                SizedBox(
                  height: 32,
                  child: SpectrumWidget(
                    isPlaying: isPlaying,
                    barColor: theme.colorScheme.primary,
                    barCount: 48,
                  ),
                ),

                // Music info
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(music.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(music.artist,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Consumer(
                        builder: (context, watchRef, _) {
                          final favs = watchRef.watch(favoritesProvider);
                          final isFav = favs.contains(music.id);
                          return IconButton(
                            icon: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                              color: isFav ? theme.colorScheme.primary : null,
                            ),
                            onPressed: () => watchRef.read(favoritesProvider.notifier).toggle(music.id),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Progress bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                        ),
                        child: Slider(
                          value: progress,
                          onChanged: (v) {
                            final pos = Duration(
                              milliseconds: (v * duration.inMilliseconds).round());
                            handler.seek(pos);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_fmtDuration(position),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                            Text(_fmtDuration(duration),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.shuffle_rounded,
                          color: isShuffle ? theme.colorScheme.primary : null),
                        onPressed: () => handler.toggleShuffle(), iconSize: 24),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded),
                        iconSize: 36, onPressed: handler.skipToPrevious),
                      const SizedBox(width: 4),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: theme.colorScheme.onPrimary),
                          iconSize: 40,
                          onPressed: () => handler.togglePlayPause(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        iconSize: 36, onPressed: () => handler.skipToNext()),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(_repeatIcon(repeatMode),
                          color: repeatMode > 0 ? theme.colorScheme.primary : null),
                        onPressed: () => handler.cycleRepeatMode(), iconSize: 24),
                    ],
                  ),
                ),

                // Volume slider (expandable)
                if (_showVolume)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Row(
                      children: [
                        Icon(Icons.volume_down_rounded, size: 16,
                          color: theme.colorScheme.onSurfaceVariant),
                        Expanded(
                          child: Slider(
                            value: handler.volume,
                            onChanged: (v) => handler.setVolume(v),
                          ),
                        ),
                        Icon(Icons.volume_up_rounded, size: 16,
                          color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtView(Music music, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: RotationTransition(
          turns: _rotationController,
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: music.artworkUrl != null
                  ? CachedNetworkImage(
                      imageUrl: music.artworkUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _placeholderArt(theme),
                      errorWidget: (_, __, ___) => _placeholderArt(theme),
                    )
                  : _placeholderArt(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLyricsView(
    Music music,
    Duration position,
    AsyncValue<Lyrics?> lyricsAsync,
    MusicAudioHandler handler,
  ) {
    return lyricsAsync.when(
      data: (lyrics) {
        if (lyrics == null || lyrics.isEmpty) {
          // Fall back to album art in lyrics mode if no lyrics
          return _buildArtView(music, Theme.of(context));
        }
        return LyricsWidget(
          key: ValueKey(music.id),
          lyrics: lyrics,
          position: position,
          onSeek: (pos) => handler.seek(pos),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildArtView(music, Theme.of(context)),
    );
  }

  Widget _placeholderArt(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Icon(Icons.music_note_rounded, size: 80,
        color: theme.colorScheme.onPrimaryContainer),
    );
  }

  IconData _repeatIcon(int mode) {
    return switch (mode) { 1 => Icons.repeat_rounded, 2 => Icons.repeat_one_rounded, _ => Icons.repeat_rounded };
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _showQueue(BuildContext context, List<Music> queue, MusicAudioHandler handler) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('即将播放 (${queue.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () => handler.clearQueue(),
                    child: const Text('清空')),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: queue.length,
                itemBuilder: (context, index) {
                  final music = queue[index];
                  final isCurrent = index == handler.currentIndex;
                  return MusicTile(
                    music: music,
                    onTap: () => handler.setQueue(queue, startIndex: index),
                    trailing: isCurrent
                        ? Icon(Icons.play_arrow_rounded,
                            color: Theme.of(context).colorScheme.primary)
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => handler.removeFromQueue(index)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
