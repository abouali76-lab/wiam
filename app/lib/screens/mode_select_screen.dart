import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/parent_state.dart';
import '../state/child_device_state.dart';
import '../theme.dart';
import 'parent_auth_screen.dart';
import 'parent_dashboard_screen.dart';
import 'child_pair_screen.dart';
import 'child_lock_screen.dart';

/// App root: routes straight into whichever mode this device already
/// belongs to, or lets a fresh install choose one the first time.
class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final parent = context.watch<ParentAppState>();
    final child = context.watch<ChildDeviceState>();

    if (parent.restoring || child.restoring) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (child.paired) return const ChildLockScreen();
    if (parent.loggedIn) return const ParentDashboardScreen();

    return Scaffold(
      backgroundColor: WiamColors.bgLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('وئام', style: displayFont(fontSize: 40, fontWeight: FontWeight.w800, color: WiamColors.inkLight), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('اختر طريقة استخدام هذا الجهاز', style: bodyFont(fontSize: 16, color: WiamColors.inkMutedLight), textAlign: TextAlign.center),
              const SizedBox(height: 48),
              _ModeCard(
                title: 'جهاز الطفل',
                subtitle: 'لإعداد آيباد الطفل وربطه بحساب ولي الأمر',
                color: WiamColors.tealDeepLight,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChildPairScreen())),
              ),
              const SizedBox(height: 16),
              _ModeCard(
                title: 'وضع ولي الأمر',
                subtitle: 'لإدارة المهام ومتابعة وقت اللعب',
                color: WiamColors.amberDeepLight,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ParentAuthScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WiamColors.cardLight,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: WiamColors.lineLight)),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.arrow_back_ios_new, color: color, size: 18),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: bodyFont(fontSize: 17, fontWeight: FontWeight.w700, color: WiamColors.inkLight)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: bodyFont(fontSize: 13, color: WiamColors.inkMutedLight)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
