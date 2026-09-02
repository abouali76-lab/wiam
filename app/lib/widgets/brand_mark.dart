import 'dart:math';
import 'package:flutter/material.dart';

import '../theme.dart';

/// The Wiam mark: the amber "play planet" with its orbit ring — the same
/// idea the child sees on the lock screen, drawn small enough to act as a
/// logo on the adult-facing screens.
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(size, size), painter: _BrandPainter());
}

class _BrandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    // Soft halo so the mark sits on the cream background instead of
    // floating on it as a hard disc.
    canvas.drawCircle(
      const Offset(50, 50),
      46,
      Paint()
        ..shader = RadialGradient(
          colors: [WiamColors.amberLight.withValues(alpha: 0.26), WiamColors.amberLight.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: const Offset(50, 50), radius: 46)),
    );

    // Orbit ring, tilted.
    canvas.save();
    canvas.translate(50, 50);
    canvas.rotate(-0.38);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 90, height: 34),
      Paint()
        ..color = WiamColors.tealDeepLight.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..isAntiAlias = true,
    );
    canvas.restore();

    // Planet.
    canvas.drawCircle(
      const Offset(50, 48),
      26,
      Paint()
        ..isAntiAlias = true
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          colors: [Color(0xFFF3D089), WiamColors.amberDeepLight],
        ).createShader(Rect.fromCircle(center: const Offset(50, 48), radius: 26)),
    );

    // A single star on the ring, marking earned time.
    _star(canvas, const Offset(84, 62), 7, WiamColors.tealDeepLight);
    canvas.restore();
  }

  void _star(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.44;
      final a = -pi / 2 + i * pi / 5;
      final p = c + Offset(cos(a) * radius, sin(a) * radius);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color..isAntiAlias = true);
  }

  @override
  bool shouldRepaint(covariant _BrandPainter oldDelegate) => false;
}
