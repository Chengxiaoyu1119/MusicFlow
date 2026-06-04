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
import '../widgets/player_gesture_handler.dart';
import '../widgets/desktop_lyrics_overlay.dart';
import '../widgets/vinyl_disc.dart';
import '../widgets/stylus_needle.dart';
import '../widgets/particle_bg.dart';
import '../services/sleep_timer_service.dart';

class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({super.key});

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  bool _showLyrics = false;
  bool _showVolume = false;
  Color _dominantColor = Colors.black;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _extractColors(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
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
  Widget build(BuildContext context) {
    final music = ref.watch(currentMusicProvider).valueOrNull;
    final isPlaying = ref.watch(isPlayingProvider).valueOrNull ?? false;
    final position = ref.watch(playerPositionProvider).valueOrNull ?? Duration.zero;
    final duration = ref.watch(playerDurationProvider).valueOrNull ?? Duration.zero;
    final repeatMode = ref.watch(repeatModeProvider).valueOrNull ?? 0;
    final isShuffle = ref.watch(shuffleModeProvider).valueOrNull ?? false;
    final queue = ref.watch(queueProvider);
    final lyricsAsync = ref.watch(lyricsProvider);
    final sleepTimer = ref.watch(sleepTimerProvider);
    final handler = ref.watch(audioHandlerProvider);
    final theme = Theme.of(context);

    if (music != null) _extractColors(music.artworkUrl);

    if (music == null) {
      return Scaffold(body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: Icon(Icons.music_note_outlined, size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 24),
          Text('暂无播放', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ]),
      ));
    }

    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0) : 0.0;
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Stack(
        children: [
          // Particle effects
          Positioned.fill(
            child: ParticleBg(
              color: _dominantColor,
              isActive: isPlaying,
            ),
          ),
          // Dynamic gradient background
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _dominantColor.withValues(alpha: 0.5),
                    theme.colorScheme.surface,
                    theme.colorScheme.surface,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: isWide
                ? _buildWideLayout(music, theme, isPlaying, position, duration,
                    repeatMode, isShuffle, progress, handler, lyricsAsync, queue)
                : _buildNarrowLayout(music, theme, isPlaying, position, duration,
                    repeatMode, isShuffle, progress, handler, lyricsAsync,
                    sleepTimer, queue, isPlaying),
          ),
        ],
      ),
    );
  }

  // ==================== 窄屏（手机） ====================
  Widget _buildNarrowLayout(Music music, ThemeData theme, bool isPlaying,
      Duration position, Duration duration, int repeatMode, bool isShuffle,
      double progress, MusicAudioHandler handler, AsyncValue<Lyrics?> lyricsAsync,
      SleepTimerState sleepTimer, List<Music> queue, bool animActive) {
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
                icon: Icon(_showVolume ? Icons.volume_up_rounded : Icons.volume_down_rounded),
                onPressed: () => setState(() => _showVolume = !_showVolume),
              ),
              IconButton(
                icon: const Icon(Icons.queue_music_rounded),
                onPressed: () => _showQueue(context, queue, handler),
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
                    child: Text(
                      ref.read(sleepTimerProvider.notifier).formattedRemaining,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Main content
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

        // Music info
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(music.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold, letterSpacing: -0.5),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(music.artist,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(width: 8),
                        if (music.album.isNotEmpty)
                          Text('· ${music.album}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
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

        // Volume slider
        if (_showVolume)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
            child: Row(
              children: [
                Icon(Icons.volume_down_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                Expanded(
                  child: Slider(
                    value: handler.volume,
                    onChanged: (v) => handler.setVolume(v),
                  ),
                ),
                Icon(Icons.volume_up_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),

        // Progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
                    color: theme.colorScheme.onPrimary, fontSize: 11),
                ),
                child: Slider(
                  value: progress,
                  onChanged: (v) {
                    handler.seek(Duration(
                      milliseconds: (v * duration.inMilliseconds).round()));
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
                        color: theme.colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500)),
                    Text(_fmtDuration(duration),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Controls
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniCtrlBtn(
                icon: Icons.shuffle_rounded,
                isActive: isShuffle,
                onTap: () => handler.toggleShuffle(),
              ),
              _RoundBtn(
                icon: Icons.skip_previous_rounded,
                size: 28,
                bgColor: theme.colorScheme.surfaceContainerHighest,
                onTap: handler.skipToPrevious,
              ),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
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
              _RoundBtn(
                icon: Icons.skip_next_rounded,
                size: 28,
                bgColor: theme.colorScheme.surfaceContainerHighest,
                onTap: () => handler.skipToNext(),
              ),
              _MiniCtrlBtn(
                icon: repeatMode == 1 ? Icons.repeat_rounded :
                    repeatMode == 2 ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                isActive: repeatMode > 0,
                onTap: () => handler.cycleRepeatMode(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ==================== 宽屏布局 ====================
  Widget _buildWideLayout(Music music, ThemeData theme, bool isPlaying,
      Duration position, Duration duration, int repeatMode, bool isShuffle,
      double progress, MusicAudioHandler handler, AsyncValue<Lyrics?> lyricsAsync,
      List<Music> queue) {
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAlbumArt(music, theme, isPlaying),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(children: [
                  Text(music.title,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(music.artist,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary)),
                ]),
              ),
              const SizedBox(height: 24),
              _buildProgressSection(theme, progress, position, duration, handler),
              const SizedBox(height: 16),
              _buildControlsRow(theme, isPlaying, isShuffle, repeatMode, handler),
            ],
          ),
        ),
        Expanded(
          child: _buildLyricsView(music, position, lyricsAsync, handler),
        ),
      ],
    );
  }

  // ==================== Album Art (Vinyl + Stylus) ====================
  Widget _buildAlbumArt(Music music, ThemeData theme, bool isPlaying) {
    final screenW = MediaQuery.of(context).size.width;
    final discSize = screenW > 800 ? 320.0 : (screenW - 80).clamp(200.0, 320.0);

    return Center(
      child: SizedBox(
        width: discSize,
        height: discSize,
        child: Stack(
          children: [
            VinylDisc(
              size: discSize,
              isPlaying: isPlaying,
              vinylColor: _dominantColor,
              albumArt: ClipOval(
                child: music.artworkUrl != null
                    ? CachedNetworkImage(
                        imageUrl: music.artworkUrl!, fit: BoxFit.cover,
                        placeholder: (_, __) => _placeholderArt(theme),
                        errorWidget: (_, __, ___) => _placeholderArt(theme),
                      )
                    : _placeholderArt(theme),
              ),
            ),
            // Stylus needle overlay
            StylusNeedle(
              isPlaying: isPlaying,
              size: discSize,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Progress ====================
  Widget _buildProgressSection(ThemeData theme, double progress,
      Duration position, Duration duration, MusicAudioHandler handler) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(children: [
        SliderTheme(data: SliderTheme.of(context).copyWith(
          trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
          activeTrackColor: theme.colorScheme.primary,
          inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
          thumbColor: theme.colorScheme.primary,
        ), child: Slider(value: progress, onChanged: (v) => handler.seek(
          Duration(milliseconds: (v * duration.inMilliseconds).round())))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(_fmtDuration(position), style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
            Text(_fmtDuration(duration), style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  // ==================== Controls ====================
  Widget _buildControlsRow(ThemeData theme, bool isPlaying, bool isShuffle,
      int repeatMode, MusicAudioHandler handler) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _MiniCtrlBtn(icon: Icons.shuffle_rounded, isActive: isShuffle, onTap: () => handler.toggleShuffle()),
        _RoundBtn(icon: Icons.skip_previous_rounded, size: 28, bgColor: theme.colorScheme.surfaceContainerHighest, onTap: handler.skipToPrevious),
        Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)]), boxShadow: [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
          child: IconButton(icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: theme.colorScheme.onPrimary), iconSize: 32, onPressed: () => handler.togglePlayPause())),
        _RoundBtn(icon: Icons.skip_next_rounded, size: 28, bgColor: theme.colorScheme.surfaceContainerHighest, onTap: () => handler.skipToNext()),
        _MiniCtrlBtn(icon: repeatMode == 1 ? Icons.repeat_rounded : repeatMode == 2 ? Icons.repeat_one_rounded : Icons.repeat_rounded, isActive: repeatMode > 0, onTap: () => handler.cycleRepeatMode()),
      ]),
    );
  }

  // ==================== Lyrics ====================
  Widget _buildLyricsView(Music music, Duration position,
      AsyncValue<Lyrics?> lyricsAsync, MusicAudioHandler handler) {
    return lyricsAsync.when(
      data: (lyrics) {
        if (lyrics == null || lyrics.isEmpty) {
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lyrics_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Text('暂无歌词', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ));
        }
        return LyricsWidget(
          key: ValueKey(music.id), lyrics: lyrics, position: position,
          onSeek: (pos) => handler.seek(pos),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => _buildAlbumArt(music, Theme.of(context), false),
    );
  }

  Widget _placeholderArt(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.music_note_rounded, size: 72,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
    );
  }

  String _fmtDuration(Duration d) {
    if (d.isNegative) return '0:00';
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ==================== 队列 ====================
  void _showQueue(BuildContext context, List<Music> queue, MusicAudioHandler handler) {
    if (queue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('播放列表为空')));
      return;
    }
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        var items = List<Music>.from(queue);
        return DraggableScrollableSheet(
          initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.3, expand: false,
          builder: (context, scrollController) => Column(children: [
            Container(margin: const EdgeInsets.only(top: 8), width: 36, height: 4,
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2))),
            Padding(padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(children: [
                Text('播放队列 (${items.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                  label: const Text('清空'), onPressed: () { handler.clearQueue(); Navigator.pop(context); }),
              ])),
            Expanded(child: ListView.builder(controller: scrollController,
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final m = items[index];
                final isCurrent = index == handler.currentIndex;
                return Dismissible(
                  key: ValueKey('q_${m.id}_$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error)),
                  onDismissed: (_) => handler.removeFromQueue(index),
                  child: MusicTile(music: m,
                    onTap: () { handler.setQueue(items, startIndex: index); Navigator.pop(context); },
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (isCurrent) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
                        child: Text('正在播放', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onPrimaryContainer))),
                      IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => handler.removeFromQueue(index)),
                    ]),
                  ),
                );
              },
            )),
          ]),
        );
      },
    );
  }
}

// ==================== 小控件 ====================
class _MiniCtrlBtn extends StatelessWidget {
  final IconData icon; final bool isActive; final VoidCallback onTap;
  const _MiniCtrlBtn({required this.icon, this.isActive = false, required this.onTap});
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(shape: BoxShape.circle,
        color: isActive ? theme.colorScheme.primaryContainer : Colors.transparent),
      child: IconButton(icon: Icon(icon, color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant, size: 20), onPressed: onTap));
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon; final double size; final Color bgColor; final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.size, required this.bgColor, required this.onTap});
  @override Widget build(BuildContext context) {
    return Container(decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
      child: IconButton(icon: Icon(icon, color: Theme.of(context).colorScheme.onSurface), iconSize: size, onPressed: onTap));
  }
}
