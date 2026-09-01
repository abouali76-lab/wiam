import 'dart:math';
import 'package:flutter/material.dart';

import '../theme.dart';

class _Twinkle {
  final double x;
  final double y;
  final double size;
  final double phase;
  _Twinkle(this.x, this.y, this.size, this.phase);
}

/// Ambient, non-interactive twinkling starfield used behind every mini-game
/// so they read as one cohesive "space" world instead of a bare card.
class GameBackdrop extends StatefulWidget {
  const GameBackdrop({super.key});

  @override
  State<GameBackdrop> createState() => _GameBackdropState();
}

class _GameBackdropState extends State<GameBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Twinkle> _stars;

  @override
  void initState() {
    super.initState();
    final rand = Random(7);
    _stars = List.generate(26, (_) => _Twinkle(rand.nextDouble(), rand.nextDouble(), 1.2 + rand.nextDouble() * 1.8, rand.nextDouble() * pi * 2));
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(painter: _BackdropPainter(_stars, _controller.value), size: Size.infinite),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  final List<_Twinkle> stars;
  final double t;
  _BackdropPainter(this.stars, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final twinkle = 0.35 + 0.65 * (0.5 + 0.5 * sin(t * pi * 2 + s.phase));
      final paint = Paint()..color = WiamColors.inkMuted.withValues(alpha: twinkle * 0.55);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) => true;
}
