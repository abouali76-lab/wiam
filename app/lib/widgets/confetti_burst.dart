import 'dart:math';
import 'package:flutter/material.dart';

import '../theme.dart';

const _confettiColors = [WiamColors.amber, WiamColors.teal, Color(0xFFE8794A), Color(0xFFF4D48C)];

class _Particle {
  final double angle;
  final double distance;
  final double size;
  final Color color;
  final double spin;
  _Particle(this.angle, this.distance, this.size, this.color, this.spin);
}

/// A short-lived burst of particles played once whenever [trigger] changes
/// (e.g. bump an int each time a task is completed) — visual payoff for an
/// action, layered over whatever's already on screen via a Stack.
class ConfettiBurst extends StatefulWidget {
  final Object trigger;
  const ConfettiBurst({super.key, required this.trigger});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  }

  @override
  void didUpdateWidget(covariant ConfettiBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) _burst();
  }

  void _burst() {
    final rand = Random();
    _particles = List.generate(18, (_) {
      final angle = rand.nextDouble() * pi - pi / 2 - pi / 4;
      return _Particle(
        angle,
        40 + rand.nextDouble() * 60,
        4 + rand.nextDouble() * 4,
        _confettiColors[rand.nextInt(_confettiColors.length)],
        rand.nextDouble() * 6 - 3,
      );
    });
    _controller
      ..reset()
      ..forward();
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
        builder: (context, _) => CustomPaint(painter: _ConfettiPainter(_particles, _controller.value), size: Size.infinite),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (t == 0 || t == 1) return;
    final origin = Offset(size.width / 2, size.height * 0.35);
    final fade = (1 - t).clamp(0.0, 1.0);
    for (final p in particles) {
      final eased = Curves.easeOut.transform(t);
      final dx = cos(p.angle) * p.distance * eased;
      final dy = sin(p.angle) * p.distance * eased + 60 * t * t; // gentle gravity
      final pos = origin + Offset(dx, dy);
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t * pi);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.6), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
