import 'package:flutter/material.dart';

/// 黑胶唱针 — 模拟网易云音乐的唱针动画
/// 播放时落在唱片上，暂停时抬起
class StylusNeedle extends StatelessWidget {
  final bool isPlaying;
  final double size;

  const StylusNeedle({
    super.key,
    required this.isPlaying,
    this.size = 280,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      offset: isPlaying ? const Offset(0, 0) : const Offset(0, -0.15),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _NeedlePainter(isPlaying: isPlaying),
        ),
      ),
    );
  }
}

class _NeedlePainter extends CustomPainter {
  final bool isPlaying;

  _NeedlePainter({required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final topY = size.height * 0.05;
    final pivotX = centerX + size.width * 0.3;
    final pivotY = topY;

    canvas.save();
    // Rotate the needle around the pivot point
    canvas.translate(pivotX, pivotY);
    final angle = isPlaying ? 0.08 : -0.35;
    canvas.rotate(angle);

    // Needle arm
    final armPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Draw arm from pivot to disc edge
    final armEndX = -size.width * 0.25;
    final armEndY = size.height * 0.35;
    canvas.drawLine(const Offset(0, 0), Offset(armEndX, armEndY), armPaint);

    // Needle head (cartridge)
    final headPaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(armEndX, armEndY),
      Offset(armEndX - 5, armEndY + size.height * 0.02),
      headPaint,
    );

    // Stylus tip
    final tipPaint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(armEndX - 5, armEndY + size.height * 0.02),
      2, tipPaint);

    // Pivot circle
    final pivotPaint = Paint()
      ..color = Colors.grey.shade500
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(0, 0), 6, pivotPaint);
    final innerPaint = Paint()..color = Colors.grey.shade300;
    canvas.drawCircle(const Offset(0, 0), 4, innerPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_NeedlePainter old) => old.isPlaying != isPlaying;
}
