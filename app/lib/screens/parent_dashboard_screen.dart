import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../models.dart';
import '../state/parent_state.dart';
import '../theme.dart';
import 'mode_select_screen.dart';
import 'parent_freeze_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

// A starting point so a parent isn't stuck typing every task from a blank
// field — tapping one just fills the form below, nothing is created until
// "إضافة" is pressed, so they can still adjust the reward or title first.
class _TaskPreset {
  final String title;
  final int rewardMinutes;
  final bool proofAllowed;
  const _TaskPreset(this.title, this.rewardMinutes, {this.proofAllowed = false});
}

const _digitalPresets = [
  _TaskPreset('درس القراءة اليومي', 15),
  _TaskPreset('درس الرياضيات', 15),
  _TaskPreset('نشاط المهارات الاجتماعية', 10),
  _TaskPreset('تمرين التركيز', 10),
];

const _externalPresets = [
  _TaskPreset('ترتيب الغرفة', 15, proofAllowed: true),
  _TaskPreset('غسل الأسنان', 5),
  _TaskPreset('قراءة كتاب ورقي', 15, proofAllowed: true),
  _TaskPreset('إنجاز الواجب المدرسي', 20, proofAllowed: true),
  _TaskPreset('المساعدة في ترتيب المنزل', 10, proofAllowed: true),
];

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  int tabIndex = 0; // 0 = digital, 1 = external
  bool _issuingDeviceToken = false;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    // Keeps the countdown, the pairing badge and the freeze state honest
    // without the parent having to pull to refresh.
    _poller = Timer.periodic(
      const Duration(seconds: 10),
      (_) => context.read<ParentAppState>().refreshChildren(),
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _addTask(ParentChildSummary child) async {
    final parentState = context.read<ParentAppState>();
    final titleCtrl = TextEditingController();
    final minutesCtrl = TextEditingController(text: '15');
    String type = tabIndex == 0 ? 'digital' : 'external';
    bool proofAllowed = false;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('مهمة جديدة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TypeToggle(
                  type: type,
                  onChanged: (v) => setDialogState(() {
                    type = v;
                    if (v == 'digital') proofAllowed = false;
                  }),
                ),
                const SizedBox(height: 16),
                Text('اقتراحات جاهزة', style: WiamText.section),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final preset in type == 'digital' ? _digitalPresets : _externalPresets)
                      ActionChip(
                        label: Text(preset.title, style: bodyFont(fontSize: 12)),
                        onPressed: () => setDialogState(() {
                          titleCtrl.text = preset.title;
                          minutesCtrl.text = preset.rewardMinutes.toString();
                          proofAllowed = preset.proofAllowed;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'عنوان المهمة'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minutesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'دقائق اللعب المكتسبة',
                    prefixIcon: Icon(Icons.timer_outlined, size: 20),
                  ),
                ),
                if (type == 'external')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: WiamColors.tealDeepLight,
                      title: Text('السماح بإرفاق صورة كإثبات', style: bodyFont(fontSize: 13)),
                      value: proofAllowed,
                      onChanged: (v) => setDialogState(() => proofAllowed = v ?? false),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
              onPressed: saving
                  ? null
                  : () async {
                      final minutes = int.tryParse(minutesCtrl.text.trim()) ?? 0;
                      if (titleCtrl.text.trim().isEmpty || minutes <= 0) return;
                      setDialogState(() => saving = true);
                      try {
                        await parentState.api.post(
                          '/api/parent/children/${child.childId}/tasks',
                          asParent: true,
                          body: {
                            'title': titleCtrl.text.trim(),
                            'type': type,
                            'rewardMinutes': minutes,
                            'proofAllowed': proofAllowed,
                          },
                        );
                      } catch (_) {
                        setDialogState(() => saving = false);
                        return;
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      await parentState.refreshChildren();
                    },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTask(ParentChildSummary child, TaskItem task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف هذه المهمة؟'),
        content: Text('لن تظهر "${task.title}" بعد الآن، لكن سجل إنجازها السابق يبقى محفوظاً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: WiamColors.coralDeep, minimumSize: const Size(96, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<ParentAppState>().deleteTask(child.childId, task.taskId);
    }
  }

  Future<void> _showPairingCode(ParentChildSummary child) async {
    // Requesting a code regenerates it server-side, invalidating any code
    // already on screen — guard against a double-tap silently orphaning
    // whatever this dialog is about to show.
    if (_issuingDeviceToken) return;
    setState(() => _issuingDeviceToken = true);
    final PairingCode pairing;
    try {
      pairing = await context.read<ParentAppState>().startPairing(child.childId);
    } catch (_) {
      if (mounted) {
        setState(() => _issuingDeviceToken = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر إصدار الرمز، تحقق من الاتصال')),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _issuingDeviceToken = false);
    }
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => _PairingCodeDialog(
        childName: child.name,
        initial: pairing,
        onRegenerate: () => context.read<ParentAppState>().startPairing(child.childId),
      ),
    );
    if (mounted) await context.read<ParentAppState>().refreshChildren();
  }

  Future<void> _showUsernameDialog() async {
    final parentState = context.read<ParentAppState>();
    final ctrl = TextEditingController();
    String? dialogError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('اسم مستخدم لدخول أسرع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('يمكنك استخدامه بدل البريد الإلكتروني عند تسجيل الدخول لاحقاً',
                  style: bodyFont(fontSize: 13, color: WiamColors.inkMutedLight, height: 1.6)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم',
                  prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                ),
              ),
              if (dialogError != null) ...[
                const SizedBox(height: 10),
                Text(dialogError!, style: bodyFont(fontSize: 12.5, color: WiamColors.coralDeep)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
              onPressed: () async {
                try {
                  await parentState.setUsername(ctrl.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                } on ApiException catch (e) {
                  setDialogState(() => dialogError =
                      e.error == 'username_taken' ? 'هذا الاسم محجوز، جرّب غيره' : 'اسم قصير جداً (3 أحرف على الأقل)');
                } catch (_) {
                  setDialogState(() => dialogError = 'تعذر الاتصال بالخادم');
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parent = context.watch<ParentAppState>();

    if (parent.children.isEmpty) {
      return Scaffold(
        backgroundColor: WiamColors.bgLight,
        body: Center(
          child: parent.offline
              ? _OfflineRetry(onRetry: () => parent.refreshChildren())
              : const CircularProgressIndicator(color: WiamColors.tealDeepLight),
        ),
      );
    }

    final child = parent.children.first;
    final state = child.state;
    final digitalTasks = state.tasks.where((t) => t.isDigital).toList();
    final externalTasks = state.tasks.where((t) => !t.isDigital).toList();
    final tasks = tabIndex == 0 ? digitalTasks : externalTasks;
    final pendingExternal = externalTasks.where((t) => !t.isDone).length;
    final doneCount = state.tasks.where((t) => t.isDone).length;
    final possibleMinutes = state.tasks.fold<int>(0, (sum, t) => sum + t.rewardMinutes);

    return Scaffold(
      backgroundColor: WiamColors.bgLight,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: WiamColors.tealDeepLight,
        foregroundColor: Colors.white,
        onPressed: () => _addTask(child),
        icon: const Icon(Icons.add_rounded),
        label: Text('مهمة جديدة', style: bodyFont(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: WiamColors.tealDeepLight,
          onRefresh: () => parent.refreshChildren(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 96),
            children: [
              _TopBar(
                childName: child.name,
                onFreeze: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => ParentFreezeScreen(child: child))),
                onPair: _issuingDeviceToken ? null : () => _showPairingCode(child),
                onUsername: _showUsernameDialog,
                onLogout: () async {
                  await context.read<ParentAppState>().logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const ModeSelectScreen()),
                      (_) => false,
                    );
                  }
                },
              ),
              if (parent.offline) ...[
                const SizedBox(height: 12),
                const _OfflineBanner(),
              ],
              const SizedBox(height: 16),
              _HeroCard(
                earnedMinutes: state.earnedMinutesToday,
                possibleMinutes: possibleMinutes,
                availableSeconds: state.availableSeconds,
                doneCount: doneCount,
                totalCount: state.tasks.length,
                frozen: state.frozen,
              ),
              const SizedBox(height: 12),
              _StatusRow(
                paired: state.paired,
                frozen: state.frozen,
                onPair: _issuingDeviceToken ? null : () => _showPairingCode(child),
                onFreeze: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => ParentFreezeScreen(child: child))),
              ),
              const SizedBox(height: 22),
              _Tabs(
                index: tabIndex,
                digitalCount: digitalTasks.length,
                externalCount: externalTasks.length,
                externalBadge: pendingExternal,
                onChanged: (i) => setState(() => tabIndex = i),
              ),
              const SizedBox(height: 14),
              if (tasks.isEmpty)
                _EmptyTasks(isDigital: tabIndex == 0, onAdd: () => _addTask(child))
              else
                for (final task in tasks) ...[
                  _TaskCard(
                    task: task,
                    onConfirm: task.isDigital || task.isDone
                        ? null
                        : () => context.read<ParentAppState>().confirmExternalTask(task.taskId),
                    onDelete: () => _confirmDeleteTask(child, task),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String childName;
  final VoidCallback onFreeze;
  final VoidCallback? onPair;
  final VoidCallback onUsername;
  final VoidCallback onLogout;
  const _TopBar({
    required this.childName,
    required this.onFreeze,
    required this.onPair,
    required this.onUsername,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: WiamColors.tealTintLight, shape: BoxShape.circle),
        child: Text(
          childName.characters.isEmpty ? '؟' : childName.characters.first,
          style: displayFont(fontSize: 22, fontWeight: FontWeight.w700, color: WiamColors.tealDeepLight),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('مهام اليوم', style: displayFont(fontSize: 21, fontWeight: FontWeight.w700, color: WiamColors.inkLight)),
          Text(childName, style: bodyFont(fontSize: 13, color: WiamColors.inkMutedLight)),
        ]),
      ),
      IconButton(
        tooltip: 'التحكم الفوري',
        icon: const Icon(Icons.shield_outlined),
        color: WiamColors.inkMutedLight,
        onPressed: onFreeze,
      ),
      PopupMenuButton<String>(
        tooltip: 'الحساب',
        icon: const Icon(Icons.more_vert_rounded, color: WiamColors.inkMutedLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WiamRadius.control)),
        onSelected: (v) {
          switch (v) {
            case 'pair':
              onPair?.call();
            case 'username':
              onUsername();
            case 'logout':
              onLogout();
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'pair',
            enabled: onPair != null,
            child: const _MenuRow(icon: Icons.tablet_android_rounded, label: 'ربط جهاز الطفل'),
          ),
          const PopupMenuItem(
            value: 'username',
            child: _MenuRow(icon: Icons.alternate_email_rounded, label: 'اسم المستخدم'),
          ),
          const PopupMenuItem(
            value: 'logout',
            child: _MenuRow(icon: Icons.logout_rounded, label: 'تسجيل الخروج', danger: true),
          ),
        ],
      ),
    ]);
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  const _MenuRow({required this.icon, required this.label, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final color = danger ? WiamColors.coralDeep : WiamColors.inkLight;
    return Row(children: [
      Icon(icon, size: 19, color: color),
      const SizedBox(width: 12),
      Text(label, style: bodyFont(fontSize: 14, color: color)),
    ]);
  }
}

/// The one number a parent opens the app for: minutes earned today, with
/// how much of that is still unspent.
class _HeroCard extends StatelessWidget {
  final int earnedMinutes;
  final int possibleMinutes;
  final int availableSeconds;
  final int doneCount;
  final int totalCount;
  final bool frozen;

  const _HeroCard({
    required this.earnedMinutes,
    required this.possibleMinutes,
    required this.availableSeconds,
    required this.doneCount,
    required this.totalCount,
    required this.frozen,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = possibleMinutes == 0 ? 0.0 : (earnedMinutes / possibleMinutes).clamp(0.0, 1.0);
    final remainingMinutes = (availableSeconds / 60).ceil();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(WiamRadius.sheet),
        gradient: const LinearGradient(
          colors: [Color(0xFF3C7F82), Color(0xFF2B5F62)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: WiamShadow.lifted,
      ),
      child: Column(children: [
        Row(children: [
          _ProgressRing(ratio: ratio, label: '$doneCount/$totalCount'),
          const SizedBox(width: 18),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('وقت اللعب المكتسب اليوم',
                  style: bodyFont(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.8))),
              const SizedBox(height: 4),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text('$earnedMinutes',
                    style: displayFont(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
                const SizedBox(width: 6),
                Text('دقيقة', style: bodyFont(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
              const SizedBox(height: 8),
              Text(
                possibleMinutes == 0
                    ? 'لم تُضف مهام بعد'
                    : 'من أصل $possibleMinutes دقيقة ممكنة اليوم',
                style: bodyFont(fontSize: 12, color: Colors.white.withValues(alpha: 0.75)),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.16)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: _HeroStat(
              icon: Icons.hourglass_bottom_rounded,
              value: frozen ? 'مجمّد' : '$remainingMinutes د',
              label: frozen ? 'اللعب موقوف' : 'متبقٍ للعب',
              highlight: frozen,
            ),
          ),
          Container(width: 1, height: 34, color: Colors.white.withValues(alpha: 0.16)),
          Expanded(
            child: _HeroStat(
              icon: Icons.task_alt_rounded,
              value: '$doneCount من $totalCount',
              label: 'مهام أُنجزت',
            ),
          ),
        ]),
      ]),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool highlight;
  const _HeroStat({required this.icon, required this.value, required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final color = highlight ? const Color(0xFFFFC9BC) : Colors.white;
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 15, color: color.withValues(alpha: 0.85)),
        const SizedBox(width: 6),
        Text(value, style: displayFont(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      ]),
      const SizedBox(height: 2),
      Text(label, style: bodyFont(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.7))),
    ]);
  }
}

class _ProgressRing extends StatelessWidget {
  final double ratio;
  final String label;
  const _ProgressRing({required this.ratio, required this.label});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: ratio),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox(
        width: 78,
        height: 78,
        child: CustomPaint(
          painter: _RingPainter(v),
          child: Center(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(label,
                  style: displayFont(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double ratio;
  _RingPainter(this.ratio);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 5;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );
    if (ratio <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -pi / 2,
      2 * pi * ratio,
      false,
      Paint()
        ..color = WiamColors.amberLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.ratio != ratio;
}

/// Pairing and freeze status side by side — both are things a parent needs
/// to be able to check at a glance, not hunt for in a menu.
class _StatusRow extends StatelessWidget {
  final bool paired;
  final bool frozen;
  final VoidCallback? onPair;
  final VoidCallback onFreeze;
  const _StatusRow({required this.paired, required this.frozen, required this.onPair, required this.onFreeze});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: _StatusTile(
          icon: paired ? Icons.link_rounded : Icons.link_off_rounded,
          title: paired ? 'الجهاز مرتبط' : 'لم يُربط بعد',
          subtitle: paired ? 'جاهز للاستخدام' : 'اضغط للربط',
          color: paired ? WiamColors.tealDeepLight : WiamColors.coralDeep,
          tint: paired ? WiamColors.tealTintLight : WiamColors.coralTintLight,
          onTap: paired ? null : onPair,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _StatusTile(
          icon: frozen ? Icons.ac_unit_rounded : Icons.play_circle_outline_rounded,
          title: frozen ? 'اللعب مجمّد' : 'اللعب متاح',
          subtitle: frozen ? 'اضغط لإلغاء التجميد' : 'تحكم فوري',
          color: frozen ? WiamColors.coralDeep : WiamColors.tealDeepLight,
          tint: frozen ? WiamColors.coralTintLight : WiamColors.bgLightAlt,
          onTap: onFreeze,
        ),
      ),
    ]);
  }
}

class _StatusTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color tint;
  final VoidCallback? onTap;
  const _StatusTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return WiamCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      onTap: onTap,
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700, color: WiamColors.inkLight)),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: WiamText.caption),
          ]),
        ),
      ]),
    );
  }
}

class _Tabs extends StatelessWidget {
  final int index;
  final int digitalCount;
  final int externalCount;
  final int externalBadge;
  final ValueChanged<int> onChanged;
  const _Tabs({
    required this.index,
    required this.digitalCount,
    required this.externalCount,
    required this.externalBadge,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: WiamColors.bgLightAlt,
        borderRadius: BorderRadius.circular(WiamRadius.control),
        border: Border.all(color: WiamColors.lineLight),
      ),
      child: Row(children: [
        Expanded(
          child: _TabButton(
            label: 'الدروس الرقمية',
            count: digitalCount,
            selected: index == 0,
            onTap: () => onChanged(0),
          ),
        ),
        Expanded(
          child: _TabButton(
            label: 'المهام الخارجية',
            count: externalCount,
            badge: externalBadge,
            selected: index == 1,
            onTap: () => onChanged(1),
          ),
        ),
      ]),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final int count;
  final int badge;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton({
    required this.label,
    required this.count,
    this.badge = 0,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? WiamColors.cardLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected ? WiamShadow.soft : null,
        ),
        alignment: Alignment.center,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
            '$label ($count)',
            style: bodyFont(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? WiamColors.tealDeepLight : WiamColors.inkMutedLight,
            ),
          ),
          if (badge > 0) ...[
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: WiamColors.coral, shape: BoxShape.circle),
            ),
          ],
        ]),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskItem task;
  final VoidCallback? onConfirm;
  final VoidCallback onDelete;
  const _TaskCard({required this.task, required this.onConfirm, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final done = task.isDone;
    return WiamCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: done ? WiamColors.tealTintLight : WiamColors.bgLightAlt,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            done
                ? Icons.check_rounded
                : (task.isDigital ? Icons.play_lesson_outlined : Icons.checklist_rtl_rounded),
            color: done ? WiamColors.tealDeepLight : WiamColors.inkMutedLight,
            size: 21,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(task.title, style: WiamText.cardTitle),
            const SizedBox(height: 4),
            Row(children: [
              WiamPill(
                label: '+${task.rewardMinutes} دقيقة',
                color: WiamColors.amberDeepLight,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  done
                      ? (task.verifiedBy == 'parent' ? 'أكّدته بنفسك' : 'تحقق تلقائي')
                      : (task.isDigital ? 'ينتظر الطفل' : 'ينتظر تأكيدك'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WiamText.caption,
                ),
              ),
            ]),
          ]),
        ),
        if (onConfirm != null)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: WiamColors.tealDeepLight,
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: bodyFont(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              onPressed: onConfirm,
              child: const Text('تأكيد'),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
          color: WiamColors.inkFaintLight,
          tooltip: 'حذف المهمة',
          onPressed: onDelete,
        ),
      ]),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  final bool isDigital;
  final VoidCallback onAdd;
  const _EmptyTasks({required this.isDigital, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return WiamCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(children: [
        Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(color: WiamColors.bgLightAlt, shape: BoxShape.circle),
          child: Icon(
            isDigital ? Icons.play_lesson_outlined : Icons.checklist_rtl_rounded,
            size: 26,
            color: WiamColors.inkFaintLight,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          isDigital ? 'لا توجد دروس رقمية بعد' : 'لا توجد مهام خارجية بعد',
          style: bodyFont(fontSize: 15, fontWeight: FontWeight.w700, color: WiamColors.inkLight),
        ),
        const SizedBox(height: 6),
        Text(
          isDigital
              ? 'الدروس الرقمية يُنجزها الطفل داخل التطبيق وتُحتسب تلقائياً'
              : 'المهام الخارجية يقوم بها الطفل في الواقع، وتؤكدها أنت بنفسك',
          textAlign: TextAlign.center,
          style: bodyFont(fontSize: 12.5, color: WiamColors.inkMutedLight, height: 1.6),
        ),
        const SizedBox(height: 16),
        FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: WiamColors.tealTintLight,
            foregroundColor: WiamColors.tealDeepLight,
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          onPressed: onAdd,
          child: Text('أضف أول مهمة', style: bodyFont(fontSize: 13.5, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: WiamColors.coralTintLight,
        borderRadius: BorderRadius.circular(WiamRadius.control),
        border: Border.all(color: WiamColors.coral.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        const Icon(Icons.cloud_off_rounded, size: 18, color: WiamColors.coralDeep),
        const SizedBox(width: 10),
        Expanded(
          child: Text('تعذر الاتصال بالخادم — البيانات المعروضة قد تكون قديمة',
              style: bodyFont(fontSize: 12.5, color: WiamColors.coralDeep, height: 1.5)),
        ),
      ]),
    );
  }
}

class _OfflineRetry extends StatelessWidget {
  final VoidCallback onRetry;
  const _OfflineRetry({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, size: 44, color: WiamColors.inkFaintLight),
        const SizedBox(height: 16),
        Text('تعذر الاتصال بالخادم', style: WiamText.title, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('تحقق من اتصال الشبكة ثم أعد المحاولة',
            textAlign: TextAlign.center, style: bodyFont(fontSize: 13.5, color: WiamColors.inkMutedLight)),
        const SizedBox(height: 22),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(180, 48)),
          onPressed: onRetry,
          child: const Text('إعادة المحاولة'),
        ),
      ]),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final String type;
  final ValueChanged<String> onChanged;
  const _TypeToggle({required this.type, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget option(String value, String label, IconData icon) {
      final selected = type == value;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () => onChanged(value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? WiamColors.cardLight : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              boxShadow: selected ? WiamShadow.soft : null,
            ),
            child: Column(children: [
              Icon(icon, size: 18, color: selected ? WiamColors.tealDeepLight : WiamColors.inkMutedLight),
              const SizedBox(height: 4),
              Text(label,
                  style: bodyFont(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? WiamColors.tealDeepLight : WiamColors.inkMutedLight,
                  )),
            ]),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: WiamColors.bgLightAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WiamColors.lineLight),
      ),
      child: Row(children: [
        option('digital', 'درس رقمي', Icons.play_lesson_outlined),
        option('external', 'مهمة خارجية', Icons.checklist_rtl_rounded),
      ]),
    );
  }
}

class _PairingCodeDialog extends StatefulWidget {
  final String childName;
  final PairingCode initial;
  final Future<PairingCode> Function() onRegenerate;

  const _PairingCodeDialog({required this.childName, required this.initial, required this.onRegenerate});

  @override
  State<_PairingCodeDialog> createState() => _PairingCodeDialogState();
}

class _PairingCodeDialogState extends State<_PairingCodeDialog> {
  late PairingCode pairing;
  Timer? _ticker;
  Duration remaining = Duration.zero;
  bool regenerating = false;

  @override
  void initState() {
    super.initState();
    pairing = widget.initial;
    _startTicker();
  }

  void _startTicker() {
    _tick();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final left = pairing.expiresAt.difference(DateTime.now());
    setState(() => remaining = left.isNegative ? Duration.zero : left);
  }

  Future<void> _regenerate() async {
    setState(() => regenerating = true);
    try {
      pairing = await widget.onRegenerate();
      _startTicker();
    } catch (_) {
      // Leave the expired code on screen; the button stays available.
    } finally {
      if (mounted) setState(() => regenerating = false);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expired = remaining == Duration.zero;
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');

    return AlertDialog(
      title: Text('ربط جهاز ${widget.childName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('افتح تطبيق وئام على جهاز الطفل، اختر "جهاز الطفل"، ثم أدخل هذا الرمز',
              textAlign: TextAlign.center,
              style: bodyFont(fontSize: 13, color: WiamColors.inkMutedLight, height: 1.6)),
          const SizedBox(height: 18),
          // Force LTR: inside the app's RTL context, a digit string with
          // separators gets bidi-reordered, so the code shown could silently
          // differ from the one actually stored.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < pairing.code.length; i++) ...[
                  Container(
                    width: 54,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: expired ? WiamColors.coralTintLight : WiamColors.tealTintLight,
                      borderRadius: BorderRadius.circular(WiamRadius.control),
                    ),
                    child: Text(
                      pairing.code[i],
                      style: displayFont(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: expired ? WiamColors.coralDeep : WiamColors.tealDeepLight,
                      ),
                    ),
                  ),
                  if (i != pairing.code.length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(expired ? Icons.timer_off_outlined : Icons.timer_outlined,
                size: 15, color: expired ? WiamColors.coralDeep : WiamColors.inkMutedLight),
            const SizedBox(width: 6),
            expired
                ? Text('انتهت صلاحية الرمز',
                    style: bodyFont(fontSize: 12.5, fontWeight: FontWeight.w700, color: WiamColors.coralDeep))
                : Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text('$minutes:$seconds',
                        style: bodyFont(fontSize: 12.5, color: WiamColors.inkMutedLight)),
                  ),
          ]),
          if (expired) ...[
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(180, 46)),
              onPressed: regenerating ? null : _regenerate,
              child: regenerating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('توليد رمز جديد'),
            ),
          ],
        ],
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: () => Navigator.pop(context),
          child: const Text('تم'),
        ),
      ],
    );
  }
}
