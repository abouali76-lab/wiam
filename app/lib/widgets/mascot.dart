import 'package:flutter/material.dart';

import '../theme.dart';

enum MascotMood { sleepy, waiting, happy }

/// A small friendly character that gives the lock screen some life — bobs
/// gently in place and swaps expression with the child's progress, instead
/// of sitting there as a static planet graphic.
class Mascot extends StatefulWidget {
  final MascotMood mood;
  final double size;
  const Mascot({super.key, required this.mood, this.size = 96});

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
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
        final bob = Curves.easeInOut.transform(_controller.value) * 8 - 4;
        return Transform.translate(offset: Offset(0, bob), child: child);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: CustomPaint(
          key: ValueKey(widget.mood),
          size: Size(widget.size, widget.size),
          painter: _MascotPainter(widget.mood),
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  final MascotMood mood;
  _MascotPainter(this.mood);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: mood == MascotMood.sleepy ? [WiamColors.inkMuted, WiamColors.planetDim] : [WiamColors.amber, WiamColors.amberDeep],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, bodyPaint);

    final eyeColor = const Color(0xFF2B1E12);
    final eyeY = center.dy - r * 0.08;
    final eyeDx = r * 0.32;
    final eyeR = r * (mood == MascotMood.happy ? 0.11 : 0.09);

    if (mood == MascotMood.sleepy) {
      final p = Paint()
        ..color = eyeColor
        ..strokeWidth = r * 0.09
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(Rect.fromCircle(center: Offset(center.dx - eyeDx, eyeY), radius: r * 0.14), 0.3, 2.5, false, p);
      canvas.drawArc(Rect.fromCircle(center: Offset(center.dx + eyeDx, eyeY), radius: r * 0.14), 0.3, 2.5, false, p);
    } else {
      canvas.drawCircle(Offset(center.dx - eyeDx, eyeY), eyeR, Paint()..color = eyeColor);
      canvas.drawCircle(Offset(center.dx + eyeDx, eyeY), eyeR, Paint()..color = eyeColor);
    }

    final mouthPaint = Paint()
      ..color = eyeColor
      ..strokeWidth = r * 0.09
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final mouthY = center.dy + r * 0.28;
    final mouthPath = Path();
    switch (mood) {
      case MascotMood.happy:
        mouthPath.moveTo(center.dx - r * 0.32, mouthY - r * 0.05);
        mouthPath.quadraticBezierTo(center.dx, mouthY + r * 0.32, center.dx + r * 0.32, mouthY - r * 0.05);
        break;
      case MascotMood.waiting:
        mouthPath.moveTo(center.dx - r * 0.22, mouthY + r * 0.06);
        mouthPath.quadraticBezierTo(center.dx, mouthY + r * 0.16, center.dx + r * 0.22, mouthY + r * 0.06);
        break;
      case MascotMood.sleepy:
        mouthPath.moveTo(center.dx - r * 0.14, mouthY + r * 0.08);
        mouthPath.quadraticBezierTo(center.dx, mouthY - r * 0.02, center.dx + r * 0.14, mouthY + r * 0.08);
        break;
    }
    canvas.drawPath(mouthPath, mouthPaint);

    // Rosy cheeks — a small warmth touch that reads well even at small sizes.
    if (mood != MascotMood.sleepy) {
      final cheek = Paint()..color = const Color(0xFFE8794A).withValues(alpha: 0.35);
      canvas.drawCircle(Offset(center.dx - r * 0.55, center.dy + r * 0.12), r * 0.11, cheek);
      canvas.drawCircle(Offset(center.dx + r * 0.55, center.dy + r * 0.12), r * 0.11, cheek);
    }
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) => oldDelegate.mood != mood;
}
