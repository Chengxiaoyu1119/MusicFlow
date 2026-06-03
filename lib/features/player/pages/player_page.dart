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
      return Scaffold(body: _buildEmptyState(theme));
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

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(theme, music, handler, sleepTimer, queue, lyricsAsync),
                Expanded(
                  child: PlayerGestureHandler(
                    onNext: handler.skipToNext,
                    onPrevious: handler.skipToPrevious,
                    onSeekForward: () => handler.seek(position + const Duration(seconds: 10)),
                    onSeekBackward: () => handler.seek(position - const Duration(seconds: 10)),
                    child: GestureDetector(
                      onTap: () => setState(() => _showLyrics = !_showLyrics),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _showLyrics
                            ? _buildLyricsView(music, position, lyricsAsync, handler)
                            : _buildArtView(music, theme, isPlaying),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Spectrum
                SizedBox(
                  height: 28,
                  child: SpectrumWidget(
                    isPlaying: isPlaying,
                    barColor: theme.colorScheme.primary,
                    barCount: 48,
                  ),
                ),
                // Music info + Volume
                _buildMusicInfo(theme, music),
                // Progress bar
                _buildProgressBar(theme, progress, position, duration, handler),
                // Controls
                _buildControls(theme, isPlaying, isShuffle, repeatMode, handler),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: Icon(Icons.music_note_outlined, size: 56,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 24),
          Text('暂无播放', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('从音乐库选择歌曲开始播放',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, Music music, MusicAudioHandler handler,
      SleepTimerState sleepTimer, List<Music> queue, AsyncValue<Lyrics?> lyricsAsync) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            onPressed: () => context.pop(),
          ),
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
                    Text(ref.read(sleepTimerProvider.notifier).formattedRemaining,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          const Spacer(),
          Text('正在播放',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant)),
          const Spacer(),
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
            icon: const Icon(Icons.queue_music_rounded),
            onPressed: () => _showQueue(context, queue, handler),
          ),
        ],
      ),
    );
  }

  Widget _buildArtView(Music music, ThemeData theme, bool isPlaying) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 56),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            if (music.artworkUrl != null)
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      blurRadius: 60,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            // Album art with rotation
            RotationTransition(
              turns: _rotationController,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: AspectRatio(
                    aspectRatio: 1,
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
            // Center icon overlay
            if (!isPlaying)
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.4),
                ),
                child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 36),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicInfo(ThemeData theme, Music music) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(music.title,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(music.artist,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                if (music.album.isNotEmpty)
                  Text(music.album,
                    style: theme.textTheme.bodySmall?.copyWith(
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
    );
  }

  Widget _buildProgressBar(ThemeData theme, double progress,
      Duration position, Duration duration, MusicAudioHandler handler) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
              thumbColor: theme.colorScheme.primary,
              valueIndicatorColor: theme.colorScheme.primary,
              valueIndicatorTextStyle: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 12,
              ),
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
                    color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
                Text('-${_fmtDuration(duration - position)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(ThemeData theme, bool isPlaying, bool isShuffle,
      int repeatMode, MusicAudioHandler handler) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(Icons.shuffle_rounded,
              color: isShuffle ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              size: 22),
            onPressed: () => handler.toggleShuffle(),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: IconButton(
              icon: Icon(Icons.skip_previous_rounded,
                color: theme.colorScheme.onSurface),
              iconSize: 32,
              onPressed: handler.skipToPrevious,
            ),
          ),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: theme.colorScheme.onPrimary),
              iconSize: 36,
              onPressed: () => handler.togglePlayPause(),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: IconButton(
              icon: Icon(Icons.skip_next_rounded,
                color: theme.colorScheme.onSurface),
              iconSize: 32,
              onPressed: () => handler.skipToNext(),
            ),
          ),
          IconButton(
            icon: Icon(
              repeatMode == 1 ? Icons.repeat_rounded :
                  repeatMode == 2 ? Icons.repeat_one_rounded : Icons.repeat_rounded,
              color: repeatMode > 0 ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              size: 22,
            ),
            onPressed: () => handler.cycleRepeatMode(),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsView(Music music, Duration position,
      AsyncValue<Lyrics?> lyricsAsync, MusicAudioHandler handler) {
    return lyricsAsync.when(
      data: (lyrics) {
        if (lyrics == null || lyrics.isEmpty) {
          return _buildArtView(music, Theme.of(context), false);
        }
        return LyricsWidget(
          key: ValueKey(music.id),
          lyrics: lyrics,
          position: position,
          onSeek: (pos) => handler.seek(pos),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildArtView(music, Theme.of(context), false),
    );
  }

  Widget _placeholderArt(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Icon(Icons.music_note_rounded, size: 80,
        color: theme.colorScheme.onPrimaryContainer),
    );
  }

  String _fmtDuration(Duration d) {
    if (d.isNegative) return '0:00';
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ==================== 队列管理 ====================

  void _showQueue(BuildContext context, List<Music> queue, MusicAudioHandler handler) {
    if (queue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('播放列表为空')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            var items = List<Music>.from(queue);
            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              maxChildSize: 0.9,
              minChildSize: 0.3,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                      child: Row(
                        children: [
                          Text('播放队列 (${items.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold)),
                          const Spacer(),
                          if (items.isNotEmpty)
                            TextButton.icon(
                              icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                              label: const Text('清空'),
                              onPressed: () {
                                handler.clearQueue();
                                Navigator.pop(context);
                              },
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: items.length,
                        onReorder: (oldIndex, newIndex) {
                          setSheetState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final item = items.removeAt(oldIndex);
                            items.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final music = items[index];
                          final isCurrent = index == handler.currentIndex;
                          return Dismissible(
                            key: ValueKey('queue_${music.id}_$index'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Theme.of(context).colorScheme.errorContainer,
                              child: Icon(Icons.delete_outline_rounded,
                                color: Theme.of(context).colorScheme.error),
                            ),
                            onDismissed: (_) => handler.removeFromQueue(index),
                            child: MusicTile(
                              music: music,
                              onTap: () {
                                handler.setQueue(items, startIndex: index);
                                Navigator.pop(context);
                              },
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isCurrent)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('正在播放',
                                        style: TextStyle(fontSize: 10,
                                          color: Theme.of(context).colorScheme.onPrimaryContainer)),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    onPressed: () => handler.removeFromQueue(index),
                                  ),
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Icon(Icons.drag_handle_rounded, size: 20),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
