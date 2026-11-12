import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
  });

  @override
  String toString() => message;
}

/// 连不上服务器时给用户看的提示。开发服务器的排查提示只在调试构建出现。
String connectionFailedMessage() {
  return kDebugMode
      ? '无法连接到开发服务器，请确认手机与电脑在同一网络且后端已启动'
      : '网络连接失败，请检查网络后重试';
}

String userFacingErrorMessage(Object error) {
  if (error is ApiException) {
    return _normalizeUserMessage(error.message);
  }

  if (error is DioException) {
    final inner = error.error;
    if (inner is ApiException) {
      return _normalizeUserMessage(inner.message);
    }

    final payload = error.response?.data;
    if (payload is Map) {
      final message = payload['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return _normalizeUserMessage(message);
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时，请检查网络后重试';
      case DioExceptionType.sendTimeout:
        return '发送超时，请检查网络后重试';
      case DioExceptionType.receiveTimeout:
        return '接收超时，请检查网络后重试';
      case DioExceptionType.connectionError:
        return connectionFailedMessage();
      case DioExceptionType.badResponse:
        return '服务器返回异常，请稍后重试';
      case DioExceptionType.badCertificate:
        return '证书校验失败，请检查服务地址';
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.unknown:
        return '网络异常，请稍后重试';
    }
  }

  final raw = error.toString().trim();
  if (raw.startsWith('Exception: ')) {
    return _normalizeUserMessage(raw.substring('Exception: '.length));
  }
  if (raw.startsWith('DioException')) {
    return '网络异常，请检查连接后重试';
  }
  return _normalizeUserMessage(raw);
}

String _normalizeUserMessage(String message) {
  if (message.contains('child_profile_gender_check')) {
    return '请选择正确的孩子性别后重试';
  }
  if (message.contains('error returned from database')) {
    return '保存失败，请检查填写内容后重试';
  }
  return message;
}
