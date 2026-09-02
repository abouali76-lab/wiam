import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'art/waste_art.dart';
import 'game_backdrop.dart';

/// فرز النفايات — an item appears and the child taps the matching recycling
/// bin (ورق / بلاستيك / زجاج). Three choices instead of the food game's two,
/// so it stays a distinct challenge. No fail state: a wrong bin just shakes
/// and the item stays until it's sorted correctly.
class WasteSortGame extends StatefulWidget {
  final int level;
  final VoidCallback onLevelComplete;
  const WasteSortGame({super.key, required this.level, required this.onLevelComplete});

  @override
  State<WasteSortGame> createState() => _WasteSortGameState();
}

class _WasteSortGameState extends State<WasteSortGame> {
  final _rand = Random();
  late WasteKind _current;
  int _score = 0;
  bool _reported = false;
  WasteBin? _wrongBin;
  WasteBin? _rightBin;
  Timer? _resetTimer;

  int get _target => 3 + widget.level * 2;

  @override
  void initState() {
    super.initState();
    _current = WasteKind.values[_rand.nextInt(WasteKind.values.length)];
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _pick(WasteBin bin) {
    if (_rightBin != null || _score >= _target) return;
    if (bin == _current.bin) {
      HapticFeedback.lightImpact();
      setState(() {
        _rightBin = bin;
        _wrongBin = null;
        _score++;
      });
      if (_score >= _target && !_reported) {
        _reported = true;
        HapticFeedback.heavyImpact();
        _resetTimer = Timer(const Duration(milliseconds: 700), () {
          if (mounted) widget.onLevelComplete();
        });
        return;
      }
      _resetTimer = Timer(const Duration(milliseconds: 550), () {
        if (!mounted) return;
        setState(() {
          WasteKind next;
          do {
            next = WasteKind.values[_rand.nextInt(WasteKind.values.length)];
          } while (next == _current);
          _current = next;
          _rightBin = null;
        });
      });
    } else {
      HapticFeedback.mediumImpact();
      setState(() => _wrongBin = bin);
      _resetTimer = Timer(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _wrongBin = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleared = _score >= _target;
    return Stack(
      children: [
        const Positioned.fill(child: GameBackdrop()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              Row(children: [
                const Icon(Icons.recycling_rounded, color: WiamColors.teal, size: 18),
                const SizedBox(width: 6),
                Text('فرز النفايات — المستوى ${widget.level}',
                    style: displayFont(fontSize: 16, fontWeight: FontWeight.w700, color: WiamColors.ink)),
                const Spacer(),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text('$_score / $_target',
                      style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700, color: WiamColors.inkMuted)),
                ),
              ]),
              const SizedBox(height: 4),
              Text('ضع كل شيء في الحاوية المناسبة له',
                  style: bodyFont(fontSize: 12, color: WiamColors.inkMuted)),
              Expanded(
                child: cleared
                    ? Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.eco_rounded, color: Color(0xFF7ED4A4), size: 54),
                          const SizedBox(height: 10),
                          Text('أحسنت! ساعدت في حماية البيئة 🌍',
                              textAlign: TextAlign.center,
                              style: displayFont(fontSize: 17, fontWeight: FontWeight.w700, color: WiamColors.ink)),
                        ]),
                      )
                    : Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Column(
                            key: ValueKey(_current),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 132,
                                height: 132,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: WiamColors.card.withValues(alpha: 0.5),
                                  border: Border.all(
                                    color: _rightBin != null ? WiamColors.teal : WiamColors.cardLine,
                                    width: 2.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: WasteArt(kind: _current, size: 88),
                              ),
                              const SizedBox(height: 10),
                              Text(_current.label,
                                  style: bodyFont(
                                      fontSize: 15, fontWeight: FontWeight.w700, color: WiamColors.ink)),
                            ],
                          ),
                        ),
                      ),
              ),
              if (!cleared)
                Row(
                  children: [
                    // Expanded so three bins always share the width evenly
                    // instead of overflowing on a narrow screen.
                    for (final bin in WasteBin.values)
                      Expanded(
                        child: _BinButton(
                          bin: bin,
                          wrong: _wrongBin == bin,
                          right: _rightBin == bin,
                          onTap: () => _pick(bin),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ],
    );
  }
}

class _BinButton extends StatelessWidget {
  final WasteBin bin;
  final bool wrong;
  final bool right;
  final VoidCallback onTap;
  const _BinButton({required this.bin, required this.wrong, required this.right, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('${wrong}_$right'),
        tween: Tween(begin: wrong ? 1 : (right ? 0.85 : 1), end: 1),
        duration: const Duration(milliseconds: 350),
        curve: wrong ? Curves.elasticIn : Curves.elasticOut,
        builder: (context, v, child) => Transform.scale(scale: right ? v : 1, child: child),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          BinArt(bin: bin, size: 74, highlighted: right),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: bin.color.withValues(alpha: wrong ? 0.5 : 0.22),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: bin.color.withValues(alpha: 0.7)),
            ),
            child: Text(bin.label,
                style: bodyFont(fontSize: 12.5, fontWeight: FontWeight.w700, color: WiamColors.ink)),
          ),
        ]),
      ),
    );
  }
}
