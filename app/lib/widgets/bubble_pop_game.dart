import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../theme.dart';

const _bubbleColors = [WiamColors.amber, WiamColors.teal, Color(0xFFE8794A), Color(0xFFF4D48C), Color(0xFF8FA7E8)];

class _Bubble {
  double x; // 0..1
  double y; // 0..1, starts at 1 (bottom) and rises toward 0
  final double speed;
  final double size;
  final double wobblePhase;
  final Color color;
  bool popped = false;
  double popAge = 0;
  _Bubble({required this.x, required this.y, required this.speed, required this.size, required this.wobblePhase, required this.color});
}

/// Tap rising bubbles before they float off the top. No fail state — an
/// un-popped bubble just drifts away. Level scales the pop target and rise
/// speed; reaching the target hands off to [onLevelComplete].
class BubblePopGame extends StatefulWidget {
  final int level;
  final VoidCallback onLevelComplete;
  const BubblePopGame({super.key, required this.level, required this.onLevelComplete});

  @override
  State<BubblePopGame> createState() => _BubblePopGameState();
}

class _BubblePopGameState extends State<BubblePopGame> {
  final _rand = Random();
  final List<_Bubble> _bubbles = [];
  int _score = 0;
  Timer? _ticker;
  double _spawnCooldown = 0;
  bool _reported = false;

  int get _target => 4 + widget.level * 3;
  double get _speedBoost => 1 + (widget.level - 1) * 0.12;

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
    final cleared = _score >= _target;
    setState(() {
      if (!cleared) {
        _spawnCooldown -= 0.04;
        if (_spawnCooldown <= 0 && _bubbles.where((b) => !b.popped).length < 7) {
          _bubbles.add(_Bubble(
            x: 0.1 + _rand.nextDouble() * 0.8,
            y: 1.05,
            speed: (0.004 + _rand.nextDouble() * 0.005) * _speedBoost,
            size: 34 + _rand.nextDouble() * 22,
            wobblePhase: _rand.nextDouble() * pi * 2,
            color: _bubbleColors[_rand.nextInt(_bubbleColors.length)],
          ));
          _spawnCooldown = (0.5 + _rand.nextDouble() * 0.5) / _speedBoost;
        }
      }

      for (final b in _bubbles) {
        if (b.popped) {
          b.popAge += 0.05;
        } else if (!cleared) {
          b.y -= b.speed;
          b.x += sin(b.y * 6 + b.wobblePhase) * 0.002;
        }
      }
      _bubbles.removeWhere((b) => (b.popped && b.popAge > 1) || (!b.popped && b.y < -0.08));
    });

    if (cleared && !_reported) {
      _reported = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) widget.onLevelComplete();
      });
    }
  }

  void _pop(_Bubble b) {
    if (b.popped) return;
    setState(() {
      b.popped = true;
      _score++;
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
            Positioned(
              top: 14,
              right: 18,
              child: Row(children: [
                const Icon(Icons.bubble_chart_rounded, color: WiamColors.teal, size: 18),
                const SizedBox(width: 6),
                Text('$_score / $_target', style: displayFont(fontSize: 16, fontWeight: FontWeight.w700, color: WiamColors.ink)),
              ]),
            ),
            Positioned(
              top: 14,
              left: 18,
              child: Text('المستوى ${widget.level}', style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700, color: WiamColors.inkMuted)),
            ),
            if (!cleared) ...[
              for (final b in _bubbles)
                Positioned(
                  left: b.x * w - b.size / 2,
                  top: b.y * h - b.size / 2,
                  child: GestureDetector(
                    onTap: () => _pop(b),
                    child: b.popped
                        ? Opacity(
                            opacity: (1 - b.popAge).clamp(0, 1),
                            child: Transform.scale(
                              scale: 1 + b.popAge * 0.8,
                              child: Icon(Icons.auto_awesome_rounded, color: b.color, size: b.size),
                            ),
                          )
                        : Container(
                            width: b.size,
                            height: b.size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(center: const Alignment(-0.3, -0.4), colors: [Colors.white.withValues(alpha: 0.5), b.color.withValues(alpha: 0.55)]),
                              border: Border.all(color: b.color.withValues(alpha: 0.8), width: 1.5),
                            ),
                          ),
                  ),
                ),
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Text('اضغط على الفقاعات قبل أن تطير', textAlign: TextAlign.center, style: bodyFont(fontSize: 11.5, color: WiamColors.inkMuted)),
              ),
            ] else
              const Center(child: Icon(Icons.celebration_rounded, color: WiamColors.amber, size: 48)),
          ],
        );
      },
    );
  }
}
