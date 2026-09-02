import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'game_backdrop.dart';

class _FoodKind {
  final IconData icon;
  final String title;
  final bool healthy;
  const _FoodKind(this.icon, this.title, this.healthy);
}

const _foods = [
  _FoodKind(Icons.eco, 'خضار طازجة', true),
  _FoodKind(Icons.egg, 'بيض', true),
  _FoodKind(Icons.rice_bowl, 'أرز وحبوب', true),
  _FoodKind(Icons.set_meal, 'سمك', true),
  _FoodKind(Icons.water_drop, 'ماء', true),
  _FoodKind(Icons.local_florist, 'فواكه', true),
  _FoodKind(Icons.fastfood, 'وجبة سريعة', false),
  _FoodKind(Icons.local_pizza, 'بيتزا', false),
  _FoodKind(Icons.icecream, 'آيس كريم', false),
  _FoodKind(Icons.cake, 'كعك محلى', false),
  _FoodKind(Icons.cookie, 'حلوى', false),
  _FoodKind(Icons.local_bar, 'مشروب غازي', false),
];

enum _Resolution { none, correct, wrong }

/// One food item at a time drifts down the middle of the screen; the child
/// sorts it into the right basket ("صحي" / "غير صحي") before it lands. No
/// fail state — an unsorted or wrongly-sorted item just fades and the next
/// one spawns. Level scales the sort target and fall speed.
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
  late _FoodKind _current;
  double _y = 0.08;
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
    _current = _foods[_rand.nextInt(_foods.length)];
    _y = 0.08;
    _resolution = _Resolution.none;
    _resolutionAge = 0;
  }

  void _tick(Timer _) {
    if (_score >= _target) return;
    setState(() {
      if (_resolution == _Resolution.none) {
        _y += _speed;
        if (_y > 0.62) {
          // Reached the baskets untouched — no penalty, just move on.
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
                  child: Text('$_score / $_target', style: displayFont(fontSize: 16, fontWeight: FontWeight.w700, color: WiamColors.ink)),
                ),
              ]),
            ),
            Positioned(
              top: 14,
              left: 18,
              child: Text('المستوى ${widget.level}', style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700, color: WiamColors.inkMuted)),
            ),
            if (!cleared) ...[
              Positioned(
                left: w / 2 - 34,
                top: _y * h - 34,
                child: Opacity(
                  opacity: _resolution == _Resolution.none ? 1 : (1 - _resolutionAge).clamp(0, 1),
                  child: Transform.scale(
                    scale: _resolution == _Resolution.correct ? 1 + _resolutionAge * 0.5 : 1,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: WiamColors.card,
                        border: Border.all(
                          color: _resolution == _Resolution.correct
                              ? WiamColors.teal
                              : (_resolution == _Resolution.wrong ? WiamColors.coral : WiamColors.cardLine),
                          width: 2,
                        ),
                      ),
                      child: Icon(_current.icon, color: _current.healthy ? WiamColors.teal : WiamColors.amber, size: 32),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: w / 2 - 70,
                top: _y * h + 40,
                child: Text(_current.title, style: bodyFont(fontSize: 12.5, fontWeight: FontWeight.w700, color: WiamColors.inkMuted)),
              ),
              Positioned(
                bottom: 60,
                left: 20,
                child: _Basket(label: 'غير صحي', icon: Icons.close_rounded, color: WiamColors.coral, onTap: () => _choose(false)),
              ),
              Positioned(
                bottom: 60,
                right: 20,
                child: _Basket(label: 'صحي', icon: Icons.check_rounded, color: WiamColors.teal, onTap: () => _choose(true)),
              ),
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Text('اختر السلة الصحيحة قبل أن يصل الطعام', textAlign: TextAlign.center, style: bodyFont(fontSize: 11.5, color: WiamColors.inkMuted)),
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
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 96,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(colors: [color.withValues(alpha: 0.85), color], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(label, style: bodyFont(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
      ),
    );
  }
}
