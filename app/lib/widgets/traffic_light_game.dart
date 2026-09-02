import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'game_backdrop.dart';

enum _Phase { red, green }

/// A "red light, green light" reflex game: tap "امشِ" only while the light
/// is green. Teaches the impulse-control half of crossing-the-street
/// safety — waiting for the right signal — without any fail state; a tap on
/// red just doesn't score, it doesn't end the round.
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
  double _walk = 0; // 0..1 progress of the character across the crossing
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
      setState(() {
        _score++;
        _walk = (_score / _target).clamp(0.0, 1.0);
      });
      if (_score >= _target && !_reported) {
        _reported = true;
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 700), () {
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
            opacity: _mistakeFlash * 0.3,
            duration: const Duration(milliseconds: 90),
            child: Container(color: WiamColors.coral),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              Row(children: [
                const Icon(Icons.traffic, color: WiamColors.teal, size: 18),
                const SizedBox(width: 6),
                Text('إشارة المرور — المستوى ${widget.level}',
                    style: displayFont(fontSize: 16, fontWeight: FontWeight.w700, color: WiamColors.ink)),
                const Spacer(),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text('$_score / $_target',
                      style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700, color: WiamColors.inkMuted)),
                ),
              ]),
              const SizedBox(height: 4),
              Text('اضغط "امشِ" فقط عندما تكون الإشارة خضراء',
                  textAlign: TextAlign.center, style: bodyFont(fontSize: 12, color: WiamColors.inkMuted)),
              Expanded(
                child: cleared
                    ? Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.emoji_events_rounded, color: WiamColors.amber, size: 54),
                          const SizedBox(height: 10),
                          Text('عبرت الطريق بأمان! 🎉',
                              style: displayFont(fontSize: 18, fontWeight: FontWeight.w700, color: WiamColors.ink)),
                        ]),
                      )
                    : Column(
                        children: [
                          const SizedBox(height: 6),
                          Expanded(
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: _StreetPainter(green: green, walk: _walk),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TweenAnimationBuilder<double>(
                            key: ValueKey(_score),
                            tween: Tween(begin: 0.86, end: 1.0),
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.elasticOut,
                            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: _tapWalk,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    gradient: LinearGradient(
                                      colors: green
                                          ? [const Color(0xFF7ED4A4), const Color(0xFF3F9E6B)]
                                          : [WiamColors.planetDim, WiamColors.planetDim],
                                    ),
                                    boxShadow: green
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF4FBE83).withValues(alpha: 0.5),
                                              blurRadius: 20,
                                              spreadRadius: 1,
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(Icons.directions_walk, color: Colors.white, size: 24),
                                    const SizedBox(width: 8),
                                    Text('امشِ',
                                        style: bodyFont(
                                            fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                                  ]),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The scene: a zebra crossing, a traffic light on a pole, and a little
/// character who steps further across each time the child goes on green.
class _StreetPainter extends CustomPainter {
  final bool green;
  final double walk;
  _StreetPainter({required this.green, required this.walk});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final roadTop = h * 0.55;

    canvas.drawRect(
      Rect.fromLTWH(0, roadTop, w, h - roadTop),
      Paint()..color = const Color(0xFF2B2F4A),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, roadTop, w, 4),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );

    // Zebra stripes.
    final stripe = Paint()..color = Colors.white.withValues(alpha: 0.5);
    final stripeW = w * 0.075;
    for (double x = w * 0.06; x < w * 0.94; x += stripeW * 1.9) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, roadTop + 12, stripeW, h - roadTop - 26),
          const Radius.circular(3),
        ),
        stripe,
      );
    }

    _trafficLight(canvas, Offset(w * 0.83, roadTop - 6), h * 0.42);
    _walker(canvas, Offset(w * (0.12 + walk * 0.62), roadTop + (h - roadTop) * 0.45), h * 0.2);
  }

  void _trafficLight(Canvas canvas, Offset base, double height) {
    final poleW = height * 0.07;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx - poleW / 2, base.dy - height * 0.55, poleW, height * 0.55),
        Radius.circular(poleW / 2),
      ),
      Paint()..color = const Color(0xFF565C82),
    );

    final boxW = height * 0.34;
    final boxH = height * 0.62;
    final boxRect = Rect.fromCenter(
      center: Offset(base.dx, base.dy - height * 0.55 - boxH / 2),
      width: boxW,
      height: boxH,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, Radius.circular(boxW * 0.22)),
      Paint()..color = const Color(0xFF20243D),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, Radius.circular(boxW * 0.22)),
      Paint()
        ..color = const Color(0xFF6E7599)
        ..style = PaintingStyle.stroke
        ..strokeWidth = boxW * 0.06,
    );

    final lampR = boxW * 0.28;
    final redC = Offset(boxRect.center.dx, boxRect.top + boxH * 0.27);
    final greenC = Offset(boxRect.center.dx, boxRect.bottom - boxH * 0.27);
    _lamp(canvas, redC, lampR, const Color(0xFFE8564B), !green);
    _lamp(canvas, greenC, lampR, const Color(0xFF4FD48A), green);
  }

  void _lamp(Canvas canvas, Offset c, double r, Color color, bool on) {
    if (on) {
      canvas.drawCircle(c, r * 2.1, Paint()..color = color.withValues(alpha: 0.22));
      canvas.drawCircle(c, r * 1.45, Paint()..color = color.withValues(alpha: 0.3));
    }
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: on
              ? [Color.lerp(color, Colors.white, 0.5)!, color]
              : [color.withValues(alpha: 0.22), color.withValues(alpha: 0.13)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  void _walker(Canvas canvas, Offset feet, double height) {
    final body = Paint()..color = const Color(0xFFF3C24B);
    final dark = Paint()
      ..color = const Color(0xFF2B1E12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = height * 0.09
      ..strokeCap = StrokeCap.round;

    final headR = height * 0.19;
    final headC = Offset(feet.dx, feet.dy - height * 0.82);
    canvas.drawCircle(headC, headR, body);
    canvas.drawCircle(Offset(headC.dx - headR * 0.28, headC.dy - headR * 0.1), headR * 0.16, Paint()..color = const Color(0xFF2B1E12));
    canvas.drawCircle(Offset(headC.dx + headR * 0.28, headC.dy - headR * 0.1), headR * 0.16, Paint()..color = const Color(0xFF2B1E12));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(feet.dx, feet.dy - height * 0.42),
          width: height * 0.34,
          height: height * 0.42,
        ),
        Radius.circular(height * 0.14),
      ),
      body,
    );

    // Legs mid-stride, arms swinging — reads as walking even when static.
    canvas.drawLine(Offset(feet.dx, feet.dy - height * 0.22), Offset(feet.dx - height * 0.16, feet.dy), dark);
    canvas.drawLine(Offset(feet.dx, feet.dy - height * 0.22), Offset(feet.dx + height * 0.17, feet.dy - height * 0.03), dark);
    canvas.drawLine(
      Offset(feet.dx - height * 0.12, feet.dy - height * 0.52),
      Offset(feet.dx - height * 0.28, feet.dy - height * 0.34),
      dark,
    );
    canvas.drawLine(
      Offset(feet.dx + height * 0.12, feet.dy - height * 0.52),
      Offset(feet.dx + height * 0.26, feet.dy - height * 0.6),
      dark,
    );
  }

  @override
  bool shouldRepaint(covariant _StreetPainter old) => old.green != green || old.walk != walk;
}
