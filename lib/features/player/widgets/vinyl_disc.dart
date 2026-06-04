import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 黑胶唱片背景 + 旋转封面组合
/// 类似 Apple Music 的播放界面
class VinylDisc extends StatefulWidget {
  final Widget? albumArt;
  final Color vinylColor;
  final bool isPlaying;
  final double size;

  const VinylDisc({
    super.key,
    this.albumArt,
    this.vinylColor = Colors.black,
    this.isPlaying = true,
    this.size = 280,
  });

  @override
  State<VinylDisc> createState() => _VinylDiscState();
}

class _VinylDiscState extends State<VinylDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _breathController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(VinylDisc old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !old.isPlaying) {
      _controller.repeat();
    } else if (!widget.isPlaying && old.isPlaying) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Start/stop rotation based on playing state
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _breathController]),
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2 + 0.1 * _breathController.value),
                blurRadius: 30 + 10 * _breathController.value,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Vinyl record background
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _VinylPainter(
                  rotation: _controller.value * 2 * math.pi,
                  color: widget.vinylColor,
                  isPlaying: widget.isPlaying,
                ),
              ),
              // Album art (center)
              ClipOval(
                child: SizedBox(
                  width: widget.size * 0.5,
                  height: widget.size * 0.5,
                  child: RotationTransition(
                    turns: _controller,
                    child: widget.albumArt ?? Container(color: Colors.grey.shade800),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VinylPainter extends CustomPainter {
  final double rotation;
  final Color color;
  final bool isPlaying;

  _VinylPainter({
    required this.rotation,
    required this.color,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // Main disc
    final discPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color,
          color.withValues(alpha: 0.95),
          color.withValues(alpha: 0.9),
          color,
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    canvas.drawCircle(Offset.zero, radius, discPaint);

    // Vinyl grooves (concentric circles)
    final groovePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (double r = radius * 0.25; r < radius; r += radius * 0.08) {
      canvas.drawCircle(Offset.zero, r, groovePaint);
    }

    // Light reflection (subtle shine)
    final shinePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: const Offset(-30, -30), radius: radius));
    canvas.drawCircle(Offset.zero, radius, shinePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_VinylPainter oldDelegate) =>
      oldDelegate.rotation != rotation || oldDelegate.isPlaying != isPlaying;
}
