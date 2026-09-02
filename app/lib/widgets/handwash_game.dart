import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'art/germ_art.dart';
import 'game_backdrop.dart';

const _germColors = [
  Color(0xFF8FC97E),
  Color(0xFFD98FE8),
  Color(0xFF8FA7E8),
  Color(0xFFE8956F),
  Color(0xFF7FD1C4),
];

class _Germ {
  final double x; // 0..1 of the scrub area
  final double y;
  final double size;
  final Color color;
  final int seed;
  bool clean = false;
  _Germ({required this.x, required this.y, required this.size, required this.color, required this.seed});
}

/// Rub across the hands to wipe germs away — teaches the "scrub every part"
/// idea behind proper hand-washing. No fail state, no timer pressure; level
/// scales how many germs are scattered.
class HandwashGame extends StatefulWidget {
  final int level;
  final VoidCallback onLevelComplete;
  const HandwashGame({super.key, required this.level, required this.onLevelComplete});

  @override
  State<HandwashGame> createState() => _HandwashGameState();
}

class _HandwashGameState extends State<HandwashGame> with SingleTickerProviderStateMixin {
  late List<_Germ> _germs;
  final List<_Suds> _suds = [];
  int _cleaned = 0;
  bool _reported = false;
  late final AnimationController _sudsTicker;

  int get _target => (6 + widget.level * 4).clamp(6, 40);

  @override
  void initState() {
    super.initState();
    _spawn();
    _sudsTicker = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..addListener(_ageSuds)
      ..repeat();
  }

  @override
  void dispose() {
    _sudsTicker.dispose();
    super.dispose();
  }

  void _ageSuds() {
    if (_suds.isEmpty) return;
    setState(() {
      for (final s in _suds) {
        s.age += 0.03;
      }
      _suds.removeWhere((s) => s.age >= 1);
    });
  }

  void _spawn() {
    final rand = Random();
    // Scattered across the whole scrub area with a margin — that area is a
    // rounded rectangle, so this stays correct at any aspect ratio.
    _germs = List.generate(_target, (i) {
      return _Germ(
        x: 0.09 + rand.nextDouble() * 0.82,
        y: 0.1 + rand.nextDouble() * 0.8,
        size: 34 + rand.nextDouble() * 16,
        color: _germColors[rand.nextInt(_germColors.length)],
        seed: rand.nextInt(1 << 30),
      );
    });
    _cleaned = 0;
    _reported = false;
  }

  void _scrubAt(Offset local, Size area) {
    var changed = false;
    for (final g in _germs) {
      if (g.clean) continue;
      final gp = Offset(g.x * area.width, g.y * area.height);
      if ((gp - local).distance < 44) {
        g.clean = true;
        _cleaned++;
        _suds.add(_Suds(g.x, g.y, g.size));
        changed = true;
      }
    }
    if (changed) {
      HapticFeedback.selectionClick();
      setState(() {});
      if (_cleaned >= _target && !_reported) {
        _reported = true;
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) widget.onLevelComplete();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleared = _cleaned >= _target;
    return Stack(
      children: [
        const Positioned.fill(child: GameBackdrop()),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(children: [
                const Icon(Icons.clean_hands, color: WiamColors.teal, size: 18),
                const SizedBox(width: 6),
                Text('نظّف يديك — المستوى ${widget.level}',
                    style: displayFont(fontSize: 16, fontWeight: FontWeight.w700, color: WiamColors.ink)),
                const Spacer(),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text('$_cleaned / $_target',
                      style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700, color: WiamColors.inkMuted)),
                ),
              ]),
              const SizedBox(height: 4),
              Text('افرك بإصبعك على الجراثيم للتخلص منها، كأنك تغسل يديك بالصابون',
                  textAlign: TextAlign.center, style: bodyFont(fontSize: 12, color: WiamColors.inkMuted)),
              const SizedBox(height: 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final area = Size(constraints.maxWidth, constraints.maxHeight);
                    return GestureDetector(
                      onPanUpdate: cleared ? null : (d) => _scrubAt(d.localPosition, area),
                      onPanStart: cleared ? null : (d) => _scrubAt(d.localPosition, area),
                      onTapDown: cleared ? null : (d) => _scrubAt(d.localPosition, area),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          gradient: const RadialGradient(
                            center: Alignment(-0.2, -0.3),
                            radius: 1.1,
                            colors: [Color(0xFF3B4270), Color(0xFF272C4C)],
                          ),
                          border: Border.all(color: WiamColors.cardLine),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: cleared
                            ? Center(
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.verified_rounded, color: WiamColors.teal, size: 54),
                                  const SizedBox(height: 10),
                                  Text('يداك نظيفتان الآن! ✨',
                                      style: displayFont(
                                          fontSize: 18, fontWeight: FontWeight.w700, color: WiamColors.ink)),
                                ]),
                              )
                            : Stack(
                                children: [
                                  Positioned.fill(child: CustomPaint(painter: _HandsPainter())),
                                  for (final g in _germs)
                                    if (!g.clean)
                                      Positioned(
                                        left: g.x * area.width - g.size / 2,
                                        top: g.y * area.height - g.size / 2,
                                        child: GermArt(color: g.color, seed: g.seed, size: g.size),
                                      ),
                                  for (final s in _suds)
                                    Positioned(
                                      left: s.x * area.width - s.size / 2,
                                      top: s.y * area.height - s.size / 2,
                                      child: SudsArt(size: s.size, progress: s.age),
                                    ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Suds {
  final double x;
  final double y;
  final double size;
  double age = 0;
  _Suds(this.x, this.y, this.size);
}

/// A faint pair of hands behind the germs, so the child understands *what*
/// they are scrubbing rather than just clearing abstract dots.
class _HandsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..isAntiAlias = true;
    final outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    for (final mirror in [false, true]) {
      canvas.save();
      if (mirror) {
        canvas.translate(size.width, 0);
        canvas.scale(-1, 1);
      }
      final w = size.width, h = size.height;
      final palm = Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.10, h * 0.42, w * 0.30, h * 0.40),
          Radius.circular(w * 0.09),
        ));
      canvas.drawPath(palm, paint);
      canvas.drawPath(palm, outline);
      for (int i = 0; i < 4; i++) {
        final fx = w * (0.125 + i * 0.072);
        final fingerTop = h * (0.28 + (i == 0 || i == 3 ? 0.06 : 0.0));
        final finger = RRect.fromRectAndRadius(
          Rect.fromLTWH(fx, fingerTop, w * 0.052, h * 0.2),
          Radius.circular(w * 0.03),
        );
        canvas.drawRRect(finger, paint);
        canvas.drawRRect(finger, outline);
      }
      final thumb = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.035, h * 0.5, w * 0.075, h * 0.17),
        Radius.circular(w * 0.035),
      );
      canvas.drawRRect(thumb, paint);
      canvas.drawRRect(thumb, outline);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _HandsPainter oldDelegate) => false;
}
