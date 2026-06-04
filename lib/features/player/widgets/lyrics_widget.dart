import 'package:flutter/material.dart';

import '../../../data/models/lyrics_model.dart';

/// Karaoke 风格滚动歌词 — 逐行高亮 + 当前行逐字染色（类似网易云音乐）
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
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.lyrics_outlined, size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text('暂无歌词', style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant)),
        ]),
      );
    }

    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
        stops: const [0.0, 0.1, 0.9, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height / 2 - 28),
        itemCount: widget.lyrics.lines.length,
        itemBuilder: (context, index) {
          final line = widget.lyrics.lines[index];
          final isCurrent = index == _currentLineIndex;
          final progress = isCurrent
              ? widget.lyrics.getLineProgress(widget.position)
              : 0.0;

          return GestureDetector(
            onTap: () => widget.onSeek?.call(line.timestamp),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: isCurrent
                  ? _KaraokeText(
                      text: line.text,
                      progress: progress,
                      activeColor: theme.colorScheme.primary,
                      defaultColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 20,
                    )
                  : Text(
                      line.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        height: 1.5,
                      ),
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

/// Karaoke 逐字染色组件 — 从左到右渐变颜色
class _KaraokeText extends StatelessWidget {
  final String text;
  final double progress;
  final Color activeColor;
  final Color defaultColor;
  final double fontSize;

  const _KaraokeText({
    required this.text,
    required this.progress,
    required this.activeColor,
    required this.defaultColor,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [
            activeColor,
            activeColor,
            defaultColor,
            defaultColor,
          ],
          stops: [0.0, progress, progress + 0.01, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white, // ShaderMask will override this
          height: 1.5,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
