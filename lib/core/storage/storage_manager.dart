import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  static const String _keySecureTokenReady = 'secure_token_ready';

  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// 登录 token 在 iOS / Android 上存进 Keychain / Keystore。
  /// 其他平台只用于开发调试，继续使用 SharedPreferences。
  static bool get _useSecureToken =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  static String? _token;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _box = await Hive.openBox<dynamic>('joyfish_app_storage');
    await _loadToken();
    AppLogger.info('Storage ready');
  }

  static Future<void> _loadToken() async {
    if (!_useSecureToken) {
      _token = _prefs.getString(_keyToken);
      return;
    }

    final legacy = _prefs.getString(_keyToken);
    if (legacy != null && legacy.isNotEmpty) {
      // 旧版本把 token 明文存在 SharedPreferences，迁移后删除明文。
      await _secure.write(key: _keyToken, value: legacy);
      await _prefs.remove(_keyToken);
      _token = legacy;
    } else if (_prefs.getBool(_keySecureTokenReady) != true) {
      // iOS 卸载重装后 Keychain 里的旧 token 还在，首次启动时清掉。
      await _secure.delete(key: _keyToken);
      _token = null;
    } else {
      _token = await _secure.read(key: _keyToken);
    }
    await _prefs.setBool(_keySecureTokenReady, true);
  }

  static Future<void> saveToken(String token) async {
    _token = token;
    if (_useSecureToken) {
      await _secure.write(key: _keyToken, value: token);
    } else {
      await _prefs.setString(_keyToken, token);
    }
  }

  static Future<String?> getToken() async {
    return _token;
  }

  static Future<void> clearToken() async {
    _token = null;
    if (_useSecureToken) {
      await _secure.delete(key: _keyToken);
    } else {
      await _prefs.remove(_keyToken);
    }
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
    await clearToken();
    await _prefs.clear();
    await _box.clear();
  }
}
