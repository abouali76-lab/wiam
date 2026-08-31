import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/parent_state.dart';
import '../theme.dart';
import 'parent_dashboard_screen.dart';

class ParentAuthScreen extends StatefulWidget {
  const ParentAuthScreen({super.key});

  @override
  State<ParentAuthScreen> createState() => _ParentAuthScreenState();
}

class _ParentAuthScreenState extends State<ParentAuthScreen> {
  bool isRegister = false;
  final emailCtrl = TextEditingController();
  final pinCtrl = TextEditingController();
  final childNameCtrl = TextEditingController();

  Future<void> _submit() async {
    final state = context.read<ParentAppState>();
    final ok = isRegister
        ? await state.register(emailCtrl.text.trim(), pinCtrl.text.trim(), childNameCtrl.text.trim())
        : await state.login(emailCtrl.text.trim(), pinCtrl.text.trim());
    if (ok && mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ParentDashboardScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ParentAppState>();
    return Scaffold(
      backgroundColor: WiamColors.bgLight,
      appBar: AppBar(backgroundColor: WiamColors.bgLight, elevation: 0, foregroundColor: WiamColors.inkLight),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isRegister ? 'إنشاء حساب ولي الأمر' : 'تسجيل الدخول',
                  style: displayFont(fontSize: 26, fontWeight: FontWeight.w700, color: WiamColors.inkLight)),
              const SizedBox(height: 24),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'البريد الإلكتروني'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              TextField(controller: pinCtrl, decoration: const InputDecoration(labelText: 'رمز الدخول (PIN)'), obscureText: true),
              if (isRegister) ...[
                const SizedBox(height: 12),
                TextField(controller: childNameCtrl, decoration: const InputDecoration(labelText: 'اسم الطفل')),
              ],
              if (state.error != null) ...[
                const SizedBox(height: 12),
                Text(state.error!, style: bodyFont(color: WiamColors.coralDeep, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: WiamColors.tealDeepLight, padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: state.loading ? null : _submit,
                child: state.loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isRegister ? 'إنشاء الحساب' : 'دخول', style: bodyFont(fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => isRegister = !isRegister),
                child: Text(isRegister ? 'لديك حساب؟ سجّل الدخول' : 'حساب جديد؟ أنشئه الآن', style: bodyFont(color: WiamColors.inkMutedLight)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
