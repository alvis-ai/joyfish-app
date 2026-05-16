import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../log/app_logger.dart';

class StorageManager {
  static late SharedPreferences _prefs;
  static late Box<dynamic> _box;

  static const String _keyToken = 'user_token';
  static const String _keyUserInfo = 'user_info';
  static const String _keySelectedChild = 'selected_child';
  static const String _keySettings = 'app_settings';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _box = await Hive.openBox<dynamic>('joyfish_app_storage');
    AppLogger.info('Storage ready');
  }

  static Future<void> saveToken(String token) async {
    await _prefs.setString(_keyToken, token);
  }

  static Future<String?> getToken() async {
    return _prefs.getString(_keyToken);
  }

  static Future<void> clearToken() async {
    await _prefs.remove(_keyToken);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> saveUserInfo(Map<String, dynamic> userInfo) async {
    await _box.put(_keyUserInfo, userInfo);
  }

  static Map<String, dynamic>? getUserInfo() {
    final data = _box.get(_keyUserInfo);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  static Future<void> clearUserInfo() async {
    await _box.delete(_keyUserInfo);
  }

  static Future<void> saveSelectedChild(Map<String, dynamic> child) async {
    await _box.put(_keySelectedChild, child);
  }

  static Map<String, dynamic>? getSelectedChild() {
    final data = _box.get(_keySelectedChild);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  static Future<void> clearSelectedChild() async {
    await _box.delete(_keySelectedChild);
  }

  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _box.put(_keySettings, settings);
  }

  static Map<String, dynamic>? getSettings() {
    final data = _box.get(_keySettings);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  static Future<void> saveCacheValue(String key, dynamic value) async {
    await _box.put(key, value);
  }

  static dynamic getCacheValue(String key) {
    return _box.get(key);
  }

  static Future<void> deleteCacheValue(String key) async {
    await _box.delete(key);
  }

  static Future<void> clearSession() async {
    await clearToken();
    await clearUserInfo();
    await clearSelectedChild();
  }

  static Future<void> clearAll() async {
    await _prefs.clear();
    await _box.clear();
  }
}
