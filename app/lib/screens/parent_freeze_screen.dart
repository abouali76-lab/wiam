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
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _poller = Timer.periodic(
      const Duration(seconds: 3),
      (_) => context.read<ParentAppState>().refreshChildren(),
    );
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

  Future<void> _toggle(String childId, bool frozen) async {
    setState(() => _working = true);
    final parent = context.read<ParentAppState>();
    try {
      frozen ? await parent.unfreeze(childId) : await parent.freeze(childId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تنفيذ الأمر، تحقق من الاتصال')),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final parent = context.watch<ParentAppState>();
    final child = parent.children.firstWhere(
      (c) => c.childId == widget.child.childId,
      orElse: () => widget.child,
    );
    final session = child.state.activeSession;
    final hasSession = session != null && !session.ended;
    final frozen = child.state.frozen;

    return Scaffold(
      backgroundColor: WiamColors.bgLight,
      appBar: AppBar(title: const Text('التحكم الفوري')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              WiamCard(
                padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
                lifted: true,
                child: Column(children: [
                  WiamPill(
                    label: frozen
                        ? 'اللعب مجمّد الآن'
                        : (hasSession ? 'جلسة لعب جارية' : 'لا توجد جلسة لعب'),
                    icon: frozen
                        ? Icons.ac_unit_rounded
                        : (hasSession ? Icons.play_arrow_rounded : Icons.pause_rounded),
                    color: frozen
                        ? WiamColors.coralDeep
                        : (hasSession ? WiamColors.tealDeepLight : WiamColors.inkMutedLight),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: 168,
                    height: 168,
                    child: Stack(alignment: Alignment.center, children: [
                      SizedBox(
                        width: 168,
                        height: 168,
                        child: CircularProgressIndicator(
                          value: hasSession && session.durationSec > 0
                              ? session.remainingSec / session.durationSec
                              : 0,
                          strokeWidth: 12,
                          strokeCap: StrokeCap.round,
                          backgroundColor: WiamColors.bgLightAlt,
                          color: frozen ? WiamColors.coral : WiamColors.amberLight,
                        ),
                      ),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            hasSession ? _fmt(session.remainingSec) : '--:--',
                            style: displayFont(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: WiamColors.inkLight,
                            ),
                          ),
                        ),
                        Text('متبقٍ من الجلسة', style: WiamText.caption),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'رصيد ${child.name} اليوم: ${(child.state.availableSeconds / 60).ceil()} دقيقة غير مستهلكة',
                    textAlign: TextAlign.center,
                    style: bodyFont(fontSize: 13, color: WiamColors.inkMutedLight),
                  ),
                ]),
              ),
              const Spacer(),
              _ActionButton(
                frozen: frozen,
                busy: _working,
                onTap: () => _toggle(child.childId, frozen),
              ),
              const SizedBox(height: 14),
              Text(
                frozen
                    ? 'اللعب متوقف حالياً على جهاز ${child.name} — اضغط لإعادة فتحه'
                    : 'سيتم قفل اللعبة على جهاز ${child.name} فوراً ومنعه من بدء لعب جديد، حتى لو لم ينتهِ وقته',
                textAlign: TextAlign.center,
                style: bodyFont(fontSize: 12.5, color: WiamColors.inkMutedLight, height: 1.7),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: WiamColors.inkFaintLight),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'يسري الأمر على الجهاز خلال ثوانٍ، وحتى لو كان خارج الشبكة سيُطبّق فور عودته',
                    style: WiamText.caption,
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool frozen;
  final bool busy;
  final VoidCallback onTap;
  const _ActionButton({required this.frozen, required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = frozen
        ? [WiamColors.tealLight, WiamColors.tealDeepLight]
        : [WiamColors.coral, WiamColors.coralDeep];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(WiamRadius.sheet),
        onTap: busy ? null : onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(WiamRadius.sheet),
            gradient: LinearGradient(colors: colors, begin: Alignment.topRight, end: Alignment.bottomLeft),
            boxShadow: [
              BoxShadow(color: colors.last.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: busy
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : Icon(frozen ? Icons.lock_open_rounded : Icons.ac_unit_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              frozen ? 'إلغاء التجميد' : 'تجميد فوري',
              style: displayFont(fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ]),
        ),
      ),
    );
  }
}
