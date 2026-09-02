import 'package:flutter/foundation.dart';
import '../api_client.dart';
import '../models.dart';
import '../storage.dart';

class PairingCode {
  final String code;
  final DateTime expiresAt;
  PairingCode({required this.code, required this.expiresAt});
}

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

  /// True when the last server call failed for a reason other than the
  /// server answering (no network, server down). Surfaced in the UI so the
  /// parent knows the numbers on screen may be stale.
  bool offline = false;
  List<ParentChildSummary> children = [];

  ParentAppState(this.api);

  Future<void> restoreSession() async {
    try {
      final token = await Storage.loadParentToken();
      if (token != null) {
        api.parentToken = token;
        loggedIn = true;
        await refreshChildren();
      }
    } catch (_) {
      // Never let a failure here strand the app on its loading spinner —
      // an unreachable server at launch is normal, not fatal.
      offline = true;
    } finally {
      restoring = false;
      notifyListeners();
    }
  }

  /// `identifier` is whatever the parent typed to log in — their email, or
  /// the username they chose at signup (which may be all digits).
  Future<bool> login(String identifier, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final res = await api.post('/api/parent/login', body: {'identifier': identifier, 'password': password});
      api.parentToken = res['token'];
      await Storage.saveParentToken(res['token']);
      loggedIn = true;
      offline = false;
      await refreshChildren();
      return true;
    } on ApiException catch (e) {
      error = switch (e.error) {
        'invalid_credentials' => 'البيانات غير صحيحة',
        'too_many_requests' => 'محاولات كثيرة، انتظر قليلاً ثم أعد المحاولة',
        _ => 'تعذر تسجيل الدخول',
      };
      return false;
    } catch (_) {
      offline = true;
      error = 'تعذر الاتصال بالخادم، تحقق من الشبكة';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String username, String password, String childName) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final res = await api.post('/api/parent/register', body: {
        'email': email,
        if (username.trim().isNotEmpty) 'username': username.trim(),
        'password': password,
        'childName': childName,
      });
      api.parentToken = res['token'];
      await Storage.saveParentToken(res['token']);
      loggedIn = true;
      offline = false;
      await refreshChildren();
      return true;
    } on ApiException catch (e) {
      error = switch (e.error) {
        'email_taken' => 'هذا البريد مستخدم مسبقاً',
        'username_taken' => 'اسم المستخدم هذا محجوز، اختر غيره',
        'password_too_short' => 'كلمة المرور قصيرة، استخدم 6 خانات على الأقل',
        'too_many_requests' => 'محاولات كثيرة، انتظر قليلاً ثم أعد المحاولة',
        _ => 'تعذر إنشاء الحساب',
      };
      return false;
    } catch (_) {
      offline = true;
      error = 'تعذر الاتصال بالخادم، تحقق من الشبكة';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Refreshes the dashboard. Deliberately does not throw: it is called from
  /// pull-to-refresh, timers and after every mutation, and a dropped
  /// connection should show a stale-data banner rather than crash a screen.
  Future<void> refreshChildren() async {
    try {
      final list = await api.get('/api/parent/children', asParent: true) as List;
      children = list.map((raw) {
        final state = ChildState.fromJson(raw);
        return ParentChildSummary(childId: state.childId, name: state.childName, state: state);
      }).toList();
      offline = false;
    } catch (_) {
      offline = true;
    }
    notifyListeners();
  }

  /// Lets a parent who registered with just email/password add the
  /// shorter username later, from account settings.
  Future<void> setUsername(String username) async {
    await api.post('/api/parent/username', asParent: true, body: {'username': username});
  }

  Future<PairingCode> startPairing(String childId) async {
    final res = await api.post('/api/parent/children/$childId/pairing-code', asParent: true);
    return PairingCode(code: res['pairingCode'], expiresAt: DateTime.parse(res['expiresAt']));
  }

  Future<void> confirmExternalTask(String taskId) async {
    await api.post('/api/parent/tasks/$taskId/confirm', asParent: true);
    await refreshChildren();
  }

  Future<void> freeze(String childId) async {
    await api.post('/api/parent/children/$childId/freeze', asParent: true);
    await refreshChildren();
  }

  Future<void> unfreeze(String childId) async {
    await api.post('/api/parent/children/$childId/unfreeze', asParent: true);
    await refreshChildren();
  }

  Future<void> deleteTask(String childId, String taskId) async {
    await api.delete('/api/parent/children/$childId/tasks/$taskId', asParent: true);
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
