import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'game_backdrop.dart';

const _germColors = [Color(0xFF8FC97E), Color(0xFFD98FE8), Color(0xFF8FA7E8), WiamColors.coral];

class _Germ {
  final double x; // 0..1 within the hand area
  final double y;
  final double size;
  final Color color;
  bool clean = false;
  double age = 0;
  _Germ({required this.x, required this.y, required this.size, required this.color});
}

/// Rub across the hand to wipe germs away — teaches the "scrub every part"
/// idea behind proper hand-washing. No fail state, no timer pressure; level
/// scales how many germs are scattered (and packs them a little tighter).
class HandwashGame extends StatefulWidget {
  final int level;
  final VoidCallback onLevelComplete;
  const HandwashGame({super.key, required this.level, required this.onLevelComplete});

  @override
  State<HandwashGame> createState() => _HandwashGameState();
}

class _HandwashGameState extends State<HandwashGame> {
  late List<_Germ> _germs;
  int _cleaned = 0;
  bool _reported = false;

  int get _target => (6 + widget.level * 4).clamp(6, 40);

  @override
  void initState() {
    super.initState();
    _spawn();
  }

  void _spawn() {
    final rand = Random();
    // Scattered across the whole play area with a small margin — the area
    // itself is a rounded rectangle (not clipped to a circle), so this
    // stays correct no matter the aspect ratio of the available space.
    _germs = List.generate(_target, (_) {
      final x = 0.08 + rand.nextDouble() * 0.84;
      final y = 0.1 + rand.nextDouble() * 0.8;
      return _Germ(x: x, y: y, size: 16 + rand.nextDouble() * 10, color: _germColors[rand.nextInt(_germColors.length)]);
    });
    _cleaned = 0;
    _reported = false;
  }

  void _scrubAt(Offset local, Size area) {
    var changed = false;
    for (final g in _germs) {
      if (g.clean) continue;
      final gx = g.x * area.width;
      final gy = g.y * area.height;
      final dist = (Offset(gx, gy) - local).distance;
      if (dist < 42) {
        g.clean = true;
        _cleaned++;
        changed = true;
      }
    }
    if (changed) {
      HapticFeedback.selectionClick();
      setState(() {});
      if (_cleaned >= _target && !_reported) {
        _reported = true;
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 600), () {
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
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(children: [
                const Icon(Icons.clean_hands, color: WiamColors.teal, size: 18),
                const SizedBox(width: 6),
                Text('نظّف يديك — المستوى ${widget.level}', style: displayFont(fontSize: 16, fontWeight: FontWeight.w700, color: WiamColors.ink)),
                const Spacer(),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text('$_cleaned / $_target', style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700, color: WiamColors.inkMuted)),
                ),
              ]),
              const SizedBox(height: 6),
              Text('افرك بإصبعك على الجراثيم للتخلص منها، كأنك تغسل يديك بالصابون', style: bodyFont(fontSize: 12, color: WiamColors.inkMuted)),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(constraints.maxWidth, constraints.maxHeight);
                    return GestureDetector(
                      onPanUpdate: cleared ? null : (d) => _scrubAt(d.localPosition, size),
                      onPanStart: cleared ? null : (d) => _scrubAt(d.localPosition, size),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: RadialGradient(
                            center: const Alignment(-0.2, -0.3),
                            radius: 1.2,
                            colors: [WiamColors.amber.withValues(alpha: 0.28), WiamColors.card],
                          ),
                          border: Border.all(color: WiamColors.cardLine),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: cleared
                            ? const Center(child: Icon(Icons.celebration_rounded, color: WiamColors.amber, size: 48))
                            : Stack(
                                children: [
                                  for (final g in _germs)
                                    if (!g.clean)
                                      Positioned(
                                        left: g.x * size.width - g.size / 2,
                                        top: g.y * size.height - g.size / 2,
                                        child: Container(
                                          width: g.size,
                                          height: g.size,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: g.color.withValues(alpha: 0.85),
                                            boxShadow: [BoxShadow(color: g.color.withValues(alpha: 0.5), blurRadius: 6)],
                                          ),
                                        ),
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
