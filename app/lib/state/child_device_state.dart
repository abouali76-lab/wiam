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
  Timer? _poller;

  ChildDeviceState(this.api);

  Future<void> restore() async {
    final token = await Storage.loadDeviceToken();
    if (token != null) {
      api.deviceToken = token;
      paired = true;
      await refresh();
    }
    restoring = false;
    notifyListeners();
  }

  Future<void> pair(String deviceToken) async {
    api.deviceToken = deviceToken;
    await refresh(); // throws ApiException if the token is invalid
    await Storage.saveDeviceToken(deviceToken);
    paired = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    final res = await api.get('/api/child/state', asChild: true);
    state = ChildState.fromJson(res);
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
    notifyListeners();
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }
}
