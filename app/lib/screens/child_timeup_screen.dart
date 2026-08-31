import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/child_device_state.dart';
import '../theme.dart';
import 'child_lock_screen.dart';

class ChildTimeUpScreen extends StatelessWidget {
  const ChildTimeUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [WiamColors.bg1, WiamColors.bg2])),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.nightlight_round, color: WiamColors.inkMuted, size: 30),
              const SizedBox(height: 24),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(shape: BoxShape.circle, color: WiamColors.card, border: Border.all(color: WiamColors.cardLine, width: 2)),
                child: const Icon(Icons.emoji_emotions_outlined, color: WiamColors.inkMuted, size: 60),
              ),
              const SizedBox(height: 28),
              Text('لقد نفدت طاقة الكوكب اليوم!', textAlign: TextAlign.center, style: displayFont(fontSize: 26, fontWeight: FontWeight.w700, color: WiamColors.ink)),
              const SizedBox(height: 10),
              Text('نراك غداً بعد إنجاز مهامك الجديدة', textAlign: TextAlign.center, style: bodyFont(fontSize: 16, color: WiamColors.inkMuted)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(color: WiamColors.card, border: Border.all(color: WiamColors.cardLine), borderRadius: BorderRadius.circular(999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: WiamColors.teal),
                  const SizedBox(width: 8),
                  Text('تم حفظ تقدمك بأمان', style: bodyFont(fontSize: 13, color: WiamColors.inkMuted)),
                ]),
              ),
              const SizedBox(height: 32),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: WiamColors.teal, padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16)),
                onPressed: () async {
                  await context.read<ChildDeviceState>().refresh();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const ChildLockScreen()), (_) => false);
                  }
                },
                child: Text('حسناً، إلى الغد!', style: displayFont(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF12162A))),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
