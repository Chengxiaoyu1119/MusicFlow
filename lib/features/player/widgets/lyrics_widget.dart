import 'package:flutter/material.dart';

import '../../../data/models/lyrics_model.dart';

/// Synced, scrollable lyrics display.
///
/// Highlights the current line, auto-scrolls to center it,
/// and supports tap-to-seek.
class LyricsWidget extends StatefulWidget {
  final Lyrics lyrics;
  final Duration position;
  final ValueChanged<Duration>? onSeek;

  const LyricsWidget({
    super.key,
    required this.lyrics,
    required this.position,
    this.onSeek,
  });

  @override
  State<LyricsWidget> createState() => _LyricsWidgetState();
}

class _LyricsWidgetState extends State<LyricsWidget> {
  final ScrollController _scrollController = ScrollController();
  int _currentLineIndex = -1;

  @override
  void didUpdateWidget(LyricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIndex = widget.lyrics.getLineIndex(widget.position);

    if (newIndex != _currentLineIndex && newIndex >= 0) {
      _currentLineIndex = newIndex;
      _scrollToLine(newIndex);
    }
  }

  void _scrollToLine(int index) {
    if (!_scrollController.hasClients) return;

    final offset = (index * 56.0) - (context.size?.height ?? 400) / 2 + 28;
    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.lyrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lyrics_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No lyrics available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.white,
          Colors.white,
          Colors.white,
          Colors.transparent,
        ],
        stops: const [0.0, 0.1, 0.4, 0.9, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height / 2 - 28,
        ),
        itemCount: widget.lyrics.lines.length,
        itemBuilder: (context, index) {
          final line = widget.lyrics.lines[index];
          final isCurrent = index == _currentLineIndex;

          return GestureDetector(
            onTap: () => widget.onSeek?.call(line.timestamp),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isCurrent ? 20 : 14,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  height: 1.5,
                ),
                child: Text(
                  line.text,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
