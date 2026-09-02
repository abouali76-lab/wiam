import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../games/game_catalog.dart';
import '../state/child_device_state.dart';
import '../storage.dart';
import '../theme.dart';
import 'child_timeup_screen.dart';
import 'parent_entry_screen.dart';

class ChildPlayScreen extends StatefulWidget {
  const ChildPlayScreen({super.key});

  @override
  State<ChildPlayScreen> createState() => _ChildPlayScreenState();
}

class _ChildPlayScreenState extends State<ChildPlayScreen> with WidgetsBindingObserver {
  bool _navigatedAway = false;

  /// Guards against ending the same session twice (e.g. backgrounded and
  /// then popped), which would otherwise fire a redundant request.
  bool _sessionClosed = false;

  /// null = showing the game picker. Set = that game is on screen.
  String? _selected;

  // Per-game current unlocked level and a "replay attempt" counter — bumping
  // either forces a fresh widget instance via its ValueKey, which is the
  // simplest way to reset a game's internal state (new shuffle, new run).
  final Map<String, int> _levels = {for (final g in kGames) g.id: 1};
  final Map<String, int> _attempts = {for (final g in kGames) g.id: 0};
  bool _levelsLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<ChildDeviceState>().startPolling();
    _loadLevels();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Leaving the app mid-game shouldn't cost the child the rest of their
    // earned time — bank it and let them resume later.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _closeSession();
    }
  }

  void _closeSession() {
    if (_sessionClosed) return;
    _sessionClosed = true;
    context.read<ChildDeviceState>().endSession();
  }

  Future<void> _loadLevels() async {
    for (final g in kGames) {
      _levels[g.id] = await Storage.loadUnlockedLevel(g.id);
    }
    if (mounted) setState(() => _levelsLoaded = true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<ChildDeviceState>().stopPolling();
    super.dispose();
  }

  String _fmt(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _onLevelComplete(GameInfo game) async {
    final device = context.read<ChildDeviceState>();
    await device.refresh();
    final state = device.state;
    if (state == null) return; // couldn't confirm eligibility, don't guess

    final todayAllDone = state.tasks.isNotEmpty && state.tasks.every((t) => t.isDone);
    final lastLevelUpDate = await Storage.loadLastLevelUpDate(game.id);
    final alreadyLeveledUpToday = lastLevelUpDate == state.date;
    final canAdvance = todayAllDone && !alreadyLeveledUpToday;
    final currentLevel = _levels[game.id]!;

    if (canAdvance) {
      final newLevel = currentLevel + 1;
      await Storage.saveUnlockedLevel(game.id, newLevel);
      await Storage.saveLastLevelUpDate(game.id, state.date);
      if (!mounted) return;
      setState(() {
        _levels[game.id] = newLevel;
        _attempts[game.id] = _attempts[game.id]! + 1;
      });
      _showLevelDialog(
        title: 'رائع! وصلت للمستوى $newLevel 🎉',
        message: 'أحسنت! تجاوزت المستوى السابق بنجاح.',
        color: WiamColors.amber,
      );
    } else {
      if (!mounted) return;
      setState(() => _attempts[game.id] = _attempts[game.id]! + 1);
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

  Widget _buildGame(GameInfo game) {
    final level = _levels[game.id]!;
    final attempt = _attempts[game.id]!;
    return game.build(
      key: ValueKey('${game.id}-$level-$attempt'),
      level: level,
      onComplete: () => _onLevelComplete(game),
    );
  }

  /// Back steps out of a game to the picker first, and only leaves the play
  /// screen from the picker — a child who taps back mid-game expects to land
  /// on the game list, not to lose their whole play session.
  void _back() {
    if (_selected != null) {
      setState(() => _selected = null);
    } else {
      // Leaving the play screen banks the unused time rather than letting
      // the countdown keep running against the child.
      _closeSession();
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
    final game = _selected == null ? null : gameById(_selected);

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
                                key: ValueKey('game-${game.id}'),
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
  final ValueChanged<GameInfo> onPick;
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
            itemCount: kGames.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, i) {
              final g = kGames[i];
              return _GameCard(info: g, level: levels[g.id]!, onTap: () => onPick(g));
            },
          ),
        ),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  final GameInfo info;
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
