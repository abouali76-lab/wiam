import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/parent_state.dart';
import '../theme.dart';

class ParentFreezeScreen extends StatefulWidget {
  final ParentChildSummary child;
  const ParentFreezeScreen({super.key, required this.child});

  @override
  State<ParentFreezeScreen> createState() => _ParentFreezeScreenState();
}

class _ParentFreezeScreenState extends State<ParentFreezeScreen> {
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _poller = Timer.periodic(const Duration(seconds: 3), (_) => context.read<ParentAppState>().refreshChildren());
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  String _fmt(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final parent = context.watch<ParentAppState>();
    final child = parent.children.firstWhere((c) => c.childId == widget.child.childId, orElse: () => widget.child);
    final session = child.state.activeSession;
    final hasSession = session != null && !session.ended;
    final frozen = child.state.frozen;

    return Scaffold(
      backgroundColor: WiamColors.bgLight,
      appBar: AppBar(
        backgroundColor: WiamColors.bgLight,
        elevation: 0,
        foregroundColor: WiamColors.inkLight,
        title: Text('التحكم الفوري', style: displayFont(fontSize: 20, fontWeight: FontWeight.w700, color: WiamColors.inkLight)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(color: WiamColors.cardLight, borderRadius: BorderRadius.circular(24), border: Border.all(color: WiamColors.lineLight)),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: frozen ? const Color(0xFFF3E7E1) : WiamColors.tealTintLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    frozen ? 'مجمّد من قبل ولي الأمر' : (hasSession ? 'كوكب الألعاب مفتوح الآن' : 'كوكب الألعاب مغلق حالياً'),
                    style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700, color: frozen ? WiamColors.coralDeep : WiamColors.tealDeepLight),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(alignment: Alignment.center, children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CircularProgressIndicator(
                        value: hasSession && session.durationSec > 0 ? session.remainingSec / session.durationSec : 0,
                        strokeWidth: 10,
                        backgroundColor: const Color(0xFFEDE8DC),
                        color: WiamColors.amberLight,
                      ),
                    ),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(hasSession ? _fmt(session.remainingSec) : '--:--', style: displayFont(fontSize: 30, fontWeight: FontWeight.w800, color: WiamColors.inkLight)),
                      Text('متبقٍ', style: bodyFont(fontSize: 11, color: WiamColors.inkMutedLight)),
                    ]),
                  ]),
                ),
              ]),
            ),
            const Spacer(),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => frozen
                    ? context.read<ParentAppState>().unfreeze(child.childId)
                    : context.read<ParentAppState>().freeze(child.childId),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: frozen
                        ? const LinearGradient(colors: [WiamColors.teal, WiamColors.tealDeepLight], begin: Alignment.topRight, end: Alignment.bottomLeft)
                        : const LinearGradient(colors: [WiamColors.coral, WiamColors.coralDeep], begin: Alignment.topRight, end: Alignment.bottomLeft),
                  ),
                  child: Column(children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
                      child: Icon(frozen ? Icons.lock_open_rounded : Icons.ac_unit_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(height: 10),
                    Text(frozen ? 'إلغاء التجميد' : 'تجميد فوري', style: displayFont(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              frozen
                  ? 'اللعب متوقف حالياً على آيباد ${child.name} — اضغطي "إلغاء التجميد" لإعادة فتحه'
                  : 'سيتم قفل اللعبة على آيباد ${child.name} فوراً ومنعه من بدء لعب جديد، حتى لو لم ينتهِ الوقت المخصص له',
              textAlign: TextAlign.center,
              style: bodyFont(fontSize: 13, color: WiamColors.inkMutedLight, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
