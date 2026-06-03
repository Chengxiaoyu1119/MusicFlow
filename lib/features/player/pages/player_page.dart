import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../../audio/audio_handler.dart';
import '../../../audio/audio_provider.dart';
import '../../../audio/lyrics_provider.dart';
import '../../../data/models/lyrics_model.dart';
import '../../../data/models/music.dart';
import '../../../data/repository/favorites_provider.dart';
import '../../../shared/widgets/music_tile.dart';
import '../widgets/lyrics_widget.dart';
import '../widgets/spectrum_widget.dart';
import '../widgets/player_gesture_handler.dart';
import '../widgets/desktop_lyrics_overlay.dart';
import '../widgets/particle_background.dart';
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
  Color _dominantColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this, duration: const Duration(seconds: 8),
    );
  }

  void _updateRotation(bool isPlaying) {
    if (isPlaying) _rotationController.repeat();
    else _rotationController.stop();
  }

  Future<void> _extractColors(String? imageUrl) async {
    if (imageUrl == null) return;
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(imageUrl),
        maximumColorCount: 5,
      );
      if (!mounted) return;
      setState(() {
        _dominantColor = palette.dominantColor?.color ?? Colors.black;
      });
    } catch (_) {}
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

    // Extract colors when music changes
    if (music != null) _extractColors(music.artworkUrl);

    if (music == null) {
      return Scaffold(body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.music_note_outlined, size: 96,
            color: theme.colorScheme.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 24),
          Text('暂无播放', style: theme.textTheme.titleLarge),
        ]),
      ));
    }

    final isWide = MediaQuery.of(context).size.width > 800;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      body: Stack(
        children: [
          // Particle effects background
          Positioned.fill(
            child: ParticleBackground(
              isActive: isPlaying,
              color: _dominantColor,
            ),
          ),
          // Main gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _dominantColor.withValues(alpha: 0.6),
                    theme.colorScheme.surface,
                    theme.colorScheme.surface,
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
          child: isWide ? _buildWideLayout(music, theme, isPlaying, position,
              duration, repeatMode, isShuffle, progress, handler, lyricsAsync)
              : _buildNarrowLayout(music, theme, isPlaying, position, duration,
              repeatMode, isShuffle, progress, handler, lyricsAsync, sleepTimer, queue),
        ),
      ]),
    );
  }

  // ==================== 宽屏布局（平板/桌面） ====================
  Widget _buildWideLayout(Music music, ThemeData theme, bool isPlaying,
      Duration position, Duration duration, int repeatMode, bool isShuffle,
      double progress, MusicAudioHandler handler, AsyncValue<Lyrics?> lyricsAsync) {
    return Row(
      children: [
        // Left: Album art + controls
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAlbumArt(music, theme, isPlaying),
              const SizedBox(height: 32),
              _buildControls(theme, isPlaying, isShuffle, repeatMode, handler),
              const SizedBox(height: 16),
              _buildProgressBar(theme, progress, position, duration, handler),
            ],
          ),
        ),
        // Right: Lyrics or info
        Expanded(
          child: _buildLyricsView(music, position, lyricsAsync, handler),
        ),
      ],
    );
  }

  // ==================== 窄屏布局（手机） ====================
  Widget _buildNarrowLayout(Music music, ThemeData theme, bool isPlaying,
      Duration position, Duration duration, int repeatMode, bool isShuffle,
      double progress, MusicAudioHandler handler, AsyncValue<Lyrics?> lyricsAsync,
      SleepTimerState sleepTimer, List<Music> queue) {
    return Column(
      children: [
        // Top bar
        Padding(
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
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.timer_rounded, size: 14,
                        color: theme.colorScheme.onTertiaryContainer),
                      const SizedBox(width: 4),
                      Text(ref.read(sleepTimerProvider.notifier).formattedRemaining,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              const Spacer(),
              Text('正在播放',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
              const Spacer(),
              if (DesktopLyricsOverlay.isSupported)
                IconButton(
                  icon: Icon(_showLyrics ? Icons.lyrics_rounded : Icons.lyrics_outlined,
                    color: _showLyrics ? theme.colorScheme.primary : null),
                  onPressed: () => setState(() => _showLyrics = !_showLyrics),
                ),
              IconButton(
                icon: const Icon(Icons.queue_music_rounded),
                onPressed: () => _showQueue(context, queue, handler),
              ),
            ],
          ),
        ),

        // Album art + Lyrics toggle
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
                    : _buildAlbumArt(music, theme, isPlaying),
              ),
            ),
          ),
        ),

        // Spectrum
        SizedBox(
          height: 24,
          child: SpectrumWidget(isPlaying: isPlaying,
            barColor: theme.colorScheme.primary, barCount: 36),
        ),

        // Music info
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
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
                        color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
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
                      color: isFav ? theme.colorScheme.error : null,
                    ),
                    onPressed: () => watchRef.read(favoritesProvider.notifier).toggle(music.id),
                  );
                },
              ),
            ],
          ),
        ),

        // Progress + Controls
        _buildProgressBar(theme, progress, position, duration, handler),
        _buildControls(theme, isPlaying, isShuffle, repeatMode, handler),
        const SizedBox(height: 8),
      ],
    );
  }

  // ==================== Album Art ====================
  Widget _buildAlbumArt(Music music, ThemeData theme, bool isPlaying) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _dominantColor.withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: RotationTransition(
            turns: _rotationController,
            child: ClipOval(
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

  // ==================== Controls ====================
  Widget _buildControls(ThemeData theme, bool isPlaying, bool isShuffle,
      int repeatMode, MusicAudioHandler handler) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SmallCtrlBtn(
            icon: Icons.shuffle_rounded,
            isActive: isShuffle,
            onTap: () => handler.toggleShuffle(),
          ),
          _SmallCtrlBtn(
            icon: Icons.skip_previous_rounded,
            size: 30,
            onTap: handler.skipToPrevious,
          ),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 16,
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
          _SmallCtrlBtn(
            icon: Icons.skip_next_rounded,
            size: 30,
            onTap: () => handler.skipToNext(),
          ),
          _SmallCtrlBtn(
            icon: repeatMode == 1 ? Icons.repeat_rounded :
                repeatMode == 2 ? Icons.repeat_one_rounded : Icons.repeat_rounded,
            isActive: repeatMode > 0,
            onTap: () => handler.cycleRepeatMode(),
          ),
        ],
      ),
    );
  }

  // ==================== Progress Bar ====================
  Widget _buildProgressBar(ThemeData theme, double progress,
      Duration position, Duration duration, MusicAudioHandler handler) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
              thumbColor: theme.colorScheme.primary,
            ),
            child: Slider(
              value: progress,
              onChanged: (v) {
                final pos = Duration(milliseconds: (v * duration.inMilliseconds).round());
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
                Text(_fmtDuration(duration),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsView(Music music, Duration position,
      AsyncValue<Lyrics?> lyricsAsync, MusicAudioHandler handler) {
    return lyricsAsync.when(
      data: (lyrics) {
        if (lyrics == null || lyrics.isEmpty) return _buildAlbumArt(music, Theme.of(context), false);
        return LyricsWidget(
          key: ValueKey(music.id),
          lyrics: lyrics,
          position: position,
          onSeek: (pos) => handler.seek(pos),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildAlbumArt(music, Theme.of(context), false),
    );
  }

  Widget _placeholderArt(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.music_note_rounded, size: 72,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
    );
  }

  String _fmtDuration(Duration d) {
    if (d.isNegative) return '0:00';
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ==================== 播放队列 ====================
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        var items = List<Music>.from(queue);
        return DraggableScrollableSheet(
          initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Column(children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(children: [
                  Text('播放队列 (${items.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                    label: const Text('清空'),
                    onPressed: () { handler.clearQueue(); Navigator.pop(context); },
                  ),
                ]),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final music = items[index];
                    final isCurrent = index == handler.currentIndex;
                    return Dismissible(
                      key: ValueKey('q_${music.id}_$index'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Icon(Icons.delete_outline_rounded,
                          color: Theme.of(context).colorScheme.error),
                      ),
                      onDismissed: (_) => handler.removeFromQueue(index),
                      child: MusicTile(music: music,
                        onTap: () { handler.setQueue(items, startIndex: index); Navigator.pop(context); },
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
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
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ]);
          },
        );
      },
    );
  }
}

// ==================== 小控件按钮 ====================
class _SmallCtrlBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool isActive;
  final VoidCallback onTap;

  const _SmallCtrlBtn({
    required this.icon,
    this.size = 22,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.6)
            : Colors.transparent,
      ),
      child: IconButton(
        icon: Icon(icon,
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          size: size),
        onPressed: onTap,
      ),
    );
  }
}
