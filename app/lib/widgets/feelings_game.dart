import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'art/emotion_art.dart';
import 'game_backdrop.dart';

/// دائرة المشاعر — a everyday situation is described, and the child picks
/// the face that matches how they'd feel. Answers are faces *and* words, so
/// it works before a child can read while still teaching the vocabulary.
/// No fail state: a wrong pick just shakes, the round continues.
class FeelingsGame extends StatefulWidget {
  final int level;
  final VoidCallback onLevelComplete;
  const FeelingsGame({super.key, required this.level, required this.onLevelComplete});

  @override
  State<FeelingsGame> createState() => _FeelingsGameState();
}

class _FeelingsGameState extends State<FeelingsGame> {
  final _rand = Random();
  late Emotion _answer;
  late List<Emotion> _choices;
  int _score = 0;
  bool _reported = false;
  Emotion? _wrong;
  bool _correct = false;
  Timer? _timer;

  int get _target => 3 + widget.level * 2;
  // More decoys as the level rises, so the same situations stay a challenge.
  int get _choiceCount => (3 + (widget.level - 1) ~/ 2).clamp(3, 4);

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _newRound() {
    final all = List<Emotion>.from(Emotion.values)..shuffle(_rand);
    _answer = all.first;
    _choices = [_answer, ...all.skip(1).take(_choiceCount - 1)]..shuffle(_rand);
    _wrong = null;
    _correct = false;
  }

  void _pick(Emotion e) {
    if (_correct || _score >= _target) return;
    if (e == _answer) {
      HapticFeedback.lightImpact();
      setState(() {
        _correct = true;
        _wrong = null;
        _score++;
      });
      if (_score >= _target && !_reported) {
        _reported = true;
        HapticFeedback.heavyImpact();
        _timer = Timer(const Duration(milliseconds: 800), () {
          if (mounted) widget.onLevelComplete();
        });
        return;
      }
      _timer = Timer(const Duration(milliseconds: 800), () {
        if (mounted) setState(_newRound);
      });
    } else {
      HapticFeedback.mediumImpact();
      setState(() => _wrong = e);
      _timer = Timer(const Duration(milliseconds: 450), () {
        if (mounted) setState(() => _wrong = null);
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
                const Icon(Icons.favorite_rounded, color: WiamColors.coral, size: 18),
                const SizedBox(width: 6),
                Text('دائرة المشاعر — المستوى ${widget.level}',
                    style: displayFont(fontSize: 16, fontWeight: FontWeight.w700, color: WiamColors.ink)),
                const Spacer(),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text('$_score / $_target',
                      style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700, color: WiamColors.inkMuted)),
                ),
              ]),
              Expanded(
                child: cleared
                    ? Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const EmotionFace(emotion: Emotion.proud, size: 84),
                          const SizedBox(height: 12),
                          Text('أنت تفهم مشاعرك جيداً! 💛',
                              style: displayFont(fontSize: 17, fontWeight: FontWeight.w700, color: WiamColors.ink)),
                        ]),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            decoration: BoxDecoration(
                              color: WiamColors.card.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: WiamColors.cardLine),
                            ),
                            child: Column(children: [
                              Text('كيف تشعر لو...',
                                  style: bodyFont(fontSize: 12.5, color: WiamColors.inkMuted)),
                              const SizedBox(height: 6),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: Text(
                                  _answer.situation,
                                  key: ValueKey(_answer),
                                  textAlign: TextAlign.center,
                                  style: displayFont(
                                      fontSize: 17, fontWeight: FontWeight.w700, color: WiamColors.ink, height: 1.4),
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 22),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 14,
                            runSpacing: 12,
                            children: [
                              for (final e in _choices)
                                _FaceChoice(
                                  emotion: e,
                                  wrong: _wrong == e,
                                  right: _correct && e == _answer,
                                  dimmed: _correct && e != _answer,
                                  onTap: () => _pick(e),
                                ),
                            ],
                          ),
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

class _FaceChoice extends StatelessWidget {
  final Emotion emotion;
  final bool wrong;
  final bool right;
  final bool dimmed;
  final VoidCallback onTap;
  const _FaceChoice({
    required this.emotion,
    required this.wrong,
    required this.right,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: dimmed ? 0.32 : 1,
        duration: const Duration(milliseconds: 250),
        child: TweenAnimationBuilder<double>(
          key: ValueKey('$wrong$right'),
          tween: Tween(begin: right ? 0.8 : (wrong ? 1.08 : 1), end: 1),
          duration: const Duration(milliseconds: 380),
          curve: Curves.elasticOut,
          builder: (context, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: WiamColors.card.withValues(alpha: 0.6),
              border: Border.all(
                color: right
                    ? const Color(0xFF7ED4A4)
                    : (wrong ? WiamColors.coral : WiamColors.cardLine),
                width: right || wrong ? 2.5 : 1,
              ),
              boxShadow: right
                  ? [BoxShadow(color: const Color(0xFF7ED4A4).withValues(alpha: 0.4), blurRadius: 16)]
                  : null,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              EmotionFace(emotion: emotion, size: 62),
              const SizedBox(height: 6),
              Text(emotion.label,
                  style: bodyFont(fontSize: 12.5, fontWeight: FontWeight.w700, color: WiamColors.ink)),
            ]),
          ),
        ),
      ),
    );
  }
}
