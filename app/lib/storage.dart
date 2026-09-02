import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static const _parentTokenKey = 'parent_token';
  static const _deviceTokenKey = 'device_token';

  static Future<void> saveParentToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_parentTokenKey, token);
  }

  static Future<String?> loadParentToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_parentTokenKey);
  }

  static Future<void> saveDeviceToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceTokenKey, token);
  }

  static Future<String?> loadDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceTokenKey);
  }

  static Future<void> clearDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceTokenKey);
  }

  static Future<void> clearParentToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_parentTokenKey);
  }

  // Opt-in convenience for the login form ("تذكرني") — separate from the
  // session token above, which is what actually keeps a parent signed in.
  // This only saves re-typing after an explicit logout. Stored in plain
  // shared_preferences on-device, same as the rest of this app's local
  // state — not for anything more sensitive than a family device's PIN.
  static const _rememberedIdentifierKey = 'remembered_identifier';
  static const _rememberedPasswordKey = 'remembered_password';

  static Future<void> saveRememberedLogin(String identifier, String? password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rememberedIdentifierKey, identifier);
    if (password != null) {
      await prefs.setString(_rememberedPasswordKey, password);
    } else {
      await prefs.remove(_rememberedPasswordKey);
    }
  }

  static Future<(String?, String?)> loadRememberedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_rememberedIdentifierKey), prefs.getString(_rememberedPasswordKey));
  }

  static Future<void> clearRememberedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberedIdentifierKey);
    await prefs.remove(_rememberedPasswordKey);
  }

  // Per-game level progress on this paired device. Advancing a level is
  // gated on a fresh day of fully-completed tasks (see ChildPlayScreen),
  // so `lastLevelUpDate` records the child's local "YYYY-MM-DD" (from the
  // server, same field driving the daily task reset) on which they last
  // moved up — that's what stops leveling up twice in one sitting.
  static Future<int> loadUnlockedLevel(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('level_unlocked_$gameId') ?? 1;
  }

  static Future<void> saveUnlockedLevel(String gameId, int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('level_unlocked_$gameId', level);
  }

  static Future<String?> loadLastLevelUpDate(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('level_up_date_$gameId');
  }

  static Future<void> saveLastLevelUpDate(String gameId, String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('level_up_date_$gameId', date);
  }

  static const _levelGameIds = [
    'memory',
    'stars',
    'bubbles',
    'food',
    'handwash',
    'traffic',
    'waste',
    'feelings',
    'market',
  ];

  static Future<void> clearAllLevelProgress() async {
    final prefs = await SharedPreferences.getInstance();
    for (final id in _levelGameIds) {
      await prefs.remove('level_unlocked_$id');
      await prefs.remove('level_up_date_$id');
    }
  }
}
