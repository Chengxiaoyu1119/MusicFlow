import 'dart:math';
import 'package:flutter/material.dart';

/// 粒子背景 — 纯 Flutter CustomPainter，无外部依赖
class ParticleBg extends StatefulWidget {
  final Color color;
  final bool isActive;

  const ParticleBg({super.key, this.color = Colors.white, this.isActive = true});

  @override
  State<ParticleBg> createState() => _ParticleBgState();
}

class _ParticleBgState extends State<ParticleBg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Dot> _dots = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, duration: const Duration(seconds: 8),
    )..repeat();
    final rng = Random(42);
    for (int i = 0; i < 15; i++) {
      _dots.add(_Dot(
        x: rng.nextDouble(), y: rng.nextDouble(),
        size: 1.0 + rng.nextDouble() * 2.5,
        speedX: -0.3 + rng.nextDouble() * 0.6,
        speedY: -0.2 + rng.nextDouble() * 0.4,
        opacity: 0.05 + rng.nextDouble() * 0.15,
      ));
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        for (final d in _dots) {
          d.x += d.speedX * 0.003;
          d.y += d.speedY * 0.003;
          if (d.x > 1) d.x = 0;
          if (d.x < 0) d.x = 1;
          if (d.y > 1) d.y = 0;
          if (d.y < 0) d.y = 1;
        }
        return CustomPaint(
          painter: _ParticlePainter(
            dots: _dots, color: widget.color, isActive: widget.isActive),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Dot {
  double x, y; final double size, speedX, speedY, opacity;
  _Dot({required this.x, required this.y, required this.size,
    required this.speedX, required this.speedY, required this.opacity});
}

class _ParticlePainter extends CustomPainter {
  final List<_Dot> dots; final Color color; final bool isActive;
  _ParticlePainter({required this.dots, required this.color, required this.isActive});
  @override
  void paint(Canvas canvas, Size size) {
    final fade = isActive ? 1.0 : 0.3;
    for (final d in dots) {
      final paint = Paint()
        ..color = color.withValues(alpha: d.opacity * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(d.x * size.width, d.y * size.height), d.size, paint);
    }
  }
  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}
