import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'confetti_burst.dart';
import 'game_backdrop.dart';

class _CardModel {
  final int pairId;
  final IconData icon;
  bool revealed = false;
  bool matched = false;
  _CardModel(this.pairId, this.icon);
}

const _icons = [
  Icons.star_rounded,
  Icons.nightlight_round,
  Icons.rocket_launch_rounded,
  Icons.satellite_alt_rounded,
  Icons.public_rounded,
  Icons.auto_awesome_rounded,
];

const _iconColors = [WiamColors.amber, WiamColors.teal, Color(0xFFE8794A), Color(0xFF8FA7E8), Color(0xFFF4D48C), Color(0xFFD98FE8)];

/// A small memory-match (concentration) game themed around the app's space
/// motif. Levels scale the number of pairs (2 at level 1 up to all 6 icons
/// at level 5+); clearing a level hands off to [onLevelComplete] rather
/// than offering its own "play again" — ChildPlayScreen owns what happens
/// next (advance a level or ask to come back after today's tasks).
class MemoryMatchGame extends StatefulWidget {
  final int level;
  final VoidCallback onLevelComplete;
  const MemoryMatchGame({super.key, required this.level, required this.onLevelComplete});

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGame> {
  late List<_CardModel> cards;
  List<int> flippedIndexes = [];
  bool locked = false;
  int moves = 0;
  int _winTrigger = 0;
  bool _reported = false;

  int get _pairCount => (widget.level + 1).clamp(2, _icons.length);

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    final chosenIcons = _icons.sublist(0, _pairCount);
    final pairs = [for (final icon in chosenIcons) ...[icon, icon]];
    final rand = Random();
    final entries = List.generate(pairs.length, (i) => _CardModel(i ~/ 2, pairs[i]));
    entries.shuffle(rand);
    setState(() {
      cards = entries;
      flippedIndexes = [];
      locked = false;
      moves = 0;
      _reported = false;
    });
  }

  bool get won => cards.every((c) => c.matched);

  Future<void> _tap(int index) async {
    if (locked || cards[index].revealed || cards[index].matched) return;
    HapticFeedback.selectionClick();
    setState(() => cards[index].revealed = true);
    flippedIndexes.add(index);

    if (flippedIndexes.length < 2) return;

    setState(() {
      locked = true;
      moves++;
    });
    final a = flippedIndexes[0];
    final b = flippedIndexes[1];
    flippedIndexes = [];

    if (cards[a].pairId == cards[b].pairId) {
      await Future.delayed(const Duration(milliseconds: 250));
      HapticFeedback.mediumImpact();
      setState(() {
        cards[a].matched = true;
        cards[b].matched = true;
        locked = false;
        if (won) _winTrigger++;
      });
      if (won && !_reported) {
        _reported = true;
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) widget.onLevelComplete();
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 700));
      setState(() {
        cards[a].revealed = false;
        cards[b].revealed = false;
        locked = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: GameBackdrop()),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Text('لعبة الذاكرة — المستوى ${widget.level}', style: displayFont(fontSize: 18, fontWeight: FontWeight.w700, color: WiamColors.ink)),
              const SizedBox(height: 4),
              Text('طابق كل بطاقتين متشابهتين — عدد المحاولات: $moves', style: bodyFont(fontSize: 12, color: WiamColors.inkMuted)),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  itemCount: cards.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemBuilder: (context, i) => _CardTile(card: cards[i], onTap: () => _tap(i)),
                ),
              ),
            ],
          ),
        ),
        if (won)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: WiamColors.bg2.withValues(alpha: 0.6),
                child: Stack(children: [
                  Positioned.fill(child: ConfettiBurst(trigger: _winTrigger)),
                  const Center(child: Icon(Icons.celebration_rounded, color: WiamColors.amber, size: 48)),
                ]),
              ),
            ),
          ),
      ],
    );
  }
}

class _CardTile extends StatelessWidget {
  final _CardModel card;
  final VoidCallback onTap;
  const _CardTile({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final faceUp = card.revealed || card.matched;
    final color = _iconColors[card.pairId % _iconColors.length];
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(faceUp),
        tween: Tween(begin: faceUp ? 0 : 1, end: faceUp ? 1 : 0),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutBack,
        builder: (context, t, _) {
          // A cheap 3D-card-flip illusion: scale the X axis down to zero at
          // the midpoint, then swap face and grow back out.
          final showBack = t < 0.5;
          final scaleX = (1 - t * 2).abs();
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..setEntry(3, 2, 0.0015),
            child: Transform.scale(
              scaleX: scaleX.clamp(0.05, 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: showBack
                      ? const LinearGradient(colors: [WiamColors.card, WiamColors.planetDim])
                      : LinearGradient(colors: card.matched ? [WiamColors.teal, const Color(0xFF4FA0A2)] : [color, color.withValues(alpha: 0.75)]),
                  border: Border.all(color: card.matched ? WiamColors.teal : WiamColors.cardLine, width: card.matched ? 2 : 1),
                  boxShadow: card.matched
                      ? [BoxShadow(color: WiamColors.teal.withValues(alpha: 0.5), blurRadius: 14, spreadRadius: 1)]
                      : (!showBack ? [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 10)] : null),
                ),
                child: Center(
                  child: showBack
                      ? const Icon(Icons.auto_awesome_rounded, color: WiamColors.inkMuted, size: 14)
                      : Icon(card.icon, color: const Color(0xFF20142A), size: 26),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
