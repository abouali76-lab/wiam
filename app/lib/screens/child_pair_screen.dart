import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../state/child_device_state.dart';
import '../theme.dart';
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
  bool loading = false;
  String? error;

  Future<void> _pair() async {
    if (codeCtrl.text.trim().length != _pairingCodeLength) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await context.read<ChildDeviceState>().pair(codeCtrl.text.trim());
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ChildLockScreen()));
    } on ApiException {
      setState(() => error = 'الرمز غير صحيح أو انتهت صلاحيته، اطلب رمزاً جديداً من ولي الأمر');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WiamColors.bgLight,
      appBar: AppBar(backgroundColor: WiamColors.bgLight, elevation: 0, foregroundColor: WiamColors.inkLight),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('ربط هذا الآيباد', style: displayFont(fontSize: 26, fontWeight: FontWeight.w700, color: WiamColors.inkLight)),
              const SizedBox(height: 8),
              Text('اطلب من ولي الأمر فتح "ربط آيباد" من تطبيقه، وأدخل الرمز المكوّن من $_pairingCodeLength أرقام الظاهر لديه',
                  style: bodyFont(fontSize: 14, color: WiamColors.inkMutedLight, height: 1.6)),
              const SizedBox(height: 28),
              TextField(
                controller: codeCtrl,
                autofocus: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(_pairingCodeLength)],
                style: displayFont(fontSize: 36, fontWeight: FontWeight.w800, color: WiamColors.inkLight),
                decoration: const InputDecoration(counterText: ''),
                onChanged: (v) {
                  setState(() => error = null);
                  if (v.length == _pairingCodeLength) _pair();
                },
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Text(error!, textAlign: TextAlign.center, style: bodyFont(color: WiamColors.coralDeep, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: WiamColors.tealDeepLight, padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: loading ? null : _pair,
                child: loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('ربط', style: bodyFont(fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
