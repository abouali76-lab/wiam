import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'game_backdrop.dart';

enum _Phase { red, green }

/// A "red light, green light" reflex game: tap "امشِ" only while the light
/// is green. Teaches the impulse-control half of crossing-the-street
/// safety — waiting for the right signal — without any fail state; a tap
/// on red just doesn't score, it doesn't end the round.
class TrafficLightGame extends StatefulWidget {
  final int level;
  final VoidCallback onLevelComplete;
  const TrafficLightGame({super.key, required this.level, required this.onLevelComplete});

  @override
  State<TrafficLightGame> createState() => _TrafficLightGameState();
}

class _TrafficLightGameState extends State<TrafficLightGame> {
  final _rand = Random();
  Timer? _ticker;
  _Phase _phase = _Phase.red;
  double _phaseRemaining = 1.5;
  int _score = 0;
  double _mistakeFlash = 0;
  bool _reported = false;

  int get _target => 4 + widget.level * 3;
  double get _greenDuration => (1.9 - (widget.level - 1) * 0.15).clamp(0.8, 1.9);

  @override
  void initState() {
    super.initState();
    _phaseRemaining = 1.2 + _rand.nextDouble() * 1.2;
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
      _phaseRemaining -= 0.016;
      if (_phaseRemaining <= 0) {
        _phase = _phase == _Phase.red ? _Phase.green : _Phase.red;
        _phaseRemaining = _phase == _Phase.green ? _greenDuration : 1.2 + _rand.nextDouble() * 1.5;
      }
      if (_mistakeFlash > 0) _mistakeFlash = (_mistakeFlash - 0.05).clamp(0, 1);
    });
  }

  void _tapWalk() {
    if (_score >= _target) return;
    if (_phase == _Phase.green) {
      HapticFeedback.lightImpact();
      setState(() => _score++);
      if (_score >= _target && !_reported) {
        _reported = true;
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) widget.onLevelComplete();
        });
      }
    } else {
      HapticFeedback.mediumImpact();
      setState(() => _mistakeFlash = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleared = _score >= _target;
    final green = _phase == _Phase.green;
    return Stack(
      children: [
        const Positioned.fill(child: GameBackdrop()),
        IgnorePointer(
          child: AnimatedOpacity(
            opacity: _mistakeFlash * 0.35,
            duration: const Duration(milliseconds: 80),
            child: Container(color: WiamColors.coral),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            children: [
              Row(children: [
                const Icon(Icons.traffic, color: WiamColors.teal, size: 18),
                const SizedBox(width: 6),
                Text('إشارة المرور — المستوى ${widget.level}', style: displayFont(fontSize: 16, fontWeight: FontWeight.w700, color: WiamColors.ink)),
                const Spacer(),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text('$_score / $_target', style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700, color: WiamColors.inkMuted)),
                ),
              ]),
              const SizedBox(height: 6),
              Text('اضغط "امشِ" فقط عندما تكون الإشارة خضراء', style: bodyFont(fontSize: 12, color: WiamColors.inkMuted)),
              Expanded(
                child: Center(
                  child: cleared
                      ? const Icon(Icons.celebration_rounded, color: WiamColors.amber, size: 48)
                      : Column(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(color: WiamColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: WiamColors.cardLine)),
                            child: Column(children: [
                              _LightDot(color: WiamColors.coral, active: !green),
                              const SizedBox(height: 10),
                              _LightDot(color: WiamColors.teal, active: green),
                            ]),
                          ),
                          const SizedBox(height: 28),
                          TweenAnimationBuilder<double>(
                            key: ValueKey(_score),
                            tween: Tween(begin: 0.8, end: 1.0),
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.elasticOut,
                            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: _tapWalk,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    gradient: LinearGradient(colors: green ? [WiamColors.teal, WiamColors.tealDeepLight] : [WiamColors.planetDim, WiamColors.planetDim]),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(Icons.directions_walk, color: Colors.white, size: 22),
                                    const SizedBox(width: 8),
                                    Text('امشِ', style: bodyFont(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                                  ]),
                                ),
                              ),
                            ),
                          ),
                        ]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LightDot extends StatelessWidget {
  final Color color;
  final bool active;
  const _LightDot({required this.color, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? color : color.withValues(alpha: 0.15),
        boxShadow: active ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 16, spreadRadius: 2)] : null,
      ),
    );
  }
}
