import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../games/game_catalog.dart';
import '../models.dart';
import '../state/child_device_state.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets/confetti_burst.dart';

/// A digital task being *done*, rather than ticked off.
///
/// The child plays one round of the educational game the parent bound to
/// the task; clearing it is what marks the task complete and releases its
/// minutes. Deliberately not a play session — this is the work that earns
/// play time, so it costs the child nothing and has no countdown.
class ChildActivityScreen extends StatefulWidget {
  final TaskItem task;
  const ChildActivityScreen({super.key, required this.task});

  @override
  State<ChildActivityScreen> createState() => _ChildActivityScreenState();
}

class _ChildActivityScreenState extends State<ChildActivityScreen> {
  int _level = 1;
  int _attempt = 0;
  bool _loaded = false;
  bool _completing = false;
  bool _done = false;
  int _confetti = 0;
  String? _error;

  GameInfo get _game => gameById(widget.task.gameId)!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // The activity uses the same level the child has reached in free play,
    // so the work scales with them instead of staying trivial forever.
    final level = await Storage.loadUnlockedLevel(_game.id);
    if (mounted) {
      setState(() {
        _level = level;
        _loaded = true;
      });
    }
  }

  Future<void> _onCleared() async {
    if (_completing || _done) return;
    setState(() {
      _completing = true;
      _error = null;
    });
    try {
      await context.read<ChildDeviceState>().completeDigitalTask(widget.task.taskId);
      if (!mounted) return;
      setState(() {
        _done = true;
        _confetti++;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر حفظ إنجازك، تحقق من الشبكة';
        // Let them try the round again rather than stranding the task.
        _attempt++;
      });
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Column(children: [
                    Text(
                      widget.task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: displayFont(fontSize: 17, fontWeight: FontWeight.w700, color: WiamColors.ink),
                    ),
                    Text('نشاط اليوم • ${_game.tag}',
                        style: bodyFont(fontSize: 11.5, color: WiamColors.inkMuted)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: WiamColors.amber.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded, size: 15, color: WiamColors.amber),
                    const SizedBox(width: 5),
                    Text('+${widget.task.rewardMinutes} د',
                        style: bodyFont(fontSize: 12.5, fontWeight: FontWeight.w700, color: WiamColors.amber)),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: gameFrame(_game.color),
                  clipBehavior: Clip.antiAlias,
                  child: !_loaded
                      ? const Center(child: CircularProgressIndicator(color: WiamColors.amber))
                      : Stack(children: [
                          Positioned.fill(
                            child: _game.build(
                              key: ValueKey('${_game.id}-$_level-$_attempt'),
                              level: _level,
                              onComplete: _onCleared,
                            ),
                          ),
                          if (_done)
                            Positioned.fill(child: _DoneOverlay(trigger: _confetti, minutes: widget.task.rewardMinutes)),
                        ]),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, textAlign: TextAlign.center, style: bodyFont(fontSize: 12.5, color: WiamColors.coral)),
              ],
              const SizedBox(height: 10),
              if (_done)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: WiamColors.amber,
                    foregroundColor: const Color(0xFF3D2A0E),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('رجوع إلى مهامي',
                      style: bodyFont(fontWeight: FontWeight.w700, color: const Color(0xFF3D2A0E))),
                )
              else
                Text(
                  'أنهِ هذا النشاط لتكسب ${widget.task.rewardMinutes} دقيقة لعب',
                  textAlign: TextAlign.center,
                  style: bodyFont(fontSize: 12.5, color: WiamColors.inkMuted),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _DoneOverlay extends StatelessWidget {
  final int trigger;
  final int minutes;
  const _DoneOverlay({required this.trigger, required this.minutes});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        color: WiamColors.bg2.withValues(alpha: 0.82),
        child: Stack(children: [
          Positioned.fill(child: ConfettiBurst(trigger: trigger)),
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.workspace_premium_rounded, color: WiamColors.amber, size: 62),
              const SizedBox(height: 14),
              Text('أنجزت النشاط! 🎉',
                  style: displayFont(fontSize: 22, fontWeight: FontWeight.w800, color: WiamColors.ink)),
              const SizedBox(height: 8),
              Text('كسبت $minutes دقيقة لعب',
                  style: bodyFont(fontSize: 15, fontWeight: FontWeight.w700, color: WiamColors.amber)),
            ]),
          ),
        ]),
      ),
    );
  }
}
