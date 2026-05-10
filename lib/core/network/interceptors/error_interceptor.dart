import 'dart:convert';

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
    final payload = _readPayload(err.response?.data);
    if (payload is Map) {
      final code = payload['code']?.toString();
      final mapped = _messageForBusinessCode(code, err);
      if (mapped != null) {
        return mapped;
      }

      final message = payload['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return _translateBackendMessage(message.trim(), err);
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
        return _handleStatusCode(err.response?.statusCode, err);
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

  String _handleStatusCode(int? statusCode, DioException err) {
    switch (statusCode) {
      case 400:
        return '请求参数错误';
      case 401:
        if (err.requestOptions.path == '/auth/sms-code') {
          return '该手机号还没有注册，请先完成新用户注册';
        }
        if (err.requestOptions.path == '/auth/login') {
          return '手机号、密码或验证码不正确';
        }
        return '登录状态已过期，请重新登录';
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
    final data = _readPayload(payload);
    if (data is Map) {
      return data['code']?.toString();
    }
    return null;
  }

  Object? _readPayload(Object? payload) {
    if (payload is String) {
      try {
        return jsonDecode(payload);
      } catch (_) {
        return payload;
      }
    }
    return payload;
  }

  String? _messageForBusinessCode(String? code, DioException err) {
    switch (code) {
      case '10003':
        return '该手机号已注册，请直接登录';
      case '10004':
        return '该手机号还没有注册，请先完成新用户注册';
      case '10008':
        return '验证码请求太频繁，请稍后再试';
      case '10010':
        return '验证码无效或已过期，请重新获取';
      case '10013':
        return '请输入正确的手机号';
      case '10014':
        return '验证码服务暂不可用，请稍后再试';
    }
    return null;
  }

  String _translateBackendMessage(String message, DioException err) {
    switch (message) {
      case 'account not found':
        return '该手机号还没有注册，请先完成新用户注册';
      case 'phone number already registered':
        return '该手机号已注册，请直接登录';
      case 'invalid login credentials':
        return '手机号、密码或验证码不正确';
      case 'invalid or expired sms verification code':
      case 'invalid sms verification code':
        return '验证码无效或已过期，请重新获取';
      default:
        return message;
    }
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
