import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/parent_state.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets/brand_mark.dart';
import 'parent_dashboard_screen.dart';

class ParentAuthScreen extends StatefulWidget {
  const ParentAuthScreen({super.key});

  @override
  State<ParentAuthScreen> createState() => _ParentAuthScreenState();
}

class _ParentAuthScreenState extends State<ParentAuthScreen> {
  bool isRegister = false;
  bool rememberMe = false;
  bool showPassword = false;
  final identifierCtrl = TextEditingController(); // login: email or username
  final emailCtrl = TextEditingController(); // register: email
  final usernameCtrl = TextEditingController(); // register: optional username
  final passwordCtrl = TextEditingController();
  final childNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prefillRememberedLogin();
  }

  @override
  void dispose() {
    identifierCtrl.dispose();
    emailCtrl.dispose();
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    childNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _prefillRememberedLogin() async {
    final (identifier, password) = await Storage.loadRememberedLogin();
    if (!mounted) return;
    if (identifier != null) {
      setState(() {
        identifierCtrl.text = identifier;
        rememberMe = true;
        if (password != null) passwordCtrl.text = password;
      });
    }
  }

  Future<void> _submit() async {
    final state = context.read<ParentAppState>();
    final ok = isRegister
        ? await state.register(
            emailCtrl.text.trim(),
            usernameCtrl.text.trim(),
            passwordCtrl.text,
            childNameCtrl.text.trim(),
          )
        : await state.login(identifierCtrl.text.trim(), passwordCtrl.text);
    if (!ok) return;

    if (!isRegister) {
      if (rememberMe) {
        await Storage.saveRememberedLogin(identifierCtrl.text.trim(), passwordCtrl.text);
      } else {
        await Storage.clearRememberedLogin();
      }
    }
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ParentDashboardScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ParentAppState>();
    return Scaffold(
      backgroundColor: WiamColors.bgLight,
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: BrandMark(size: 62)),
              const SizedBox(height: 16),
              Text(
                isRegister ? 'أنشئ حساب ولي الأمر' : 'أهلاً بعودتك',
                textAlign: TextAlign.center,
                style: WiamText.title,
              ),
              const SizedBox(height: 6),
              Text(
                isRegister
                    ? 'حساب واحد يدير مهام أطفالك ووقت لعبهم'
                    : 'سجّل الدخول لمتابعة مهام اليوم',
                textAlign: TextAlign.center,
                style: bodyFont(fontSize: 13.5, color: WiamColors.inkMutedLight),
              ),
              const SizedBox(height: 26),
              WiamCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isRegister) ...[
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: usernameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'اسم مستخدم (اختياري)',
                          helperText: 'لدخول أسرع لاحقاً بدل البريد',
                          prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                        ),
                      ),
                    ] else
                      TextField(
                        controller: identifierCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني أو اسم المستخدم',
                          prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                        ),
                      ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: !showPassword,
                      textInputAction: isRegister ? TextInputAction.next : TextInputAction.done,
                      onSubmitted: (_) => isRegister ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        helperText: isRegister ? '6 خانات على الأقل' : null,
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          tooltip: showPassword ? 'إخفاء' : 'إظهار',
                          icon: Icon(
                            showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                            color: WiamColors.inkMutedLight,
                          ),
                          onPressed: () => setState(() => showPassword = !showPassword),
                        ),
                      ),
                    ),
                    if (isRegister) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: childNameCtrl,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'اسم الطفل',
                          prefixIcon: Icon(Icons.child_care_rounded, size: 20),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => rememberMe = !rememberMe),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: rememberMe,
                                visualDensity: VisualDensity.compact,
                                onChanged: (v) => setState(() => rememberMe = v ?? false),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                activeColor: WiamColors.tealDeepLight,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('تذكرني على هذا الجهاز',
                                style: bodyFont(fontSize: 13.5, color: WiamColors.inkLight)),
                          ]),
                        ),
                      ),
                    ],
                    if (state.error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: WiamColors.coralTintLight,
                          borderRadius: BorderRadius.circular(WiamRadius.control),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline_rounded, size: 18, color: WiamColors.coralDeep),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(state.error!,
                                style: bodyFont(fontSize: 13, color: WiamColors.coralDeep, height: 1.5)),
                          ),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: state.loading ? null : _submit,
                      child: state.loading
                          ? const SizedBox(
                              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(isRegister ? 'إنشاء الحساب' : 'دخول'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() {
                  isRegister = !isRegister;
                  context.read<ParentAppState>().error = null;
                }),
                child: Text(isRegister ? 'لديك حساب؟ سجّل الدخول' : 'حساب جديد؟ أنشئه الآن'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
