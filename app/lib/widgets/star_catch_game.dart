import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'game_backdrop.dart';

const _starColors = [WiamColors.amber, Color(0xFFF4D48C), Color(0xFF8FA7E8), Color(0xFFD98FE8)];

class _FallingStar {
  double x; // 0..1, fraction of width
  double y; // 0..1, fraction of height
  final double speed; // fraction of height per tick
  final double wobblePhase;
  final double size;
  final Color color;
  bool caught = false;
  _FallingStar({required this.x, required this.y, required this.speed, required this.wobblePhase, required this.size, required this.color});
}

class _Pop {
  final Offset position;
  final Color color;
  double age = 0;
  _Pop(this.position, this.color);
}

/// Drag the basket along the bottom to catch falling stars. No fail state
/// on purpose — a missed star just drifts away. Level scales the catch
/// target and fall speed; reaching the target hands off to
/// [onLevelComplete] instead of just resetting itself.
class StarCatchGame extends StatefulWidget {
  final int level;
  final VoidCallback onLevelComplete;
  const StarCatchGame({super.key, required this.level, required this.onLevelComplete});

  @override
  State<StarCatchGame> createState() => _StarCatchGameState();
}

class _StarCatchGameState extends State<StarCatchGame> {
  final _rand = Random();
  final List<_FallingStar> _stars = [];
  final List<_Pop> _pops = [];
  double _catcherX = 0.5; // 0..1
  double _catcherTargetX = 0.5;
  int _score = 0;
  int _combo = 0;
  Timer? _ticker;
  double _spawnCooldown = 0;
  bool _reported = false;

  int get _target => 4 + widget.level * 3;
  double get _speedBoost => 1 + (widget.level - 1) * 0.12;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 16), _tick);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick(Timer _) {
    if (_score >= _target) return;
    setState(() {
      // Ease the catcher toward the drag target instead of snapping — feels
      // far more controllable and alive than an instant jump.
      _catcherX += (_catcherTargetX - _catcherX) * 0.28;

      _spawnCooldown -= 0.016;
      if (_spawnCooldown <= 0 && _stars.length < 6) {
        _stars.add(_FallingStar(
          x: 0.08 + _rand.nextDouble() * 0.84,
          y: -0.05,
          speed: (0.0022 + _rand.nextDouble() * 0.0022) * _speedBoost,
          wobblePhase: _rand.nextDouble() * pi * 2,
          size: 24 + _rand.nextDouble() * 10,
          color: _starColors[_rand.nextInt(_starColors.length)],
        ));
        _spawnCooldown = (0.7 + _rand.nextDouble() * 0.6) / _speedBoost;
      }

      for (final star in _stars) {
        star.y += star.speed;
        star.x += sin(star.y * 8 + star.wobblePhase) * 0.001;
        if (!star.caught && star.y > 0.8 && star.y < 0.95 && (star.x - _catcherX).abs() < 0.13) {
          star.caught = true;
          _score++;
          _combo++;
          HapticFeedback.lightImpact();
          _pops.add(_Pop(Offset(star.x, star.y), star.color));
        } else if (!star.caught && star.y > 1.02) {
          _combo = 0;
        }
      }
      _stars.removeWhere((s) => s.caught || s.y > 1.05);

      for (final pop in _pops) {
        pop.age += 0.02;
      }
      _pops.removeWhere((p) => p.age > 1);
    });

    if (_score >= _target && !_reported) {
      _reported = true;
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) widget.onLevelComplete();
      });
    }
  }

  void _updateCatcher(double localX, double width) {
    setState(() => _catcherTargetX = (localX / width).clamp(0.06, 0.94));
  }

  @override
  Widget build(BuildContext context) {
    final cleared = _score >= _target;
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
              const Positioned.fill(child: GameBackdrop()),
              Positioned(
                top: 14,
                right: 18,
                child: Row(children: [
                  const Icon(Icons.star_rounded, color: WiamColors.amber, size: 18),
                  const SizedBox(width: 6),
                  Text('$_score / $_target', style: displayFont(fontSize: 16, fontWeight: FontWeight.w700, color: WiamColors.ink)),
                  if (_combo >= 3) ...[
                    const SizedBox(width: 8),
                    Text('🔥 $_combo', style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700, color: WiamColors.coral)),
                  ],
                ]),
              ),
              Positioned(
                top: 14,
                left: 18,
                child: Text('المستوى ${widget.level}', style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700, color: WiamColors.inkMuted)),
              ),
              if (!cleared) ...[
                for (final star in _stars)
                  Positioned(
                    left: star.x * w - star.size / 2,
                    top: star.y * h - star.size / 2,
                    child: Icon(Icons.star_rounded, color: star.color, size: star.size, shadows: [Shadow(color: star.color.withValues(alpha: 0.8), blurRadius: 12)]),
                  ),
                for (final pop in _pops)
                  Positioned(
                    left: pop.position.dx * w - 22,
                    top: pop.position.dy * h - 22,
                    child: Opacity(
                      opacity: (1 - pop.age).clamp(0, 1),
                      child: Transform.scale(
                        scale: 1 + pop.age * 1.2,
                        child: Icon(Icons.auto_awesome_rounded, color: pop.color, size: 44),
                      ),
                    ),
                  ),
                Positioned(
                  left: _catcherX * w - 40,
                  bottom: h * 0.08,
                  child: CustomPaint(size: const Size(80, 44), painter: _BasketPainter()),
                ),
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Text('اسحب إصبعك لتحريك السلة والتقط النجوم', textAlign: TextAlign.center, style: bodyFont(fontSize: 11.5, color: WiamColors.inkMuted)),
                ),
              ] else
                const Center(child: Icon(Icons.celebration_rounded, color: WiamColors.amber, size: 48)),
            ],
          ),
        );
      },
    );
  }
}

class _BasketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, size.height * 0.28, size.width, size.height * 0.6);
    final basketPath = Path()
      ..moveTo(rect.left + 6, rect.top)
      ..lineTo(rect.right - 6, rect.top)
      ..lineTo(rect.right, rect.bottom - 6)
      ..quadraticBezierTo(size.width / 2, rect.bottom + 10, rect.left, rect.bottom - 6)
      ..close();
    canvas.drawPath(
      basketPath,
      Paint()..shader = const LinearGradient(colors: [WiamColors.amber, WiamColors.amberDeep], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(rect),
    );
    canvas.drawPath(basketPath, Paint()..color = WiamColors.bg1..style = PaintingStyle.stroke..strokeWidth = 2.5);

    // Weave lines for a bit of texture.
    final weavePaint = Paint()
      ..color = WiamColors.bg1.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    for (int i = 1; i < 4; i++) {
      final dx = rect.left + rect.width * i / 4;
      canvas.drawLine(Offset(dx, rect.top + 3), Offset(dx, rect.bottom - 3), weavePaint);
    }

    // Rim highlight.
    canvas.drawLine(
      Offset(rect.left + 4, rect.top),
      Offset(rect.right - 4, rect.top),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _BasketPainter oldDelegate) => false;
}
