import 'dart:math';
import 'package:flutter/material.dart';

/// A cartoon germ: a wobbly blob with spikes and a face. Deliberately
/// cheeky rather than scary — the point is that the child enjoys scrubbing
/// them away, not that they find germs frightening.
class GermArt extends StatelessWidget {
  final Color color;
  final int seed;
  final double size;
  const GermArt({super.key, required this.color, required this.seed, this.size = 44});

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(size, size), painter: _GermPainter(color, seed));
}

class _GermPainter extends CustomPainter {
  final Color color;
  final int seed;
  _GermPainter(this.color, this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(seed);
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.32;
    final lobes = 5 + rand.nextInt(3);
    final phase = rand.nextDouble() * pi * 2;
    final dark = Color.lerp(color, Colors.black, 0.22)!;

    final spikeCount = 7 + rand.nextInt(3);
    final spike = Paint()
      ..color = dark
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    for (int i = 0; i < spikeCount; i++) {
      final a = phase + i * 2 * pi / spikeCount;
      final dir = Offset(cos(a), sin(a));
      canvas.drawLine(c + dir * (r * 0.85), c + dir * (r * 1.38), spike);
      canvas.drawCircle(c + dir * (r * 1.38), size.width * 0.045, Paint()..color = dark);
    }

    final body = Path();
    var first = true;
    for (double a = 0; a <= pi * 2 + 0.001; a += 0.12) {
      final rr = r * (1 + 0.1 * sin(a * lobes + phase));
      final p = c + Offset(cos(a) * rr, sin(a) * rr);
      if (first) {
        body.moveTo(p.dx, p.dy);
        first = false;
      } else {
        body.lineTo(p.dx, p.dy);
      }
    }
    body.close();
    canvas.drawPath(
      body,
      Paint()
        ..isAntiAlias = true
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          colors: [Color.lerp(color, Colors.white, 0.45)!, color],
        ).createShader(Rect.fromCircle(center: c, radius: r * 1.15)),
    );

    final eyeDx = r * 0.36;
    final eyeY = c.dy - r * 0.1;
    final eyeR = r * 0.27;
    for (final dx in [-eyeDx, eyeDx]) {
      canvas.drawCircle(Offset(c.dx + dx, eyeY), eyeR, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(c.dx + dx + eyeR * 0.18, eyeY + eyeR * 0.12), eyeR * 0.52, Paint()..color = const Color(0xFF25213C));
    }

    canvas.drawPath(
      Path()
        ..moveTo(c.dx - r * 0.26, c.dy + r * 0.34)
        ..quadraticBezierTo(c.dx, c.dy + r * 0.68, c.dx + r * 0.26, c.dy + r * 0.34),
      Paint()
        ..color = const Color(0xFF25213C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.13
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _GermPainter old) => old.color != color || old.seed != seed;
}

/// A soap bubble left behind where a germ was scrubbed away.
class SudsArt extends StatelessWidget {
  final double size;
  final double progress; // 0..1
  const SudsArt({super.key, required this.size, required this.progress});

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(size, size), painter: _SudsPainter(progress));
}

class _SudsPainter extends CustomPainter {
  final double t;
  _SudsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final fade = (1 - t).clamp(0.0, 1.0);
    final grow = 0.5 + t * 0.9;
    for (int i = 0; i < 6; i++) {
      final a = i * pi / 3 - pi / 2;
      final d = size.width * 0.3 * grow;
      final p = c + Offset(cos(a) * d, sin(a) * d);
      final rr = size.width * 0.13 * (1 - t * 0.4);
      canvas.drawCircle(p, rr, Paint()..color = Colors.white.withValues(alpha: 0.7 * fade));
      canvas.drawCircle(
        p - Offset(rr * 0.3, rr * 0.3),
        rr * 0.32,
        Paint()..color = Colors.white.withValues(alpha: 0.9 * fade),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SudsPainter old) => old.t != t;
}
