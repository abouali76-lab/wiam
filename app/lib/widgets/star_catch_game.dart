import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../theme.dart';

class _FallingStar {
  double x; // 0..1, fraction of width
  double y; // 0..1, fraction of height
  final double speed; // fraction of height per tick
  final double wobblePhase;
  bool caught = false;
  _FallingStar({required this.x, required this.y, required this.speed, required this.wobblePhase});
}

class _Pop {
  final Offset position;
  double age = 0;
  _Pop(this.position);
}

/// Drag the basket along the bottom to catch falling stars. No fail state
/// on purpose — a missed star just drifts away, so nothing punishes a
/// child for missing a catch; the point is the satisfying catch itself.
class StarCatchGame extends StatefulWidget {
  const StarCatchGame({super.key});

  @override
  State<StarCatchGame> createState() => _StarCatchGameState();
}

class _StarCatchGameState extends State<StarCatchGame> {
  final _rand = Random();
  final List<_FallingStar> _stars = [];
  final List<_Pop> _pops = [];
  double _catcherX = 0.5; // 0..1
  int _score = 0;
  Timer? _ticker;
  double _spawnCooldown = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 40), _tick);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick(Timer _) {
    setState(() {
      _spawnCooldown -= 0.04;
      if (_spawnCooldown <= 0 && _stars.length < 6) {
        _stars.add(_FallingStar(
          x: 0.08 + _rand.nextDouble() * 0.84,
          y: -0.05,
          speed: 0.006 + _rand.nextDouble() * 0.006,
          wobblePhase: _rand.nextDouble() * pi * 2,
        ));
        _spawnCooldown = 0.7 + _rand.nextDouble() * 0.6;
      }

      for (final star in _stars) {
        star.y += star.speed;
        star.x += sin(star.y * 8 + star.wobblePhase) * 0.0025;
        if (!star.caught && star.y > 0.82 && star.y < 0.94 && (star.x - _catcherX).abs() < 0.13) {
          star.caught = true;
          _score++;
          _pops.add(_Pop(Offset(star.x, star.y)));
        }
      }
      _stars.removeWhere((s) => s.caught || s.y > 1.05);

      for (final pop in _pops) {
        pop.age += 0.04;
      }
      _pops.removeWhere((p) => p.age > 1);
    });
  }

  void _updateCatcher(double localX, double width) {
    setState(() => _catcherX = (localX / width).clamp(0.06, 0.94));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return GestureDetector(
          onPanUpdate: (d) => _updateCatcher(d.localPosition.dx, w),
          onPanStart: (d) => _updateCatcher(d.localPosition.dx, w),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                top: 14,
                right: 18,
                child: Row(children: [
                  const Icon(Icons.star_rounded, color: WiamColors.amber, size: 18),
                  const SizedBox(width: 6),
                  Text('$_score', style: displayFont(fontSize: 16, fontWeight: FontWeight.w700, color: WiamColors.ink)),
                ]),
              ),
              for (final star in _stars)
                Positioned(
                  left: star.x * w - 14,
                  top: star.y * h - 14,
                  child: const Icon(Icons.star_rounded, color: WiamColors.amber, size: 28),
                ),
              for (final pop in _pops)
                Positioned(
                  left: pop.position.dx * w - 20,
                  top: pop.position.dy * h - 20,
                  child: Opacity(
                    opacity: (1 - pop.age).clamp(0, 1),
                    child: Transform.scale(
                      scale: 1 + pop.age,
                      child: const Icon(Icons.auto_awesome_rounded, color: WiamColors.teal, size: 40),
                    ),
                  ),
                ),
              Positioned(
                left: _catcherX * w - 34,
                bottom: h * 0.08,
                child: Container(
                  width: 68,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20), top: Radius.circular(8)),
                    gradient: const LinearGradient(colors: [WiamColors.amber, WiamColors.amberDeep]),
                    border: Border.all(color: WiamColors.bg1, width: 2),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Text('اسحب إصبعك لتحريك السلة والتقط النجوم', textAlign: TextAlign.center, style: bodyFont(fontSize: 11.5, color: WiamColors.inkMuted)),
              ),
            ],
          ),
        );
      },
    );
  }
}
