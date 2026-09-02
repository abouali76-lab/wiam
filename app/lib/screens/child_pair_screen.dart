import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../state/child_device_state.dart';
import '../theme.dart';
import '../widgets/brand_mark.dart';
import 'child_lock_screen.dart';

// Keep in sync with the backend's generatePairingCode() (backend/src/auth.js).
const _pairingCodeLength = 3;

class ChildPairScreen extends StatefulWidget {
  const ChildPairScreen({super.key});

  @override
  State<ChildPairScreen> createState() => _ChildPairScreenState();
}

class _ChildPairScreenState extends State<ChildPairScreen> {
  final codeCtrl = TextEditingController();
  final focus = FocusNode();
  bool loading = false;
  String? error;

  @override
  void dispose() {
    codeCtrl.dispose();
    focus.dispose();
    super.dispose();
  }

  Future<void> _pair() async {
    if (codeCtrl.text.trim().length != _pairingCodeLength) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await context.read<ChildDeviceState>().pair(codeCtrl.text.trim());
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ChildLockScreen()));
      }
    } on ApiException catch (e) {
      setState(() {
        error = e.error == 'too_many_requests'
            ? 'محاولات كثيرة، انتظر دقيقة ثم أعد المحاولة'
            : 'الرمز غير صحيح أو انتهت صلاحيته، اطلب رمزاً جديداً من ولي الأمر';
        codeCtrl.clear();
      });
      focus.requestFocus();
    } catch (_) {
      setState(() => error = 'تعذر الاتصال بالخادم، تحقق من الشبكة');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = codeCtrl.text;
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
              Text('ربط جهاز الطفل', textAlign: TextAlign.center, style: WiamText.title),
              const SizedBox(height: 6),
              Text(
                'اطلب من ولي الأمر فتح "ربط الجهاز" من تطبيقه،\nثم أدخل الرمز الظاهر لديه',
                textAlign: TextAlign.center,
                style: bodyFont(fontSize: 13.5, color: WiamColors.inkMutedLight, height: 1.7),
              ),
              const SizedBox(height: 28),
              WiamCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(children: [
                  // A real (invisible) field drives the boxes below, so the
                  // system keyboard, paste and autofill all behave normally.
                  Stack(alignment: Alignment.center, children: [
                    Opacity(
                      opacity: 0,
                      child: SizedBox(
                        height: 1,
                        child: TextField(
                          controller: codeCtrl,
                          focusNode: focus,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(_pairingCodeLength),
                          ],
                          onChanged: (v) {
                            setState(() => error = null);
                            if (v.length == _pairingCodeLength) _pair();
                          },
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => focus.requestFocus(),
                      behavior: HitTestBehavior.opaque,
                      // The code is a number: force LTR so the boxes fill
                      // left-to-right the way the parent reads it out.
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < _pairingCodeLength; i++) ...[
                              _CodeBox(
                                digit: i < code.length ? code[i] : null,
                                active: i == code.length,
                                hasError: error != null,
                              ),
                              if (i != _pairingCodeLength - 1) const SizedBox(width: 12),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ]),
                  if (error != null) ...[
                    const SizedBox(height: 18),
                    Text(error!,
                        textAlign: TextAlign.center,
                        style: bodyFont(fontSize: 13, color: WiamColors.coralDeep, height: 1.6)),
                  ],
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: loading || code.length != _pairingCodeLength ? null : _pair,
                    child: loading
                        ? const SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('ربط الجهاز'),
                  ),
                ]),
              ),
              const SizedBox(height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.lock_outline_rounded, size: 15, color: WiamColors.inkFaintLight),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'الرمز يُستخدم مرة واحدة فقط، ولا يمنح الجهاز أي وصول لحساب ولي الأمر',
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

class _CodeBox extends StatelessWidget {
  final String? digit;
  final bool active;
  final bool hasError;
  const _CodeBox({required this.digit, required this.active, required this.hasError});

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? WiamColors.coralDeep
        : (active ? WiamColors.tealDeepLight : WiamColors.lineLight);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 62,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: digit != null ? WiamColors.tealTintLight : WiamColors.bgLightAlt,
        borderRadius: BorderRadius.circular(WiamRadius.control),
        border: Border.all(color: borderColor, width: active || hasError ? 2 : 1.2),
      ),
      child: Text(
        digit ?? '',
        style: displayFont(fontSize: 34, fontWeight: FontWeight.w800, color: WiamColors.inkLight),
      ),
    );
  }
}
