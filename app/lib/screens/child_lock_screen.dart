import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/child_device_state.dart';
import '../theme.dart';
import '../widgets/confetti_burst.dart';
import '../widgets/mascot.dart';
import 'child_play_screen.dart';
import 'parent_entry_screen.dart';

class ChildLockScreen extends StatefulWidget {
  const ChildLockScreen({super.key});

  @override
  State<ChildLockScreen> createState() => _ChildLockScreenState();
}

class _ChildLockScreenState extends State<ChildLockScreen> {
  Timer? _poller;
  int _lastDone = -1;
  int _confettiTrigger = 0;

  @override
  void initState() {
    super.initState();
    _poller = Timer.periodic(const Duration(seconds: 4), (_) => context.read<ChildDeviceState>().refresh());
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _startPlay() async {
    final device = context.read<ChildDeviceState>();
    await device.startSession();
    if (mounted) Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChildPlayScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final device = context.watch<ChildDeviceState>();
    final state = device.state;

    if (state == null) {
      return const Scaffold(backgroundColor: WiamColors.bg2, body: Center(child: CircularProgressIndicator(color: WiamColors.amber)));
    }

    final done = state.tasks.where((t) => t.isDone).length;
    final total = state.tasks.length;
    final ratio = total == 0 ? 0.0 : done / total;
    final canPlay = state.availableSeconds > 0;

    // A task just got completed since the last build — celebrate it. Guard
    // with _lastDone >= 0 so the very first load (going from "unknown" to
    // whatever the server already has) doesn't fire a burst on its own.
    if (_lastDone >= 0 && done > _lastDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _confettiTrigger++);
      });
    }
    _lastDone = done;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [WiamColors.bg1, WiamColors.bg2])),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(children: [
              Row(children: [
                Text('وئام', style: displayFont(fontSize: 20, fontWeight: FontWeight.w700, color: WiamColors.ink)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.person_outline, color: WiamColors.inkMuted), onPressed: () => _showAccountMenu(context)),
              ]),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(children: [
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 240,
                      child: Stack(alignment: Alignment.center, children: [
                        _Planet(locked: !canPlay),
                        Positioned(top: 0, child: Mascot(mood: canPlay ? MascotMood.happy : MascotMood.waiting, size: 76)),
                        Positioned.fill(child: ConfettiBurst(trigger: _confettiTrigger)),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    Text('كوكب الألعاب يستمد طاقته من إنجازاتك!',
                        textAlign: TextAlign.center, style: displayFont(fontSize: 26, fontWeight: FontWeight.w700, color: WiamColors.ink, height: 1.3)),
                    const SizedBox(height: 8),
                    Text('أكمل مهامك اليوم لتفتح بوابة اللعب', textAlign: TextAlign.center, style: bodyFont(fontSize: 15, color: WiamColors.inkMuted)),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: WiamColors.card, border: Border.all(color: WiamColors.cardLine), borderRadius: BorderRadius.circular(22)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text('مهامك اليوم', style: bodyFont(fontSize: 15, fontWeight: FontWeight.w700, color: WiamColors.ink)),
                          const Spacer(),
                          Text('أُنجز $done من $total', style: bodyFont(fontSize: 12.5, color: WiamColors.inkMuted)),
                        ]),
                        const SizedBox(height: 8),
                        for (final task in state.tasks) _TaskRow(task: task, onTapDigital: task.isDigital && !task.isDone ? () => device.completeDigitalTask(task.taskId) : null),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: ratio),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) =>
                                LinearProgressIndicator(value: value, minHeight: 7, backgroundColor: WiamColors.planetDim.withValues(alpha: 0.4), color: WiamColors.amber),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),
                    TweenAnimationBuilder<double>(
                      key: ValueKey(state.availableSeconds),
                      tween: Tween(begin: 0.75, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: canPlay ? _startPlay : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: LinearGradient(colors: canPlay ? [WiamColors.amber, WiamColors.amberDeep] : [WiamColors.planetDim, WiamColors.planetDim]),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.star_rounded, color: Color(0xFF3D2A0E), size: 20),
                              const SizedBox(width: 10),
                              Text(
                                canPlay ? '${(state.availableSeconds / 60).ceil()} دقيقة لعب بانتظارك' : 'أكمل مهامك لفتح اللعب',
                                style: bodyFont(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF3D2A0E)),
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showAccountMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('حساب ولي الأمر', style: bodyFont(fontWeight: FontWeight.w700)),
        children: [
          // Pushes on top of this screen without touching the child's
          // pairing — both stay signed in at once, so coming back just
          // pops this route. Still gated by the parent's own login.
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
            onPressed: () {
              Navigator.pop(ctx);
              _confirmUnpair(context);
            },
            child: Row(children: [
              const Icon(Icons.link_off, size: 20, color: WiamColors.coralDeep),
              const SizedBox(width: 12),
              Text('إلغاء ربط هذا الجهاز', style: bodyFont(fontSize: 15, color: WiamColors.coralDeep)),
            ]),
          ),
        ],
      ),
    );
  }

  void _confirmUnpair(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء ربط هذا الجهاز؟'),
        content: const Text('يستخدم هذا فقط لإعادة إعداد الجهاز من طرف ولي الأمر.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              await context.read<ChildDeviceState>().unpair();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('إلغاء الربط'),
          ),
        ],
      ),
    );
  }
}

class _Planet extends StatelessWidget {
  final bool locked;
  const _Planet({required this.locked});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(alignment: Alignment.center, children: [
        Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: WiamColors.inkMuted.withValues(alpha: 0.35), width: 2),
          ),
        ),
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(center: const Alignment(-0.3, -0.4), colors: locked ? [WiamColors.inkMuted, WiamColors.planetDim] : [WiamColors.amber, WiamColors.amberDeep]),
          ),
        ),
        if (locked)
          Positioned(
            bottom: 6,
            right: 6,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [WiamColors.amber, WiamColors.amberDeep]), border: Border.all(color: WiamColors.bg2, width: 5)),
              child: const Icon(Icons.lock_outline, color: Color(0xFF3D2A0E), size: 22),
            ),
          ),
      ]),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final TaskItem task;
  final VoidCallback? onTapDigital;
  const _TaskRow({required this.task, required this.onTapDigital});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTapDigital,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          TweenAnimationBuilder<double>(
            key: ValueKey(task.isDone),
            tween: Tween(begin: task.isDone ? 0.4 : 1.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isDone ? WiamColors.amber : Colors.transparent,
                border: task.isDone ? null : Border.all(color: WiamColors.inkMuted, width: 2),
              ),
              child: task.isDone ? const Icon(Icons.check, size: 14, color: Color(0xFF3D2A0E)) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(task.title, style: bodyFont(fontSize: 14.5, color: WiamColors.ink))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: task.isDigital ? WiamColors.teal.withValues(alpha: 0.18) : WiamColors.inkMuted.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              task.isDone ? (task.isDigital ? 'تحقق تلقائي' : 'تم') : (task.isDigital ? 'اضغط لإنهاء الدرس' : 'بانتظار ولي الأمر'),
              style: bodyFont(fontSize: 10.5, color: task.isDigital ? WiamColors.teal : WiamColors.inkMuted),
            ),
          ),
        ]),
      ),
    );
  }
}
