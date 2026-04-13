import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../log/app_logger.dart';
import '../api_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final errorMessage = _getErrorMessage(err);

    AppLogger.error(
      'Request failed: ${err.requestOptions.path}',
      error: errorMessage,
      stackTrace: err.stackTrace,
    );

    _showErrorToast(errorMessage);

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: ApiException(
          message: errorMessage,
          code: _readErrorCode(err.response?.data),
          statusCode: err.response?.statusCode,
        ),
        stackTrace: err.stackTrace,
      ),
    );
  }

  String _getErrorMessage(DioException err) {
    final payload = err.response?.data;
    if (payload is Map<String, dynamic>) {
      final message = payload['message'] as String?;
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时，请检查网络';
      case DioExceptionType.sendTimeout:
        return '发送超时，请检查网络';
      case DioExceptionType.receiveTimeout:
        return '接收超时，请检查网络';
      case DioExceptionType.badResponse:
        return _handleStatusCode(err.response?.statusCode);
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.unknown:
        return '网络异常，请稍后重试';
      default:
        return '未知错误';
    }
  }

  String _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '请求参数错误';
      case 401:
        return '未授权，请重新登录';
      case 403:
        return '禁止访问';
      case 404:
        return '请求的资源不存在';
      case 500:
        return '服务器内部错误';
      default:
        return '服务器错误($statusCode)';
    }
  }

  String? _readErrorCode(Object? payload) {
    if (payload is Map<String, dynamic>) {
      return payload['code'] as String?;
    }
    return null;
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
    );
  }
}
