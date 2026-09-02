import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'art/food_art.dart';
import 'game_backdrop.dart';

enum _Resolution { none, correct, wrong }

/// One food item at a time drifts down; the child sorts it into the right
/// basket ("صحي" / "غير صحي") before it lands. No fail state — a missed or
/// mis-sorted item just fades and the next one spawns. Level scales the
/// sort target and fall speed.
class HealthyFoodGame extends StatefulWidget {
  final int level;
  final VoidCallback onLevelComplete;
  const HealthyFoodGame({super.key, required this.level, required this.onLevelComplete});

  @override
  State<HealthyFoodGame> createState() => _HealthyFoodGameState();
}

class _HealthyFoodGameState extends State<HealthyFoodGame> {
  final _rand = Random();
  Timer? _ticker;
  late FoodKind _current;
  double _y = 0.1;
  _Resolution _resolution = _Resolution.none;
  double _resolutionAge = 0;
  int _score = 0;
  bool _reported = false;

  int get _target => 4 + widget.level * 3;
  double get _speed => (0.0016 + (widget.level - 1) * 0.00018).clamp(0.0016, 0.0045);

  @override
  void initState() {
    super.initState();
    _spawn();
    _ticker = Timer.periodic(const Duration(milliseconds: 16), _tick);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _spawn() {
    // Alternate healthy/unhealthy loosely so the child can't win by always
    // tapping the same basket.
    final wantHealthy = _rand.nextBool();
    final pool = FoodKind.values.where((f) => f.healthy == wantHealthy).toList();
    _current = pool[_rand.nextInt(pool.length)];
    _y = 0.1;
    _resolution = _Resolution.none;
    _resolutionAge = 0;
  }

  void _tick(Timer _) {
    if (_score >= _target) return;
    setState(() {
      if (_resolution == _Resolution.none) {
        _y += _speed;
        if (_y > 0.6) {
          _resolution = _Resolution.wrong;
          _resolutionAge = 0;
        }
      } else {
        _resolutionAge += 0.03;
        if (_resolutionAge > 1) _spawn();
      }
    });
    if (_score >= _target && !_reported) {
      _reported = true;
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) widget.onLevelComplete();
      });
    }
  }

  void _choose(bool healthyBasket) {
    if (_resolution != _Resolution.none) return;
    final correct = _current.healthy == healthyBasket;
    HapticFeedback.lightImpact();
    setState(() {
      _resolution = correct ? _Resolution.correct : _Resolution.wrong;
      _resolutionAge = 0;
      if (correct) _score++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cleared = _score >= _target;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final resolved = _resolution != _Resolution.none;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned.fill(child: GameBackdrop()),
            Positioned(
              top: 14,
              right: 18,
              child: Row(children: [
                const Icon(Icons.restaurant_menu, color: WiamColors.teal, size: 18),
                const SizedBox(width: 6),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text('$_score / $_target',
                      style: displayFont(fontSize: 16, fontWeight: FontWeight.w700, color: WiamColors.ink)),
                ),
              ]),
            ),
            Positioned(
              top: 14,
              left: 18,
              child: Text('المستوى ${widget.level}',
                  style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700, color: WiamColors.inkMuted)),
            ),
            if (!cleared) ...[
              Positioned(
                left: w / 2 - 54,
                top: _y * h - 54,
                child: Opacity(
                  opacity: resolved ? (1 - _resolutionAge).clamp(0.0, 1.0) : 1,
                  child: Transform.scale(
                    scale: _resolution == _Resolution.correct ? 1 + _resolutionAge * 0.45 : 1,
                    child: Column(children: [
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: WiamColors.card.withValues(alpha: 0.55),
                          border: Border.all(
                            color: switch (_resolution) {
                              _Resolution.correct => WiamColors.teal,
                              _Resolution.wrong => WiamColors.coral,
                              _Resolution.none => WiamColors.cardLine,
                            },
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_current.healthy ? WiamColors.teal : WiamColors.amber).withValues(alpha: 0.28),
                              blurRadius: 22,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: FoodArt(kind: _current, size: 74),
                      ),
                      const SizedBox(height: 6),
                      Text(_current.label,
                          style: bodyFont(fontSize: 13.5, fontWeight: FontWeight.w700, color: WiamColors.ink)),
                    ]),
                  ),
                ),
              ),
              Positioned(
                bottom: 58,
                left: 18,
                child: _Basket(
                  label: 'غير صحي',
                  icon: Icons.thumb_down_alt_rounded,
                  color: WiamColors.coral,
                  onTap: () => _choose(false),
                ),
              ),
              Positioned(
                bottom: 58,
                right: 18,
                child: _Basket(
                  label: 'صحي',
                  icon: Icons.favorite_rounded,
                  color: WiamColors.teal,
                  onTap: () => _choose(true),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Text('اختر السلة الصحيحة قبل أن يصل الطعام',
                    textAlign: TextAlign.center, style: bodyFont(fontSize: 11.5, color: WiamColors.inkMuted)),
              ),
            ] else
              const Center(child: Icon(Icons.celebration_rounded, color: WiamColors.amber, size: 48)),
          ],
        );
      },
    );
  }
}

class _Basket extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Basket({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 104,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Color.lerp(color, Colors.white, 0.18)!, color],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 5),
            Text(label, style: bodyFont(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
      ),
    );
  }
}
