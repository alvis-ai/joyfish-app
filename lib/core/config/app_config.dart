import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _defaultApiBaseUrl = 'https://joyfishstory.cn';

  static late AppConfig _instance;
  static AppConfig get instance => _instance;

  final String environment;
  final String baseUrl;
  final bool enableLog;
  final bool enableCrashReport;
  final int connectTimeout;
  final int receiveTimeout;

  const AppConfig._({
    required this.environment,
    required this.baseUrl,
    required this.enableLog,
    required this.enableCrashReport,
    required this.connectTimeout,
    required this.receiveTimeout,
  });

  static Future<void> init() async {
    _instance = AppConfig._(
      environment: kDebugMode ? 'dev' : 'prod',
      baseUrl: _resolveBaseUrl(),
      enableLog: kDebugMode,
      enableCrashReport: !kDebugMode,
      connectTimeout: 15000,
      receiveTimeout: 30000,
    );
  }

  bool get isDev => environment == 'dev';

  static String _resolveBaseUrl() {
    const defined = String.fromEnvironment('JOYFISH_API_BASE_URL');
    if (defined.trim().isNotEmpty) {
      return _normalizeBaseUrl(defined.trim());
    }

    return _defaultApiBaseUrl;
  }

  static String _normalizeBaseUrl(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  String? resolveMediaUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final value = raw.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    if (value.startsWith('/')) {
      return '$baseUrl$value';
    }

    return '$baseUrl/$value';
  }
}
