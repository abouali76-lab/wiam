import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/parent_state.dart';
import '../state/child_device_state.dart';
import '../theme.dart';
import '../widgets/brand_mark.dart';
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
      return const Scaffold(
        backgroundColor: WiamColors.bgLight,
        body: Center(child: CircularProgressIndicator(color: WiamColors.tealDeepLight)),
      );
    }
    if (child.paired) return const ChildLockScreen();
    if (parent.loggedIn) return const ParentDashboardScreen();

    return Scaffold(
      backgroundColor: WiamColors.bgLight,
      body: Stack(
        children: [
          const Positioned.fill(child: _WelcomeBackdrop()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 56),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: BrandMark(size: 82)),
                      const SizedBox(height: 20),
                      Text('وئام', textAlign: TextAlign.center, style: WiamText.hero),
                      const SizedBox(height: 8),
                      Text(
                        'وقت اللعب يُكتسب بالإنجاز، لا بالمساومة',
                        textAlign: TextAlign.center,
                        style: bodyFont(fontSize: 15, color: WiamColors.inkMutedLight, height: 1.6),
                      ),
                      const SizedBox(height: 34),
                      Text('اختر طريقة استخدام هذا الجهاز', style: WiamText.section),
                      const SizedBox(height: 12),
                      _ModeCard(
                        title: 'وضع ولي الأمر',
                        subtitle: 'أنشئ المهام، أكّد الإنجاز، وتحكّم بوقت اللعب لحظياً',
                        icon: Icons.admin_panel_settings_rounded,
                        color: WiamColors.tealDeepLight,
                        tint: WiamColors.tealTintLight,
                        primary: true,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ParentAuthScreen()),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ModeCard(
                        title: 'جهاز الطفل',
                        subtitle: 'اربط جهاز طفلك بحسابك برمز من ثلاثة أرقام',
                        icon: Icons.tablet_android_rounded,
                        color: WiamColors.amberDeepLight,
                        tint: WiamColors.amberTintLight,
                        primary: false,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ChildPairScreen()),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const _TrustRow(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two very soft colour washes behind the page — enough to stop the welcome
/// screen reading as a blank form, not enough to compete with the content.
class _WelcomeBackdrop extends StatelessWidget {
  const _WelcomeBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(children: [
        Positioned(
          top: -140,
          right: -90,
          child: _Blob(size: 300, color: WiamColors.tealLight.withValues(alpha: 0.16)),
        ),
        Positioned(
          bottom: -160,
          left: -110,
          child: _Blob(size: 340, color: WiamColors.amberLight.withValues(alpha: 0.18)),
        ),
      ]),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      );
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color tint;

  /// The parent path is the one almost every first-run user wants, so it
  /// gets the visual weight instead of both cards looking equally likely.
  final bool primary;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.tint,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return WiamCard(
      lifted: primary,
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: bodyFont(fontSize: 16.5, fontWeight: FontWeight.w700, color: WiamColors.inkLight)),
                const SizedBox(height: 3),
                Text(subtitle, style: bodyFont(fontSize: 12.5, color: WiamColors.inkMutedLight, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_left_rounded, color: WiamColors.inkFaintLight, size: 24),
        ],
      ),
    );
  }
}

/// Three plain promises. A parent deciding whether to hand this app a child's
/// screen time wants to know what it does before they sign up.
class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.verified_user_outlined, 'تحقق مزدوج', 'دروس تُحتسب تلقائياً،\nومهام يؤكدها ولي الأمر'),
      (Icons.timer_outlined, 'وقت محسوب', 'العدّاد على الخادم،\nلا يمكن التلاعب به'),
      (Icons.ac_unit_rounded, 'تحكم فوري', 'تجميد اللعب في أي لحظة\nمن جهازك'),
    ];
    return Row(
      children: [
        for (final (icon, title, body) in items)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(children: [
                Icon(icon, size: 20, color: WiamColors.tealDeepLight),
                const SizedBox(height: 6),
                Text(title, style: bodyFont(fontSize: 12.5, fontWeight: FontWeight.w700, color: WiamColors.inkLight)),
                const SizedBox(height: 3),
                Text(body, textAlign: TextAlign.center, style: bodyFont(fontSize: 10.5, color: WiamColors.inkFaintLight, height: 1.45)),
              ]),
            ),
          ),
      ],
    );
  }
}
