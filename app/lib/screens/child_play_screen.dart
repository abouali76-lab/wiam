import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/child_device_state.dart';
import '../theme.dart';
import '../widgets/memory_match_game.dart';
import 'child_timeup_screen.dart';

class ChildPlayScreen extends StatefulWidget {
  const ChildPlayScreen({super.key});

  @override
  State<ChildPlayScreen> createState() => _ChildPlayScreenState();
}

class _ChildPlayScreenState extends State<ChildPlayScreen> {
  bool _navigatedAway = false;

  @override
  void initState() {
    super.initState();
    context.read<ChildDeviceState>().startPolling();
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

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [WiamColors.bg1, WiamColors.bg2])),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Row(children: [
                  const SizedBox(width: 44),
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
                  const SizedBox(width: 44),
                ]),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    width: double.infinity,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), border: Border.all(color: WiamColors.planetDim, width: 2), color: WiamColors.bg1.withValues(alpha: 0.5)),
                    clipBehavior: Clip.antiAlias,
                    child: const MemoryMatchGame(),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
