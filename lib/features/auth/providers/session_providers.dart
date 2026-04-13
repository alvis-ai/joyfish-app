import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_manager.dart';
import '../models/auth_models.dart';
import '../repository/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class SessionState {
  final bool initialized;
  final bool bootstrapping;
  final bool submitting;
  final AuthUser? user;
  final String? error;

  const SessionState({
    this.initialized = false,
    this.bootstrapping = false,
    this.submitting = false,
    this.user,
    this.error,
  });

  bool get isAuthenticated => user != null;

  SessionState copyWith({
    bool? initialized,
    bool? bootstrapping,
    bool? submitting,
    AuthUser? user,
    String? error,
    bool clearError = false,
  }) {
    return SessionState(
      initialized: initialized ?? this.initialized,
      bootstrapping: bootstrapping ?? this.bootstrapping,
      submitting: submitting ?? this.submitting,
      user: user ?? this.user,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class SessionController extends StateNotifier<SessionState> {
  SessionController(this.ref) : super(const SessionState());

  final Ref ref;

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> bootstrap() async {
    if (state.bootstrapping || state.initialized) {
      return;
    }

    state = state.copyWith(bootstrapping: true, clearError: true);
    final token = await StorageManager.getToken();
    if (token == null || token.isEmpty) {
      state = state.copyWith(initialized: true, bootstrapping: false, user: null);
      return;
    }

    try {
      final user = await _repository.fetchMe();
      await StorageManager.saveUserInfo(user.toJson());
      state = state.copyWith(
        initialized: true,
        bootstrapping: false,
        user: user,
        clearError: true,
      );
    } catch (error) {
      await StorageManager.clearSession();
      state = state.copyWith(
        initialized: true,
        bootstrapping: false,
        user: null,
        error: error.toString(),
      );
    }
  }

  Future<void> loginWithPassword({
    required String phoneNumber,
    required String password,
  }) async {
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final session = await _repository.loginWithPassword(
        phoneNumber: phoneNumber,
        password: password,
      );
      await _persistSession(session);
    } catch (error) {
      state = state.copyWith(submitting: false, error: error.toString());
    }
  }

  Future<void> loginWithSms({
    required String phoneNumber,
    required String smsCode,
  }) async {
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final session = await _repository.loginWithSms(
        phoneNumber: phoneNumber,
        smsCode: smsCode,
      );
      await _persistSession(session);
    } catch (error) {
      state = state.copyWith(submitting: false, error: error.toString());
    }
  }

  Future<void> register({
    required String phoneNumber,
    required String password,
    required String smsCode,
  }) async {
    state = state.copyWith(submitting: true, clearError: true);
    try {
      await _repository.register(
        phoneNumber: phoneNumber,
        password: password,
        smsCode: smsCode,
      );
      final session = await _repository.loginWithPassword(
        phoneNumber: phoneNumber,
        password: password,
      );
      await _persistSession(session);
    } catch (error) {
      state = state.copyWith(submitting: false, error: error.toString());
    }
  }

  Future<void> logout() async {
    state = state.copyWith(submitting: true, clearError: true);
    try {
      await _repository.logout();
    } catch (_) {
      // Server-side logout failure should not block local sign-out.
    } finally {
      await StorageManager.clearSession();
      state = const SessionState(initialized: true);
    }
  }

  Future<void> handleSessionExpired() async {
    await StorageManager.clearSession();
    state = const SessionState(
      initialized: true,
      error: '登录状态已过期，请重新登录',
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> _persistSession(AuthSession session) async {
    await StorageManager.saveToken(session.token);
    await StorageManager.saveUserInfo(session.user.toJson());
    state = state.copyWith(
      initialized: true,
      bootstrapping: false,
      submitting: false,
      user: session.user,
      clearError: true,
    );
  }
}

final sessionControllerProvider =
    StateNotifierProvider<SessionController, SessionState>((ref) {
  return SessionController(ref);
});
