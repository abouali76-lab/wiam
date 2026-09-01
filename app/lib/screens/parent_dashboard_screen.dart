import 'dart:async';
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

  Future<void> _addTask(ParentChildSummary child) async {
    final parentState = context.read<ParentAppState>();
    final titleCtrl = TextEditingController();
    final minutesCtrl = TextEditingController(text: '15');
    String type = 'digital';
    bool proofAllowed = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('مهمة جديدة', style: bodyFont(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('اقتراحات جاهزة', style: bodyFont(fontSize: 12.5, color: WiamColors.inkMutedLight)),
              const SizedBox(height: 6),
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
              const SizedBox(height: 14),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'عنوان المهمة')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'النوع'),
                items: const [
                  DropdownMenuItem(value: 'digital', child: Text('رقمي (تحقق تلقائي)')),
                  DropdownMenuItem(value: 'external', child: Text('خارجي (تأكيدك مطلوب)')),
                ],
                onChanged: (v) => setDialogState(() => type = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minutesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'مكافأة الدقائق'),
              ),
              if (type == 'external')
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('السماح بإرفاق صورة كإثبات', style: bodyFont(fontSize: 13)),
                  value: proofAllowed,
                  onChanged: (v) => setDialogState(() => proofAllowed = v ?? false),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                final minutes = int.tryParse(minutesCtrl.text.trim()) ?? 0;
                if (titleCtrl.text.trim().isEmpty || minutes <= 0) return;
                await parentState.api.post('/api/parent/children/${child.childId}/tasks', asParent: true, body: {
                  'title': titleCtrl.text.trim(),
                  'type': type,
                  'rewardMinutes': minutes,
                  'proofAllowed': proofAllowed,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                await parentState.refreshChildren();
              },
              child: const Text('إضافة'),
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
        content: Text('لن تظهر "${task.title}" بعد الآن، لكن سجل إنجازها السابق يبقى محفوظاً.', style: bodyFont(fontSize: 13.5, height: 1.6)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: WiamColors.coralDeep),
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
  }

  Future<void> _showUsernameDialog() async {
    final parentState = context.read<ParentAppState>();
    final ctrl = TextEditingController();
    String? dialogError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('اسم مستخدم لدخول أسرع', style: bodyFont(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('يمكنك استخدامه بدل البريد الإلكتروني عند تسجيل الدخول لاحقاً', style: bodyFont(fontSize: 12.5, color: WiamColors.inkMutedLight)),
              const SizedBox(height: 12),
              TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'اسم المستخدم')),
              if (dialogError != null) ...[
                const SizedBox(height: 8),
                Text(dialogError!, style: bodyFont(fontSize: 12.5, color: WiamColors.coralDeep)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                try {
                  await parentState.setUsername(ctrl.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                } on ApiException catch (e) {
                  setDialogState(() => dialogError = e.error == 'username_taken' ? 'هذا الاسم محجوز، جرّب غيره' : 'اسم قصير جداً (3 أحرف على الأقل)');
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final child = parent.children.first;
    final digitalTasks = child.state.tasks.where((t) => t.isDigital).toList();
    final externalTasks = child.state.tasks.where((t) => !t.isDigital).toList();
    final tasks = tabIndex == 0 ? digitalTasks : externalTasks;
    final earnedMinutes = child.state.earnedMinutesToday;
    final possibleMinutes = child.state.tasks.fold<int>(0, (sum, t) => sum + t.rewardMinutes);

    return Scaffold(
      backgroundColor: WiamColors.bgLight,
      appBar: AppBar(
        backgroundColor: WiamColors.bgLight,
        elevation: 0,
        foregroundColor: WiamColors.inkLight,
        title: Text('مهام اليوم', style: displayFont(fontSize: 20, fontWeight: FontWeight.w700, color: WiamColors.inkLight)),
        actions: [
          IconButton(icon: const Icon(Icons.shield_outlined), tooltip: 'التحكم الفوري', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ParentFreezeScreen(child: child)))),
          IconButton(icon: const Icon(Icons.smartphone), tooltip: 'ربط آيباد', onPressed: _issuingDeviceToken ? null : () => _showPairingCode(child)),
          IconButton(icon: const Icon(Icons.person_outline), tooltip: 'اسم المستخدم', onPressed: _showUsernameDialog),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<ParentAppState>().logout();
              if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const ModeSelectScreen()), (_) => false);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: WiamColors.tealDeepLight,
        onPressed: () => _addTask(child),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () => parent.refreshChildren(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _PairingStatusChip(paired: child.state.paired, onTapConnect: _issuingDeviceToken ? null : () => _showPairingCode(child)),
            const SizedBox(height: 14),
            _SummaryCard(earnedMinutes: earnedMinutes, possibleMinutes: possibleMinutes),
            const SizedBox(height: 20),
            _Tabs(index: tabIndex, onChanged: (i) => setState(() => tabIndex = i)),
            const SizedBox(height: 16),
            for (final task in tasks) ...[
              _TaskCard(
                task: task,
                onConfirm: task.isDigital || task.isDone ? null : () => context.read<ParentAppState>().confirmExternalTask(task.taskId),
                onDelete: () => _confirmDeleteTask(child, task),
              ),
              const SizedBox(height: 12),
            ],
            if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text('لا توجد مهام من هذا النوع بعد', textAlign: TextAlign.center, style: bodyFont(color: WiamColors.inkMutedLight)),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int earnedMinutes;
  final int possibleMinutes;
  const _SummaryCard({required this.earnedMinutes, required this.possibleMinutes});

  @override
  Widget build(BuildContext context) {
    final ratio = possibleMinutes == 0 ? 0.0 : (earnedMinutes / possibleMinutes).clamp(0, 1).toDouble();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(colors: [WiamColors.amberLight, WiamColors.amberDeepLight], begin: Alignment.topRight, end: Alignment.bottomLeft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.star_rounded, color: Color(0xFF3D2A0E), size: 22),
            const SizedBox(width: 8),
            Text('وقت لعب مكتسب اليوم', style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF3D2A0E))),
          ]),
          const SizedBox(height: 10),
          Text('$earnedMinutes دقيقة', style: displayFont(fontSize: 30, fontWeight: FontWeight.w800, color: const Color(0xFF3D2A0E))),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: ratio, minHeight: 8, backgroundColor: Colors.white.withValues(alpha: 0.35), color: const Color(0xFF3D2A0E)),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _Tabs({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: const Color(0xFFEDE8DC), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Expanded(child: _TabButton(label: 'الدروس الرقمية', selected: index == 0, onTap: () => onChanged(0))),
        Expanded(child: _TabButton(label: 'المهام الخارجية', selected: index == 1, onTap: () => onChanged(1))),
      ]),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? WiamColors.cardLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)] : null,
        ),
        alignment: Alignment.center,
        child: Text(label, style: bodyFont(fontSize: 13.5, fontWeight: FontWeight.w700, color: selected ? WiamColors.tealDeepLight : WiamColors.inkMutedLight)),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: WiamColors.cardLight, borderRadius: BorderRadius.circular(18), border: Border.all(color: WiamColors.lineLight)),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: WiamColors.tealTintLight, borderRadius: BorderRadius.circular(14)),
          child: Icon(task.isDigital ? Icons.chat_bubble_outline : Icons.checklist_rtl, color: WiamColors.tealDeepLight, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title, style: bodyFont(fontSize: 15.5, fontWeight: FontWeight.w700, color: WiamColors.inkLight)),
              const SizedBox(height: 2),
              Text(
                task.isDigital ? 'تحقق تلقائي من التطبيق' : (task.proofAllowed ? 'يمكن إرفاق صورة كإثبات (اختياري)' : 'يتطلب تأكيدك'),
                style: bodyFont(fontSize: 12.5, color: WiamColors.inkMutedLight),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (onConfirm != null)
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: WiamColors.tealDeepLight, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            onPressed: onConfirm,
            icon: const Icon(Icons.check, size: 14, color: Colors.white),
            label: Text('تأكيد الإنجاز', style: bodyFont(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
          )
        else
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: task.isDone ? WiamColors.tealTintLight : const Color(0xFFEDE8DC),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(task.isDone ? 'مكتمل' : 'قيد الانتظار',
                  style: bodyFont(fontSize: 11.5, fontWeight: FontWeight.w700, color: task.isDone ? WiamColors.tealDeepLight : WiamColors.inkMutedLight)),
            ),
            const SizedBox(height: 6),
            Text('+${task.rewardMinutes} د', style: displayFont(fontSize: 13, fontWeight: FontWeight.w700, color: WiamColors.amberDeepLight)),
          ]),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20, color: WiamColors.inkMutedLight),
          tooltip: 'حذف المهمة',
          onPressed: onDelete,
        ),
      ]),
    );
  }
}

/// Surfaces whether the child's device currently holds a live pairing —
/// otherwise a parent has no way to tell "not connected yet" apart from
/// "connected but nothing happened today" just by looking at the task list.
class _PairingStatusChip extends StatelessWidget {
  final bool paired;
  final VoidCallback? onTapConnect;
  const _PairingStatusChip({required this.paired, required this.onTapConnect});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: paired ? WiamColors.tealTintLight : const Color(0xFFF3E7E1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: paired ? null : onTapConnect,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Icon(paired ? Icons.check_circle_rounded : Icons.smartphone, size: 18, color: paired ? WiamColors.tealDeepLight : WiamColors.coralDeep),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                paired ? 'جهاز الطفل مرتبط بهذا الحساب' : 'لم يتم ربط جهاز الطفل بعد — اضغط هنا للربط',
                style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700, color: paired ? WiamColors.tealDeepLight : WiamColors.coralDeep),
              ),
            ),
          ]),
        ),
      ),
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
      title: Text('ربط آيباد ${widget.childName}', style: bodyFont(fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('أدخلي هذا الرمز في تطبيق الطفل', style: bodyFont(fontSize: 13, color: WiamColors.inkMutedLight)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: expired ? const Color(0xFFF3E7E1) : WiamColors.tealTintLight,
              borderRadius: BorderRadius.circular(14),
            ),
            // Force LTR here: inside the app's RTL context, a space-joined
            // digit string gets bidi-reordered by the renderer, so the code
            // shown could silently differ from the one actually stored.
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                pairing.code.split('').join(' '),
                style: displayFont(fontSize: 34, fontWeight: FontWeight.w800, color: expired ? WiamColors.coralDeep : WiamColors.tealDeepLight),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            expired ? 'انتهت صلاحية الرمز' : 'صالح لمدة $minutes:$seconds',
            style: bodyFont(fontSize: 12.5, color: expired ? WiamColors.coralDeep : WiamColors.inkMutedLight),
          ),
          if (expired) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: regenerating ? null : _regenerate,
              child: regenerating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('توليد رمز جديد'),
            ),
          ],
        ],
      ),
      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('تم'))],
    );
  }
}
