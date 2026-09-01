import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/parent_state.dart';
import 'parent_auth_screen.dart';
import 'parent_dashboard_screen.dart';

/// Routes to whichever parent screen makes sense right now — used when
/// jumping to the parent side from a paired child device (see
/// ChildLockScreen's "الدخول كولي أمر"), where we can't just rely on
/// ModeSelectScreen's routing since the device is already child-paired.
class ParentEntryScreen extends StatelessWidget {
  const ParentEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<ParentAppState>().loggedIn;
    return loggedIn ? const ParentDashboardScreen() : const ParentAuthScreen();
  }
}
