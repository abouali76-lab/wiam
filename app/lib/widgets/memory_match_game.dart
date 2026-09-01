import 'dart:math';
import 'package:flutter/material.dart';

import '../theme.dart';
import 'confetti_burst.dart';

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

/// A small memory-match (concentration) game themed around the app's space
/// motif — the actual "play" content behind the countdown timer, replacing
/// the earlier out-of-scope placeholder.
class MemoryMatchGame extends StatefulWidget {
  const MemoryMatchGame({super.key});

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGame> {
  late List<_CardModel> cards;
  List<int> flippedIndexes = [];
  bool locked = false;
  int moves = 0;
  int _winTrigger = 0;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    final pairs = [for (final icon in _icons) ...[icon, icon]];
    final rand = Random();
    final entries = List.generate(pairs.length, (i) => _CardModel(i ~/ 2, pairs[i]));
    entries.shuffle(rand);
    setState(() {
      cards = entries;
      flippedIndexes = [];
      locked = false;
      moves = 0;
    });
  }

  bool get won => cards.every((c) => c.matched);

  Future<void> _tap(int index) async {
    if (locked || cards[index].revealed || cards[index].matched) return;
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
      setState(() {
        cards[a].matched = true;
        cards[b].matched = true;
        locked = false;
        if (won) _winTrigger++;
      });
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
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Text('لعبة الذاكرة', style: displayFont(fontSize: 18, fontWeight: FontWeight.w700, color: WiamColors.ink)),
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
            child: Container(
              color: WiamColors.bg2.withValues(alpha: 0.85),
              child: Stack(children: [
                Positioned.fill(child: ConfettiBurst(trigger: _winTrigger)),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.celebration_rounded, color: WiamColors.amber, size: 42),
                      const SizedBox(height: 12),
                      Text('أحسنت! أنهيت اللعبة', style: displayFont(fontSize: 20, fontWeight: FontWeight.w700, color: WiamColors.ink)),
                      const SizedBox(height: 16),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: WiamColors.amber),
                        onPressed: _newGame,
                        child: Text('العب مرة أخرى', style: bodyFont(fontWeight: FontWeight.w700, color: const Color(0xFF3D2A0E))),
                      ),
                    ],
                  ),
                ),
              ]),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: faceUp
              ? LinearGradient(colors: card.matched ? [WiamColors.teal, WiamColors.teal] : [WiamColors.amber, WiamColors.amberDeep])
              : LinearGradient(colors: [WiamColors.card, WiamColors.planetDim]),
          border: Border.all(color: WiamColors.cardLine),
        ),
        child: Center(
          child: faceUp
              ? Icon(card.icon, color: const Color(0xFF20142A), size: 26)
              : const Icon(Icons.circle, color: WiamColors.inkMuted, size: 8),
        ),
      ),
    );
  }
}
