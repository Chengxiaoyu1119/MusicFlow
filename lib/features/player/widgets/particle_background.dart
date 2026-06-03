import 'dart:math';
import 'package:flutter/material.dart';

/// 粒子背景动效 — 类似 Namida 风格
/// 在播放器背景中生成缓慢浮动的发光粒子
class ParticleBackground extends StatefulWidget {
  final bool isActive;
  final Color color;

  const ParticleBackground({
    super.key,
    this.isActive = true,
    this.color = Colors.white,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _initParticles();
  }

  void _initParticles() {
    for (int i = 0; i < 12; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 1.5 + _random.nextDouble() * 3,
        speedX: (-0.2 + _random.nextDouble() * 0.4),
        speedY: (-0.15 + _random.nextDouble() * 0.3),
        opacity: 0.1 + _random.nextDouble() * 0.3,
      ));
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
        // Update particle positions
        for (final p in _particles) {
          p.x += p.speedX * 0.005;
          p.y += p.speedY * 0.005;
          // Wrap around
          if (p.x > 1) p.x = 0;
          if (p.x < 0) p.x = 1;
          if (p.y > 1) p.y = 0;
          if (p.y < 0) p.y = 1;
        }

        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(
            particles: _particles,
            color: widget.color,
            isActive: widget.isActive,
          ),
        );
      },
    );
  }
}

class _Particle {
  double x, y;
  final double size;
  final double speedX, speedY;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;
  final bool isActive;

  _ParticlePainter({
    required this.particles,
    required this.color,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fade = isActive ? 1.0 : 0.3;

    for (final p in particles) {
      final paint = Paint()
        ..color = color.withValues(alpha: p.opacity * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
