import '../../../core/network/network_manager.dart';
import '../models/auth_models.dart';

class AuthRepository {
  Future<SmsCodeResult> requestSmsCode({
    required String phoneNumber,
    required String purpose,
  }) {
    return NetworkManager.requestEnvelope(
      () => NetworkManager.post(
        '/auth/sms-code',
        data: {
          'phone_number': phoneNumber,
          'purpose': purpose,
        },
      ),
      (data) => SmsCodeResult.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<AuthUser> register({
    required String phoneNumber,
    required String password,
    required String smsCode,
  }) {
    return NetworkManager.requestEnvelope(
      () => NetworkManager.post(
        '/auth/register',
        data: {
          'phone_number': phoneNumber,
          'password': password,
          'sms_code': smsCode,
        },
      ),
      (data) => AuthUser.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<AuthSession> loginWithPassword({
    required String phoneNumber,
    required String password,
  }) {
    return NetworkManager.requestEnvelope(
      () => NetworkManager.post(
        '/auth/login',
        data: {
          'phone_number': phoneNumber,
          'password': password,
        },
      ),
      (data) => AuthSession.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<AuthSession> loginWithSms({
    required String phoneNumber,
    required String smsCode,
  }) {
    return NetworkManager.requestEnvelope(
      () => NetworkManager.post(
        '/auth/login',
        data: {
          'phone_number': phoneNumber,
          'sms_code': smsCode,
        },
      ),
      (data) => AuthSession.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<AuthUser> fetchMe() {
    return NetworkManager.requestEnvelope(
      () => NetworkManager.get('/auth/me'),
      (data) => AuthUser.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  Future<void> logout() async {
    await NetworkManager.requestEnvelope(
      () => NetworkManager.post('/auth/logout'),
      (_) => true,
    );
  }
}
