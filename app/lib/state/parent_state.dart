import 'package:flutter/foundation.dart';
import '../api_client.dart';
import '../models.dart';
import '../storage.dart';

class ParentChildSummary {
  final String childId;
  final String name;
  final ChildState state;
  ParentChildSummary({required this.childId, required this.name, required this.state});
}

class ParentAppState extends ChangeNotifier {
  final ApiClient api;
  bool loggedIn = false;
  bool loading = false;
  bool restoring = true;
  String? error;
  List<ParentChildSummary> children = [];

  ParentAppState(this.api);

  Future<void> restoreSession() async {
    final token = await Storage.loadParentToken();
    if (token != null) {
      api.parentToken = token;
      loggedIn = true;
      await refreshChildren();
    }
    restoring = false;
    notifyListeners();
  }

  Future<bool> login(String email, String pin) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final res = await api.post('/api/parent/login', body: {'email': email, 'pin': pin});
      api.parentToken = res['token'];
      await Storage.saveParentToken(res['token']);
      loggedIn = true;
      await refreshChildren();
      return true;
    } on ApiException catch (e) {
      error = e.error == 'invalid_credentials' ? 'البريد أو الرمز غير صحيح' : 'تعذر تسجيل الدخول';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String pin, String childName) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final res = await api.post('/api/parent/register', body: {'email': email, 'pin': pin, 'childName': childName});
      api.parentToken = res['token'];
      await Storage.saveParentToken(res['token']);
      loggedIn = true;
      await refreshChildren();
      return true;
    } on ApiException catch (e) {
      error = e.error == 'email_taken' ? 'هذا البريد مستخدم مسبقاً' : 'تعذر إنشاء الحساب';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshChildren() async {
    final list = await api.get('/api/parent/children', asParent: true) as List;
    children = list
        .map((raw) {
          final state = ChildState.fromJson(raw);
          return ParentChildSummary(childId: state.childId, name: state.childName, state: state);
        })
        .toList();
    notifyListeners();
  }

  Future<String> issueDeviceToken(String childId) async {
    final res = await api.post('/api/parent/children/$childId/device-token', asParent: true);
    return res['deviceToken'];
  }

  Future<void> confirmExternalTask(String taskId) async {
    await api.post('/api/parent/tasks/$taskId/confirm', asParent: true);
    await refreshChildren();
  }

  Future<void> freeze(String childId) async {
    await api.post('/api/parent/children/$childId/freeze', asParent: true);
    await refreshChildren();
  }

  Future<void> logout() async {
    api.parentToken = null;
    loggedIn = false;
    children = [];
    await Storage.clearParentToken();
    notifyListeners();
  }
}
