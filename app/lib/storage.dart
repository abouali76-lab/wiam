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
}
