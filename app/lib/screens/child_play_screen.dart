import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/child_device_state.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets/bubble_pop_game.dart';
import '../widgets/healthy_food_game.dart';
import '../widgets/handwash_game.dart';
import '../widgets/memory_match_game.dart';
import '../widgets/star_catch_game.dart';
import '../widgets/traffic_light_game.dart';
import 'child_timeup_screen.dart';
import 'parent_entry_screen.dart';

enum _Game { memory, stars, bubbles, food, handwash, traffic }

class _GameInfo {
  final _Game id;
  final String storageKey;
  final String label;
  final IconData icon;
  const _GameInfo(this.id, this.storageKey, this.label, this.icon);
}

const _games = [
  _GameInfo(_Game.memory, 'memory', 'الذاكرة', Icons.grid_view_rounded),
  _GameInfo(_Game.stars, 'stars', 'التقاط النجوم', Icons.star_rounded),
  _GameInfo(_Game.bubbles, 'bubbles', 'الفقاعات', Icons.bubble_chart_rounded),
  _GameInfo(_Game.food, 'food', 'الغذاء الصحي', Icons.restaurant_menu),
  _GameInfo(_Game.handwash, 'handwash', 'نظّف يديك', Icons.clean_hands),
  _GameInfo(_Game.traffic, 'traffic', 'إشارة المرور', Icons.traffic),
];

class ChildPlayScreen extends StatefulWidget {
  const ChildPlayScreen({super.key});

  @override
  State<ChildPlayScreen> createState() => _ChildPlayScreenState();
}

class _ChildPlayScreenState extends State<ChildPlayScreen> {
  bool _navigatedAway = false;
  _Game _selected = _Game.memory;

  // Per-game current unlocked level and a "replay attempt" counter — bumping
  // either forces a fresh widget instance via its ValueKey, which is the
  // simplest way to reset a game's internal state (new shuffle, new run).
  final Map<String, int> _levels = {for (final g in _games) g.storageKey: 1};
  final Map<String, int> _attempts = {for (final g in _games) g.storageKey: 0};
  bool _levelsLoaded = false;

  @override
  void initState() {
    super.initState();
    context.read<ChildDeviceState>().startPolling();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    for (final g in _games) {
      _levels[g.storageKey] = await Storage.loadUnlockedLevel(g.storageKey);
    }
    if (mounted) setState(() => _levelsLoaded = true);
  }

  @override
  void dispose() {
    context.read<ChildDeviceState>().stopPolling();
    super.dispose();
  }

  String _fmt(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _onLevelComplete(_GameInfo game) async {
    final device = context.read<ChildDeviceState>();
    await device.refresh();
    final state = device.state;
    if (state == null) return; // couldn't confirm eligibility, don't guess

    final todayAllDone = state.tasks.isNotEmpty && state.tasks.every((t) => t.isDone);
    final lastLevelUpDate = await Storage.loadLastLevelUpDate(game.storageKey);
    final alreadyLeveledUpToday = lastLevelUpDate == state.date;
    final canAdvance = todayAllDone && !alreadyLeveledUpToday;
    final currentLevel = _levels[game.storageKey]!;

    if (canAdvance) {
      final newLevel = currentLevel + 1;
      await Storage.saveUnlockedLevel(game.storageKey, newLevel);
      await Storage.saveLastLevelUpDate(game.storageKey, state.date);
      if (!mounted) return;
      setState(() {
        _levels[game.storageKey] = newLevel;
        _attempts[game.storageKey] = _attempts[game.storageKey]! + 1;
      });
      _showLevelDialog(
        title: 'رائع! وصلت للمستوى $newLevel 🎉',
        message: 'أحسنت! تجاوزت المستوى السابق بنجاح.',
        color: WiamColors.amber,
      );
    } else {
      if (!mounted) return;
      setState(() => _attempts[game.storageKey] = _attempts[game.storageKey]! + 1);
      _showLevelDialog(
        title: 'أحسنت في هذا المستوى! ⭐',
        message: alreadyLeveledUpToday
            ? 'انتقلت لمستوى جديد اليوم بالفعل — عد غداً بعد إنجاز مهامك لتفتح مستوى آخر.'
            : 'أكمل كل مهامك اليوم أولاً من "كوكب الألعاب" لتفتح المستوى التالي.',
        color: WiamColors.teal,
      );
    }
  }

  void _showAccountMenu() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('حساب ولي الأمر', style: bodyFont(fontWeight: FontWeight.w700)),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ParentEntryScreen()));
            },
            child: Row(children: [
              const Icon(Icons.login, size: 20, color: WiamColors.inkMuted),
              const SizedBox(width: 12),
              Text('الدخول كولي أمر', style: bodyFont(fontSize: 15)),
            ]),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx),
            child: Row(children: [
              const Icon(Icons.close, size: 20, color: WiamColors.inkMuted),
              const SizedBox(width: 12),
              Text('إغلاق', style: bodyFont(fontSize: 15)),
            ]),
          ),
        ],
      ),
    );
  }

  void _showLevelDialog({required String title, required String message, required Color color}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: displayFont(fontSize: 18, fontWeight: FontWeight.w700, color: WiamColors.inkLight)),
        content: Text(message, style: bodyFont(fontSize: 14, color: WiamColors.inkMutedLight, height: 1.6)),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: color),
            onPressed: () => Navigator.pop(ctx),
            child: Text('حسناً', style: bodyFont(fontWeight: FontWeight.w700, color: const Color(0xFF20142A))),
          ),
        ],
      ),
    );
  }

  Widget _buildGame(_GameInfo game) {
    final level = _levels[game.storageKey]!;
    final attempt = _attempts[game.storageKey]!;
    final key = ValueKey('${game.storageKey}-$level-$attempt');
    switch (game.id) {
      case _Game.memory:
        return MemoryMatchGame(key: key, level: level, onLevelComplete: () => _onLevelComplete(game));
      case _Game.stars:
        return StarCatchGame(key: key, level: level, onLevelComplete: () => _onLevelComplete(game));
      case _Game.bubbles:
        return BubblePopGame(key: key, level: level, onLevelComplete: () => _onLevelComplete(game));
      case _Game.food:
        return HealthyFoodGame(key: key, level: level, onLevelComplete: () => _onLevelComplete(game));
      case _Game.handwash:
        return HandwashGame(key: key, level: level, onLevelComplete: () => _onLevelComplete(game));
      case _Game.traffic:
        return TrafficLightGame(key: key, level: level, onLevelComplete: () => _onLevelComplete(game));
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = context.watch<ChildDeviceState>();
    final session = device.state?.activeSession;

    if (session != null && session.ended && !_navigatedAway) {
      _navigatedAway = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ChildTimeUpScreen()));
      });
    }

    final remaining = session?.remainingSec ?? 0;
    final total = session?.durationSec ?? 1;
    final ratio = (remaining / total).clamp(0, 1).toDouble();
    // Warn gently in the last two minutes rather than cutting off abruptly.
    final soon = remaining <= 120;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [WiamColors.bg1, WiamColors.bg2])),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: WiamColors.inkMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: WiamColors.card.withValues(alpha: 0.9), border: Border.all(color: WiamColors.cardLine), borderRadius: BorderRadius.circular(22)),
                  child: Column(children: [
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: Stack(alignment: Alignment.center, children: [
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: CircularProgressIndicator(value: ratio, strokeWidth: 6, backgroundColor: WiamColors.planetDim, color: soon ? WiamColors.coral : WiamColors.amber),
                        ),
                        Text(_fmt(remaining), style: displayFont(fontSize: 15, fontWeight: FontWeight.w700, color: WiamColors.ink)),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    Text(soon ? 'الوقت أوشك على الانتهاء' : 'الوقت المتبقي', style: bodyFont(fontSize: 10.5, color: WiamColors.inkMuted)),
                  ]),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.person_outline, color: WiamColors.inkMuted),
                  onPressed: _showAccountMenu,
                ),
              ]),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final game in _games) ...[
                      _GameTab(info: game, level: _levels[game.storageKey]!, selected: _selected == game.id, onTap: () => setState(() => _selected = game.id)),
                      if (game != _games.last) const SizedBox(width: 10),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  width: double.infinity,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), border: Border.all(color: WiamColors.planetDim, width: 2), color: WiamColors.bg1.withValues(alpha: 0.5)),
                  clipBehavior: Clip.antiAlias,
                  child: !_levelsLoaded
                      ? const Center(child: CircularProgressIndicator(color: WiamColors.amber))
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _buildGame(_games.firstWhere((g) => g.id == _selected)),
                        ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _GameTab extends StatelessWidget {
  final _GameInfo info;
  final int level;
  final bool selected;
  final VoidCallback onTap;
  const _GameTab({required this.info, required this.level, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? WiamColors.amber : WiamColors.card,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(info.icon, size: 16, color: selected ? const Color(0xFF3D2A0E) : WiamColors.inkMuted),
            const SizedBox(width: 6),
            Text('${info.label} • $level', style: bodyFont(fontSize: 12.5, fontWeight: FontWeight.w700, color: selected ? const Color(0xFF3D2A0E) : WiamColors.inkMuted)),
          ]),
        ),
      ),
    );
  }
}
