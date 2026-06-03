import 'dart:math';

import 'package:flutter/material.dart';

/// Animated spectrum visualization widget.
///
/// Creates decorative animated bars that react to playback state.
class SpectrumWidget extends StatefulWidget {
  final bool isPlaying;
  final Color barColor;
  final int barCount;

  const SpectrumWidget({
    super.key,
    this.isPlaying = false,
    this.barColor = Colors.white,
    this.barCount = 32,
  });

  @override
  State<SpectrumWidget> createState() => _SpectrumWidgetState();
}

class _SpectrumWidgetState extends State<SpectrumWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<double> _barHeights = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    _initBarHeights();
  }

  void _initBarHeights() {
    _barHeights.clear();
    for (int i = 0; i < widget.barCount; i++) {
      _barHeights.add(_random.nextDouble());
    }
  }

  @override
  void didUpdateWidget(SpectrumWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.barCount != widget.barCount) {
      _initBarHeights();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update bar heights periodically
        for (int i = 0; i < widget.barCount; i++) {
          final target = widget.isPlaying
              ? (0.1 + _random.nextDouble() * 0.9)
              : 0.05 + sin(i * 0.5 + _controller.value * 2 * pi) * 0.05;

          _barHeights[i] += (target - _barHeights[i]) * 0.1;
        }

        return CustomPaint(
          size: Size.infinite,
          painter: _SpectrumPainter(
            barHeights: _barHeights,
            barColor: widget.barColor,
            barCount: widget.barCount,
          ),
        );
      },
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  final List<double> barHeights;
  final Color barColor;
  final int barCount;

  _SpectrumPainter({
    required this.barHeights,
    required this.barColor,
    required this.barCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (barHeights.isEmpty) return;

    final barWidth = size.width / barCount;
    final gap = barWidth * 0.2;
    final paint = Paint()
      ..color = barColor.withValues(alpha: 0.6)
      ..strokeWidth = barWidth - gap
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < barCount && i < barHeights.length; i++) {
      final x = i * barWidth + gap / 2;
      final height = barHeights[i] * size.height * 0.6;
      final y = size.height - height;

      paint.color = barColor.withValues(
        alpha: 0.3 + (0.5 * (1.0 - (i / barCount))),
      );

      canvas.drawLine(
        Offset(x, size.height),
        Offset(x, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SpectrumPainter oldDelegate) => true;
}
