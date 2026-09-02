import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/child_device_state.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets/bubble_pop_game.dart';
import '../widgets/feelings_game.dart';
import '../widgets/healthy_food_game.dart';
import '../widgets/handwash_game.dart';
import '../widgets/market_game.dart';
import '../widgets/memory_match_game.dart';
import '../widgets/star_catch_game.dart';
import '../widgets/traffic_light_game.dart';
import '../widgets/waste_sort_game.dart';
import 'child_timeup_screen.dart';
import 'parent_entry_screen.dart';

enum _Game { memory, stars, bubbles, food, handwash, traffic, waste, feelings, market }

class _GameInfo {
  final _Game id;
  final String storageKey;
  final String label;

  /// What the game is actually teaching — shown on the card so a parent
  /// glancing over the child's shoulder can see this is not just filler.
  final String tag;
  final IconData icon;
  final Color color;
  const _GameInfo(this.id, this.storageKey, this.label, this.tag, this.icon, this.color);
}

const _games = [
  _GameInfo(_Game.memory, 'memory', 'الذاكرة', 'تركيز', Icons.grid_view_rounded, Color(0xFF7B6BC4)),
  _GameInfo(_Game.stars, 'stars', 'التقاط النجوم', 'تناسق حركي', Icons.star_rounded, Color(0xFFE0A93F)),
  _GameInfo(_Game.bubbles, 'bubbles', 'الفقاعات', 'سرعة بديهة', Icons.bubble_chart_rounded, Color(0xFF4E9FC4)),
  _GameInfo(_Game.food, 'food', 'الغذاء الصحي', 'تغذية', Icons.restaurant_menu, Color(0xFF5FAE72)),
  _GameInfo(_Game.handwash, 'handwash', 'نظّف يديك', 'نظافة', Icons.clean_hands, Color(0xFF4EAFA8)),
  _GameInfo(_Game.traffic, 'traffic', 'إشارة المرور', 'سلامة', Icons.traffic, Color(0xFFD9645A)),
  _GameInfo(_Game.waste, 'waste', 'فرز النفايات', 'بيئة', Icons.recycling_rounded, Color(0xFF5B8FD1)),
  _GameInfo(_Game.feelings, 'feelings', 'دائرة المشاعر', 'مشاعر', Icons.favorite_rounded, Color(0xFFD97BA0)),
  _GameInfo(_Game.market, 'market', 'سوق المعرفة', 'حساب', Icons.storefront_rounded, Color(0xFFDE9142)),
];

class ChildPlayScreen extends StatefulWidget {
  const ChildPlayScreen({super.key});

  @override
  State<ChildPlayScreen> createState() => _ChildPlayScreenState();
}

class _ChildPlayScreenState extends State<ChildPlayScreen> {
  bool _navigatedAway = false;

  /// null = showing the game picker. Set = that game is on screen.
  _Game? _selected;

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
      case _Game.waste:
        return WasteSortGame(key: key, level: level, onLevelComplete: () => _onLevelComplete(game));
      case _Game.feelings:
        return FeelingsGame(key: key, level: level, onLevelComplete: () => _onLevelComplete(game));
      case _Game.market:
        return MarketGame(key: key, level: level, onLevelComplete: () => _onLevelComplete(game));
    }
  }

  /// Back steps out of a game to the picker first, and only leaves the play
  /// screen from the picker — a child who taps back mid-game expects to land
  /// on the game list, not to lose their whole play session.
  void _back() {
    if (_selected != null) {
      setState(() => _selected = null);
    } else {
      Navigator.of(context).pop();
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
    final game = _selected == null ? null : _games.firstWhere((g) => g.id == _selected);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [WiamColors.bg1, WiamColors.bg2],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(children: [
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: WiamColors.inkMuted),
                  onPressed: _back,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: WiamColors.card.withValues(alpha: 0.9),
                    border: Border.all(color: WiamColors.cardLine),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: Stack(alignment: Alignment.center, children: [
                        SizedBox(
                          width: 42,
                          height: 42,
                          child: CircularProgressIndicator(
                            value: ratio,
                            strokeWidth: 4.5,
                            backgroundColor: WiamColors.planetDim,
                            color: soon ? WiamColors.coral : WiamColors.amber,
                          ),
                        ),
                        Icon(Icons.timer_outlined, size: 16, color: soon ? WiamColors.coral : WiamColors.amber),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_fmt(remaining),
                          style: displayFont(fontSize: 18, fontWeight: FontWeight.w800, color: WiamColors.ink)),
                      Text(soon ? 'أوشك على الانتهاء' : 'الوقت المتبقي',
                          style: bodyFont(fontSize: 10, color: WiamColors.inkMuted)),
                    ]),
                  ]),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.person_outline, color: WiamColors.inkMuted),
                  onPressed: _showAccountMenu,
                ),
              ]),
              const SizedBox(height: 10),
              Expanded(
                child: !_levelsLoaded
                    ? const Center(child: CircularProgressIndicator(color: WiamColors.amber))
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        child: game == null
                            ? _GamePicker(
                                key: const ValueKey('picker'),
                                levels: _levels,
                                onPick: (g) => setState(() => _selected = g.id),
                              )
                            : Container(
                                key: ValueKey('game-${game.storageKey}'),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(color: game.color.withValues(alpha: 0.55), width: 2),
                                  color: WiamColors.bg1.withValues(alpha: 0.5),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _buildGame(game),
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

class _GamePicker extends StatelessWidget {
  final Map<String, int> levels;
  final ValueChanged<_GameInfo> onPick;
  const _GamePicker({super.key, required this.levels, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('اختر لعبتك 🎮',
            textAlign: TextAlign.center,
            style: displayFont(fontSize: 20, fontWeight: FontWeight.w700, color: WiamColors.ink)),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: _games.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, i) {
              final g = _games[i];
              return _GameCard(info: g, level: levels[g.storageKey]!, onTap: () => onPick(g));
            },
          ),
        ),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  final _GameInfo info;
  final int level;
  final VoidCallback onTap;
  const _GameCard({required this.info, required this.level, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(info.color, Colors.white, 0.14)!,
                Color.lerp(info.color, Colors.black, 0.28)!,
              ],
            ),
            boxShadow: [
              BoxShadow(color: info.color.withValues(alpha: 0.32), blurRadius: 14, offset: const Offset(0, 5)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.22),
                ),
                child: Icon(info.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                info.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: bodyFont(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('مستوى $level',
                    style: bodyFont(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(height: 3),
              Text(info.tag,
                  style: bodyFont(fontSize: 9.5, color: Colors.white.withValues(alpha: 0.75))),
            ],
          ),
        ),
      ),
    );
  }
}
