import 'package:flutter/material.dart';

import '../../../core/constants/platform_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../audio/audio_provider.dart';
import '../../../audio/lyrics_provider.dart';
import '../../../data/models/lyrics_model.dart';

/// Desktop lyrics overlay that shows synced lyrics in a fullscreen window.
///
/// Designed for use as a separate route/page that can be triggered
/// from the player page or via keyboard shortcut.
class DesktopLyricsOverlay extends ConsumerWidget {
  const DesktopLyricsOverlay({super.key});

  static bool get isSupported =>
      PlatformHelper.isDesktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final music = ref.watch(currentMusicProvider).valueOrNull;
    final position = ref.watch(playerPositionProvider).valueOrNull ?? Duration.zero;
    final lyricsAsync = ref.watch(lyricsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: lyricsAsync.when(
          data: (lyrics) => lyrics != null && lyrics.lines.isNotEmpty
              ? _LyricsDisplay(
                  lyrics: lyrics,
                  position: position,
                  theme: theme,
                )
              : _NoLyrics(musicName: music?.title, theme: theme),
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => _NoLyrics(musicName: music?.title, theme: theme),
        ),
      ),
    );
  }
}

class _LyricsDisplay extends StatefulWidget {
  final Lyrics lyrics;
  final Duration position;
  final ThemeData theme;

  const _LyricsDisplay({
    required this.lyrics,
    required this.position,
    required this.theme,
  });

  @override
  State<_LyricsDisplay> createState() => _LyricsDisplayState();
}

class _LyricsDisplayState extends State<_LyricsDisplay> {
  final ScrollController _controller = ScrollController();
  int _currentIndex = -1;

  @override
  void didUpdateWidget(_LyricsDisplay old) {
    super.didUpdateWidget(old);
    final idx = widget.lyrics.getLineIndex(widget.position);
    if (idx != _currentIndex && idx >= 0) {
      _currentIndex = idx;
      _scrollTo(idx);
    }
  }

  void _scrollTo(int index) {
    if (!_controller.hasClients) return;
    final offset = (index * 64.0) - (context.size?.height ?? 600) / 2 + 32;
    _controller.animateTo(
      offset.clamp(0, _controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
        stops: const [0.0, 0.15, 0.85, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        controller: _controller,
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height / 2 - 32,
        ),
        itemCount: widget.lyrics.lines.length,
        itemBuilder: (context, index) {
          final line = widget.lyrics.lines[index];
          final isCurrent = index == _currentIndex;

          return AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: isCurrent ? 28 : 18,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent
                  ? widget.theme.colorScheme.primary
                  : widget.theme.colorScheme.onSurface.withValues(alpha: 0.4),
              height: 1.8,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
              child: Text(
                line.text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NoLyrics extends StatelessWidget {
  final String? musicName;
  final ThemeData theme;

  const _NoLyrics({this.musicName, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lyrics_outlined, size: 80,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
        const SizedBox(height: 24),
        if (musicName != null)
          Text(musicName!,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('No lyrics available',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
