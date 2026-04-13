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
    if (err.response?.statusCode == 401) {
      AppLogger.warning('Received 401 response, clearing local session');
      await StorageManager.clearSession();
      AuthSessionBus.emitExpired();
    }
    super.onError(err, handler);
  }
}
