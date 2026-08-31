import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../state/child_device_state.dart';
import '../theme.dart';
import 'child_lock_screen.dart';

class ChildPairScreen extends StatefulWidget {
  const ChildPairScreen({super.key});

  @override
  State<ChildPairScreen> createState() => _ChildPairScreenState();
}

class _ChildPairScreenState extends State<ChildPairScreen> {
  final tokenCtrl = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> _pair() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await context.read<ChildDeviceState>().pair(tokenCtrl.text.trim());
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ChildLockScreen()));
    } on ApiException {
      setState(() => error = 'رمز الربط غير صحيح، تأكد منه مع ولي الأمر');
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
              Text('أدخل رمز الربط الذي حصلت عليه من تطبيق ولي الأمر', style: bodyFont(fontSize: 14, color: WiamColors.inkMutedLight)),
              const SizedBox(height: 24),
              TextField(controller: tokenCtrl, decoration: const InputDecoration(labelText: 'رمز الربط')),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: bodyFont(color: WiamColors.coralDeep, fontSize: 13)),
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
