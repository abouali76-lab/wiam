import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'art/food_art.dart';
import 'game_backdrop.dart';

/// سوق المعرفة — counting and simple arithmetic made concrete: two baskets
/// of real fruit, how many altogether? The child counts pictures rather than
/// reading symbols, so it works well before they know their numerals, and
/// the level raises the range (and later swaps in subtraction).
class MarketGame extends StatefulWidget {
  final int level;
  final VoidCallback onLevelComplete;
  const MarketGame({super.key, required this.level, required this.onLevelComplete});

  @override
  State<MarketGame> createState() => _MarketGameState();
}

class _MarketGameState extends State<MarketGame> {
  final _rand = Random();
  late int _left;
  late int _right;
  late bool _subtract;
  late FoodKind _fruit;
  late List<int> _choices;
  int _score = 0;
  bool _reported = false;
  int? _wrong;
  bool _correct = false;
  Timer? _timer;

  static const _fruits = [FoodKind.apple, FoodKind.banana, FoodKind.carrot, FoodKind.grapes, FoodKind.egg];

  int get _target => 3 + widget.level * 2;
  int get _answer => _subtract ? _left - _right : _left + _right;
  // Subtraction only appears once the child has cleared a few levels.
  bool get _allowSubtraction => widget.level >= 3;
  int get _maxPer => (2 + widget.level).clamp(2, 6);

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
    _subtract = _allowSubtraction && _rand.nextBool();
    _fruit = _fruits[_rand.nextInt(_fruits.length)];
    if (_subtract) {
      _left = 2 + _rand.nextInt(_maxPer);
      _right = 1 + _rand.nextInt(_left - 1);
    } else {
      _left = 1 + _rand.nextInt(_maxPer);
      _right = 1 + _rand.nextInt(_maxPer);
    }
    final answer = _answer;
    final options = <int>{answer};
    while (options.length < 3) {
      final delta = _rand.nextInt(3) + 1;
      final candidate = _rand.nextBool() ? answer + delta : answer - delta;
      if (candidate >= 0) options.add(candidate);
    }
    _choices = options.toList()..shuffle(_rand);
    _wrong = null;
    _correct = false;
  }

  void _pick(int value) {
    if (_correct || _score >= _target) return;
    if (value == _answer) {
      HapticFeedback.lightImpact();
      setState(() {
        _correct = true;
        _wrong = null;
        _score++;
      });
      if (_score >= _target && !_reported) {
        _reported = true;
        HapticFeedback.heavyImpact();
        _timer = Timer(const Duration(milliseconds: 750), () {
          if (mounted) widget.onLevelComplete();
        });
        return;
      }
      _timer = Timer(const Duration(milliseconds: 750), () {
        if (mounted) setState(_newRound);
      });
    } else {
      HapticFeedback.mediumImpact();
      setState(() => _wrong = value);
      _timer = Timer(const Duration(milliseconds: 420), () {
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
                const Icon(Icons.storefront_rounded, color: WiamColors.amber, size: 18),
                const SizedBox(width: 6),
                Text('سوق المعرفة — المستوى ${widget.level}',
                    style: displayFont(fontSize: 16, fontWeight: FontWeight.w700, color: WiamColors.ink)),
                const Spacer(),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text('$_score / $_target',
                      style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700, color: WiamColors.inkMuted)),
                ),
              ]),
              const SizedBox(height: 4),
              Text(_subtract ? 'كم يتبقى؟' : 'كم المجموع؟',
                  style: bodyFont(fontSize: 12.5, color: WiamColors.inkMuted)),
              Expanded(
                child: cleared
                    ? Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.workspace_premium_rounded, color: WiamColors.amber, size: 54),
                          const SizedBox(height: 10),
                          Text('حسبت كل شيء بشكل صحيح! 🧮',
                              style: displayFont(fontSize: 17, fontWeight: FontWeight.w700, color: WiamColors.ink)),
                        ]),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Directionality(
                              key: ValueKey('$_left$_right$_subtract$_fruit'),
                              // The whole sum is one left-to-right expression;
                              // inside the app's RTL context its parts would
                              // otherwise be reordered.
                              textDirection: TextDirection.ltr,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Flexible so the baskets shrink (and their
                                  // fruit wraps onto a second row) instead of
                                  // overflowing once the counts grow at higher
                                  // levels.
                                  Flexible(child: _Basket(count: _left, fruit: _fruit, faded: false)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      _subtract ? '−' : '+',
                                      style: displayFont(
                                          fontSize: 34, fontWeight: FontWeight.w800, color: WiamColors.amber),
                                    ),
                                  ),
                                  Flexible(child: _Basket(count: _right, fruit: _fruit, faded: _subtract)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (final c in _choices) ...[
                                _NumberChoice(
                                  value: c,
                                  wrong: _wrong == c,
                                  right: _correct && c == _answer,
                                  dimmed: _correct && c != _answer,
                                  onTap: () => _pick(c),
                                ),
                                if (c != _choices.last) const SizedBox(width: 14),
                              ],
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

class _Basket extends StatelessWidget {
  final int count;
  final FoodKind fruit;
  /// The "taken away" group in a subtraction — shown crossed out so the
  /// child sees what leaving means rather than just a minus sign.
  final bool faded;
  const _Basket({required this.count, required this.fruit, required this.faded});

  @override
  Widget build(BuildContext context) {
    // Shrink the fruit a little once a basket holds a lot, so a full
    // basket stays two tidy rows rather than a long thin strip.
    final itemSize = count > 4 ? 26.0 : 30.0;
    return Container(
      constraints: const BoxConstraints(minWidth: 84),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: WiamColors.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WiamColors.cardLine),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: [
          for (int i = 0; i < count; i++)
            Opacity(
              opacity: faded ? 0.35 : 1,
              child: Stack(alignment: Alignment.center, children: [
                FoodArt(kind: fruit, size: itemSize),
                if (faded)
                  Container(
                    width: itemSize - 4,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: WiamColors.coral,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ]),
            ),
        ],
      ),
    );
  }
}

class _NumberChoice extends StatelessWidget {
  final int value;
  final bool wrong;
  final bool right;
  final bool dimmed;
  final VoidCallback onTap;
  const _NumberChoice({
    required this.value,
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
        opacity: dimmed ? 0.3 : 1,
        duration: const Duration(milliseconds: 250),
        child: TweenAnimationBuilder<double>(
          key: ValueKey('$wrong$right'),
          tween: Tween(begin: right ? 0.78 : (wrong ? 1.1 : 1), end: 1),
          duration: const Duration(milliseconds: 380),
          curve: Curves.elasticOut,
          builder: (context, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: right
                    ? [const Color(0xFF7ED4A4), const Color(0xFF3F9E6B)]
                    : (wrong
                        ? [WiamColors.coral, WiamColors.coralDeep]
                        : [WiamColors.amber, WiamColors.amberDeep]),
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: (right ? const Color(0xFF7ED4A4) : WiamColors.amber).withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text('$value',
                style: displayFont(fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFF3D2A0E))),
          ),
        ),
      ),
    );
  }
}
