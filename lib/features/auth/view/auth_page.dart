import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/joyfish_scaffold.dart';
import '../../../core/router/app_router.dart';
import '../providers/session_providers.dart';

enum _AuthMode { sms, password, register }

@RoutePage()
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _loginPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _smsCodeController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  final _registerCodeController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  _AuthMode _mode = _AuthMode.sms;
  bool _smsRequested = false;
  String? _loginDebugCode;
  String? _registerDebugCode;

  @override
  void dispose() {
    _loginPhoneController.dispose();
    _passwordController.dispose();
    _smsCodeController.dispose();
    _registerPhoneController.dispose();
    _registerCodeController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionControllerProvider);
    final sessionNotifier = ref.read(sessionControllerProvider.notifier);

    ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.error!)));
      }
      if (next.isAuthenticated && !(previous?.isAuthenticated ?? false)) {
        context.router.replace(const MainShellRoute());
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE2A9), Color(0xFFF4B3D8), Color(0xFFB59AF5)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = _mode == _AuthMode.register;
              final logoSize = 120.w;
              final topPadding = 30.h;
              final bottomPadding = 24.h;
              final titleGap = 24.h;
              final cardPadding = compact
                  ? EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 14.h)
                  : EdgeInsets.fromLTRB(22.w, 22.h, 22.w, 20.h);
              final rawCardMaxHeight = compact
                  ? constraints.maxHeight - 206.h
                  : constraints.maxHeight - 274.h;
              final cardMaxHeight = rawCardMaxHeight.clamp(300.h, constraints.maxHeight - 120.h);
              final targetCardHeight = _cardHeightForMode(cardMaxHeight);

              return Padding(
                padding: EdgeInsets.fromLTRB(28.w, topPadding, 28.w, bottomPadding),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: logoSize,
                            height: logoSize,
                            child: SvgPicture.asset('assets/images/home_hero.svg'),
                          ),
                          SizedBox(height: titleGap),
                          Text('乐鱼故事', style: Theme.of(context).textTheme.displayMedium),
                          SizedBox(height: 10.h),
                          Text(
                            '专属于你的睡前故事',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: const Color(0xFF8A59D7),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        height: targetCardHeight,
                        child: JoyfishCard(
                          radius: 30.r,
                          padding: cardPadding,
                          backgroundColor: Colors.white.withValues(alpha: 0.86),
                          child: SingleChildScrollView(
                            physics: compact
                                ? const ClampingScrollPhysics()
                                : const NeverScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _titleForMode(),
                                  style: Theme.of(context).textTheme.headlineLarge,
                                ),
                                SizedBox(height: compact ? 12.h : 18.h),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: _buildFormContent(sessionState, sessionNotifier),
                                ),
                                SizedBox(height: compact ? 8.h : 16.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _FooterLink(
                                      text: '手机号登录',
                                      active: _mode == _AuthMode.sms,
                                      onTap: () => _switchMode(_AuthMode.sms),
                                    ),
                                    _DotDivider(),
                                    _FooterLink(
                                      text: '密码登录',
                                      active: _mode == _AuthMode.password,
                                      onTap: () => _switchMode(_AuthMode.password),
                                    ),
                                    _DotDivider(),
                                    _FooterLink(
                                      text: '注册',
                                      active: _mode == _AuthMode.register,
                                      onTap: () => _switchMode(_AuthMode.register),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(SessionState sessionState, SessionController sessionNotifier) {
    switch (_mode) {
      case _AuthMode.sms:
        final phoneValid = _loginPhoneController.text.trim().length >= 11;
        final codeValid = _smsCodeController.text.trim().length >= 4;
        return Column(
          key: const ValueKey('sms'),
          children: [
            _phoneField(_loginPhoneController),
            if (_smsRequested) ...[
              SizedBox(height: 12.h),
              _codeField(_smsCodeController),
            ],
            SizedBox(height: 16.h),
            AppButton(
              text: _smsRequested ? '进入乐鱼故事' : '获取验证码',
              isLoading: sessionState.submitting,
              height: 54.h,
              onPressed: !phoneValid
                  ? null
                  : () async {
                      if (!_smsRequested) {
                        await _requestCode(phone: _loginPhoneController.text, purpose: 'login');
                        if (mounted) {
                          setState(() => _smsRequested = true);
                        }
                        return;
                      }
                      if (!codeValid) return;
                      await sessionNotifier.loginWithSms(
                        phoneNumber: _loginPhoneController.text.trim(),
                        smsCode: _smsCodeController.text.trim(),
                      );
                    },
            ),
            SizedBox(height: 12.h),
            Text(
              '登录即同意《用户协议》和《隐私政策》',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.mutedInk,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (kDebugMode && _loginDebugCode != null) ...[
              SizedBox(height: 12.h),
              _debugBadge('调试验证码: $_loginDebugCode'),
            ],
          ],
        );
      case _AuthMode.password:
        return Column(
          key: const ValueKey('password'),
          children: [
            _phoneField(_loginPhoneController),
            SizedBox(height: 12.h),
            _passwordField(_passwordController, hint: '请输入密码'),
            SizedBox(height: 16.h),
            AppButton(
              text: '登录',
              isLoading: sessionState.submitting,
              height: 54.h,
              onPressed: _loginPhoneController.text.trim().length >= 11 &&
                      _passwordController.text.trim().length >= 6
                  ? () => sessionNotifier.loginWithPassword(
                        phoneNumber: _loginPhoneController.text.trim(),
                        password: _passwordController.text.trim(),
                      )
                  : null,
            ),
          ],
        );
      case _AuthMode.register:
        return Column(
          key: const ValueKey('register'),
          children: [
            _phoneField(_registerPhoneController),
            SizedBox(height: 10.h),
            _codeField(_registerCodeController),
            SizedBox(height: 4.h),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _registerPhoneController.text.trim().length >= 11
                    ? () => _requestCode(
                          phone: _registerPhoneController.text,
                          purpose: 'register',
                        )
                    : null,
                child: const Text('获取注册验证码'),
              ),
            ),
            SizedBox(height: 4.h),
            _passwordField(_registerPasswordController, hint: '设置 6 位以上密码'),
            SizedBox(height: 14.h),
            AppButton(
              text: '注册并登录',
              isLoading: sessionState.submitting,
              height: 52.h,
              onPressed: _registerPhoneController.text.trim().length >= 11 &&
                      _registerCodeController.text.trim().length >= 4 &&
                      _registerPasswordController.text.trim().length >= 6
                  ? () => sessionNotifier.register(
                        phoneNumber: _registerPhoneController.text.trim(),
                        password: _registerPasswordController.text.trim(),
                        smsCode: _registerCodeController.text.trim(),
                      )
                  : null,
            ),
            if (kDebugMode && _registerDebugCode != null) ...[
              SizedBox(height: 12.h),
              _debugBadge('调试验证码: $_registerDebugCode'),
            ],
          ],
        );
    }
  }

  String _titleForMode() {
    switch (_mode) {
      case _AuthMode.sms:
        return '手机号登录';
      case _AuthMode.password:
        return '密码登录';
      case _AuthMode.register:
        return '注册账号';
    }
  }

  double _cardHeightForMode(double maxHeight) {
    final target = switch (_mode) {
      _AuthMode.sms => _smsRequested ? 404.h : 322.h,
      _AuthMode.password => 378.h,
      _AuthMode.register => 470.h,
    };
    return target.clamp(300.h, maxHeight);
  }

  void _switchMode(_AuthMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      if (mode != _AuthMode.sms) {
        _smsRequested = false;
      }
    });
  }

  Widget _phoneField(TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      onChanged: (_) => setState(() {}),
      decoration: const InputDecoration(hintText: '请输入手机号'),
    );
  }

  Widget _codeField(TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      decoration: const InputDecoration(hintText: '请输入验证码'),
    );
  }

  Widget _passwordField(TextEditingController controller, {required String hint}) {
    return TextField(
      controller: controller,
      obscureText: true,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(hintText: hint),
    );
  }

  Future<void> _requestCode({
    required String phone,
    required String purpose,
  }) async {
    final result = await ref.read(authRepositoryProvider).requestSmsCode(
          phoneNumber: phone.trim(),
          purpose: purpose,
        );
    if (!mounted) return;
    setState(() {
      if (purpose == 'login') {
        _loginDebugCode = result.debugCode;
      } else {
        _registerDebugCode = result.debugCode;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('验证码已发送到 ${result.phoneNumber}')),
    );
  }

  Widget _debugBadge(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Text(
        text,
        style: TextStyle(color: AppTheme.purple, fontSize: 12.sp, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.text,
    required this.active,
    required this.onTap,
  });

  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        text,
        style: TextStyle(
          color: active ? AppTheme.purple : AppTheme.mutedInk,
          fontWeight: active ? FontWeight.w700 : FontWeight.w600,
          fontSize: 12.sp,
        ),
      ),
    );
  }
}

class _DotDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4.w,
      height: 4.h,
      margin: EdgeInsets.symmetric(horizontal: 2.w),
      decoration: const BoxDecoration(
        color: AppTheme.mutedInk,
        shape: BoxShape.circle,
      ),
    );
  }
}
