import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api_client.dart';
import '../models.dart';
import '../storage.dart';

class ChildDeviceState extends ChangeNotifier {
  final ApiClient api;
  bool paired = false;
  bool restoring = true;
  ChildState? state;

  /// Set when the last poll couldn't reach the server. The child screens
  /// keep showing the last known state and flag it rather than going blank.
  bool offline = false;
  Timer? _poller;

  ChildDeviceState(this.api);

  Future<void> restore() async {
    try {
      final token = await Storage.loadDeviceToken();
      if (token != null) {
        api.deviceToken = token;
        paired = true;
        await refresh();
      }
    } catch (_) {
      // A device that is already paired stays paired even if the server is
      // unreachable right now — otherwise a flaky network would dump the
      // child back onto the pairing screen, or hang the app on its spinner.
      offline = true;
    } finally {
      restoring = false;
      notifyListeners();
    }
  }

  /// Exchanges the 3-digit code shown on the parent's phone for a real,
  /// long-lived device token — the code itself is never stored or reused.
  Future<void> pair(String pairingCode) async {
    final res = await api.post('/api/child/pair', body: {'pairingCode': pairingCode});
    final deviceToken = res['deviceToken'] as String;
    api.deviceToken = deviceToken;
    await refresh();
    await Storage.saveDeviceToken(deviceToken);
    paired = true;
    offline = false;
    notifyListeners();
  }

  /// Never throws — it runs on a timer, and an unhandled failure inside a
  /// timer callback would take down the zone rather than the request.
  Future<void> refresh() async {
    try {
      final res = await api.get('/api/child/state', asChild: true);
      state = ChildState.fromJson(res);
      offline = false;
    } catch (_) {
      offline = true;
    }
    notifyListeners();
  }

  Future<void> completeDigitalTask(String taskId) async {
    await api.post('/api/child/tasks/$taskId/complete-digital', asChild: true);
    await refresh();
  }

  Future<void> startSession() async {
    await api.post('/api/child/session/start', asChild: true);
    await refresh();
  }

  /// Polls the session endpoint while a play screen is on-screen. The
  /// remaining time always comes from the server — the device clock is
  /// never trusted to drive the countdown.
  void startPolling({Duration every = const Duration(seconds: 2)}) {
    _poller?.cancel();
    _poller = Timer.periodic(every, (_) => refresh());
  }

  void stopPolling() {
    _poller?.cancel();
    _poller = null;
  }

  Future<void> unpair() async {
    stopPolling();
    api.deviceToken = null;
    paired = false;
    state = null;
    await Storage.clearDeviceToken();
    await Storage.clearAllLevelProgress(); // this device may get paired to a different child next
    notifyListeners();
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }
}
