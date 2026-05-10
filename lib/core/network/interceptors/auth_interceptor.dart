import 'package:dio/dio.dart';

import '../../log/app_logger.dart';
import '../../storage/storage_manager.dart';
import '../auth_session_bus.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await StorageManager.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && _shouldExpireSession(err)) {
      AppLogger.warning('Received 401 response, clearing local session');
      await StorageManager.clearSession();
      AuthSessionBus.emitExpired();
    }
    super.onError(err, handler);
  }

  bool _shouldExpireSession(DioException err) {
    final path = err.requestOptions.path;
    final hasToken =
        err.requestOptions.headers['Authorization']?.toString().isNotEmpty ??
            false;
    if (!hasToken) {
      return false;
    }
    return path != '/auth/login' &&
        path != '/auth/register' &&
        path != '/auth/sms-code';
  }
}
