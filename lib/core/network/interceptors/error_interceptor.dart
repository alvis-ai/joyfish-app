import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
    if (payload is Map) {
      final message = payload['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    final rawError = err.error?.toString();
    if (rawError != null) {
      if (rawError.contains('App Transport Security')) {
        return 'iPhone 当前不允许访问开发服务器，请重新安装最新构建';
      }
      if (rawError.contains('Connection refused') ||
          rawError.contains('Failed host lookup') ||
          rawError.contains('No route to host')) {
        return '无法连接到开发服务器，请确认手机与电脑在同一网络且后端已启动';
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
      case DioExceptionType.badCertificate:
        return '证书校验失败，请检查服务地址';
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.connectionError:
        return '无法连接到开发服务器，请确认手机与电脑在同一网络且后端已启动';
      case DioExceptionType.unknown:
        return '网络异常，请稍后重试';
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
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return;
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
    );
  }
}
