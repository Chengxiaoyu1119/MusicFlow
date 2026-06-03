import 'dart:math' show sin, cos;
import 'package:flutter/material.dart';

/// 波形进度条 — 替代普通 Slider，显示音频波形可视化
class WaveformSeekbar extends StatelessWidget {
  final double progress;
  final double height;
  final int barCount;
  final ValueChanged<double>? onSeek;
  final Color? activeColor;
  final Color? inactiveColor;

  const WaveformSeekbar({
    super.key,
    required this.progress,
    this.height = 48,
    this.barCount = 60,
    this.onSeek,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) {
            if (onSeek != null) {
              onSeek!((details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0));
            }
          },
          onHorizontalDragUpdate: (details) {
            if (onSeek != null) {
              final pos = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
              onSeek!(pos);
            }
          },
          child: SizedBox(
            height: height,
            child: CustomPaint(
              size: Size(constraints.maxWidth, height),
              painter: _WaveformPainter(
                progress: progress,
                activeColor: activeColor ?? theme.colorScheme.primary,
                inactiveColor: inactiveColor ?? theme.colorScheme.surfaceContainerHighest,
                barCount: barCount,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final int barCount;

  _WaveformPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.barCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / barCount;
    final gap = barWidth * 0.25;

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + gap / 2;
      // Generate waveform-like heights using sin/cos
      final h = 0.15 + 0.85 * (0.5 + 0.5 * sin(i * 0.7 + 1.3) * cos(i * 0.3 + 0.7));
      final barH = h * size.height * 0.7;
      final isPlayed = i / barCount <= progress;

      final paint = Paint()
        ..color = isPlayed ? activeColor : inactiveColor.withValues(alpha: 0.4)
        ..strokeWidth = (barWidth - gap).clamp(1.5, 8.0)
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x, size.height / 2 + barH / 2),
        Offset(x, size.height / 2 - barH / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) => oldDelegate.progress != progress;
}
