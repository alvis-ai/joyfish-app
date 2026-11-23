import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/widgets/candy_widgets.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../providers/session_providers.dart';

enum _AuthMode { login, register }

enum _LoginMethod { sms, password }

@RoutePage()
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _loginPhoneController = TextEditingController();
  final _loginCodeController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerCodeController = TextEditingController();

  _AuthMode _mode = _AuthMode.register;
  _LoginMethod _loginMethod = _LoginMethod.sms;
  bool _acceptedLegal = false;
  bool _requestingLoginCode = false;
  bool _requestingRegisterCode = false;
  String? _loginDebugCode;
  String? _registerDebugCode;

  @override
  void dispose() {
    _loginPhoneController.dispose();
    _loginCodeController.dispose();
    _loginPasswordController.dispose();
    _registerPhoneController.dispose();
    _registerPasswordController.dispose();
    _registerCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionControllerProvider);
    final sessionNotifier = ref.read(sessionControllerProvider.notifier);

    ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
      if (next.isAuthenticated && !(previous?.isAuthenticated ?? false)) {
        context.router.replace(const MainShellRoute());
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppTheme.background,
      body: CandyBackground(
        child: SafeArea(
          child: _mode == _AuthMode.register
              ? _RegisterView(
                  phoneController: _registerPhoneController,
                  codeController: _registerCodeController,
                  passwordController: _registerPasswordController,
                  debugCode: _registerDebugCode,
                  requestingCode: _requestingRegisterCode,
                  submitting: sessionState.submitting,
                  onChanged: () => setState(() {}),
                  onRequestCode:
                      _registerPhoneController.text.trim().length >= 11 &&
                          !_requestingRegisterCode &&
                          !sessionState.submitting
                      ? () => _requestRegisterCode(
                          _registerPhoneController.text.trim(),
                        )
                      : null,
                  onLoginTap: () => setState(() => _mode = _AuthMode.login),
                  onOpenTerms: () =>
                      _openLegalDocument('/static/legal/user-agreement.html'),
                  onOpenPrivacy: () =>
                      _openLegalDocument('/static/legal/privacy-policy.html'),
                  acceptedLegal: _acceptedLegal,
                  onAcceptedLegalChanged: (value) =>
                      setState(() => _acceptedLegal = value),
                  onSubmit: _acceptedLegal && _canRegister()
                      ? () => _register(sessionNotifier)
                      : null,
                )
              : _LoginView(
                  phoneController: _loginPhoneController,
                  codeController: _loginCodeController,
                  passwordController: _loginPasswordController,
                  method: _loginMethod,
                  debugCode: _loginDebugCode,
                  requestingCode: _requestingLoginCode,
                  submitting: sessionState.submitting,
                  onChanged: () => setState(() {}),
                  onRequestCode:
                      _loginPhoneController.text.trim().length >= 11 &&
                          !_requestingLoginCode &&
                          !sessionState.submitting
                      ? () =>
                            _requestLoginCode(_loginPhoneController.text.trim())
                      : null,
                  onSwitchMethod: (method) =>
                      setState(() => _loginMethod = method),
                  onRegisterTap: () =>
                      setState(() => _mode = _AuthMode.register),
                  onOpenTerms: () =>
                      _openLegalDocument('/static/legal/user-agreement.html'),
                  onOpenPrivacy: () =>
                      _openLegalDocument('/static/legal/privacy-policy.html'),
                  acceptedLegal: _acceptedLegal,
                  onAcceptedLegalChanged: (value) =>
                      setState(() => _acceptedLegal = value),
                  onSubmit: _acceptedLegal && _canLogin()
                      ? () => _login(sessionNotifier)
                      : null,
                ),
        ),
      ),
    );
  }

  bool _canLogin() {
    final hasPhone = _loginPhoneController.text.trim().length >= 11;
    if (_loginMethod == _LoginMethod.password) {
      return hasPhone && _loginPasswordController.text.trim().length >= 6;
    }
    return hasPhone && _loginCodeController.text.trim().length >= 4;
  }

  bool _canRegister() {
    return _registerPhoneController.text.trim().length >= 11 &&
        _registerCodeController.text.trim().length >= 4 &&
        _registerPasswordController.text.trim().length >= 6;
  }

  Future<void> _register(SessionController sessionNotifier) async {
    final phone = _registerPhoneController.text.trim();
    final password = _registerPasswordController.text.trim();
    final smsCode = _registerCodeController.text.trim();
    if (smsCode.isEmpty) {
      _showMessage('验证码已发送，请输入短信验证码后再注册');
      return;
    }

    await sessionNotifier.register(
      phoneNumber: phone,
      password: password,
      smsCode: smsCode,
    );
  }

  Future<void> _login(SessionController sessionNotifier) async {
    final phone = _loginPhoneController.text.trim();
    if (_loginMethod == _LoginMethod.password) {
      final password = _loginPasswordController.text.trim();
      await sessionNotifier.loginWithPassword(
        phoneNumber: phone,
        password: password,
      );
      return;
    }

    final smsCode = _loginCodeController.text.trim();
    if (smsCode.isEmpty) {
      _showMessage('验证码已发送，请输入短信验证码后再登录');
      return;
    }

    await sessionNotifier.loginWithSms(phoneNumber: phone, smsCode: smsCode);
  }

  Future<bool> _requestLoginCode(String phone) async {
    setState(() => _requestingLoginCode = true);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .requestSmsCode(phoneNumber: phone, purpose: 'login');
      if (!mounted) return false;
      setState(() {
        _loginDebugCode = result.debugCode;
        if (result.debugCode != null) {
          _loginCodeController.text = result.debugCode!;
        }
      });
      _showMessage(
        result.debugCode == null
            ? '验证码已发送到 ${result.phoneNumber}'
            : '本地测试验证码 ${result.debugCode}，已自动填入',
      );
      return true;
    } catch (error) {
      if (mounted) _showMessage(_friendlyError(error));
      return false;
    } finally {
      if (mounted) setState(() => _requestingLoginCode = false);
    }
  }

  Future<bool> _requestRegisterCode(String phone) async {
    setState(() => _requestingRegisterCode = true);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .requestSmsCode(phoneNumber: phone, purpose: 'register');
      if (!mounted) return false;
      setState(() {
        _registerDebugCode = result.debugCode;
        if (result.debugCode != null) {
          _registerCodeController.text = result.debugCode!;
        }
      });
      _showMessage(
        result.debugCode == null
            ? '验证码已发送到 ${result.phoneNumber}'
            : '本地测试验证码 ${result.debugCode}，已自动填入',
      );
      return true;
    } catch (error) {
      if (mounted) _showMessage(_friendlyError(error));
      return false;
    } finally {
      if (mounted) setState(() => _requestingRegisterCode = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openLegalDocument(String path) async {
    final uri = Uri.parse('${AppConfig.instance.baseUrl}$path');
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      if (!opened) {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      _showMessage('暂时无法打开页面，请稍后再试');
    }
  }

  String _friendlyError(Object error) {
    return userFacingErrorMessage(error);
  }
}

class _RegisterView extends StatelessWidget {
  const _RegisterView({
    required this.phoneController,
    required this.codeController,
    required this.passwordController,
    required this.debugCode,
    required this.requestingCode,
    required this.submitting,
    required this.onChanged,
    required this.onRequestCode,
    required this.onLoginTap,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
    required this.acceptedLegal,
    required this.onAcceptedLegalChanged,
    required this.onSubmit,
  });

  final TextEditingController phoneController;
  final TextEditingController codeController;
  final TextEditingController passwordController;
  final String? debugCode;
  final bool requestingCode;
  final bool submitting;
  final VoidCallback onChanged;
  final VoidCallback? onRequestCode;
  final VoidCallback onLoginTap;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;
  final bool acceptedLegal;
  final ValueChanged<bool> onAcceptedLegalChanged;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return _AuthFrame(
      topBar: const _TopBar(),
      form: _SoftPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PanelTitle(title: '新用户注册', subtitle: '用手机号创建账号，开始听故事'),
            SizedBox(height: 10.h),
            _ModernInput(
              label: '手机号',
              hint: '输入手机号',
              icon: Icons.person_outline_rounded,
              controller: phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              onChanged: onChanged,
            ),
            SizedBox(height: 8.h),
            _CodeInputRow(
              controller: codeController,
              requesting: requestingCode,
              onChanged: onChanged,
              onRequestCode: onRequestCode,
            ),
            SizedBox(height: 8.h),
            _ModernInput(
              label: '设置密码',
              hint: '至少 6 位密码',
              icon: Icons.lock_outline_rounded,
              controller: passwordController,
              obscureText: true,
              onChanged: onChanged,
            ),
            if (debugCode != null) ...[
              SizedBox(height: 7.h),
              _DebugCodeBadge(code: debugCode!),
            ],
            SizedBox(height: 10.h),
            _GradientButton(
              label: '立即注册',
              loading: submitting,
              onPressed: onSubmit,
            ),
            SizedBox(height: 6.h),
            _LegalConsentText(
              accepted: acceptedLegal,
              onAcceptedChanged: onAcceptedLegalChanged,
              onOpenTerms: onOpenTerms,
              onOpenPrivacy: onOpenPrivacy,
            ),
            SizedBox(height: 2.h),
            _TextSwitchButton(label: '已有账号？立即登录', onPressed: onLoginTap),
          ],
        ),
      ),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView({
    required this.phoneController,
    required this.codeController,
    required this.passwordController,
    required this.method,
    required this.debugCode,
    required this.requestingCode,
    required this.submitting,
    required this.onChanged,
    required this.onRequestCode,
    required this.onSwitchMethod,
    required this.onRegisterTap,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
    required this.acceptedLegal,
    required this.onAcceptedLegalChanged,
    required this.onSubmit,
  });

  final TextEditingController phoneController;
  final TextEditingController codeController;
  final TextEditingController passwordController;
  final _LoginMethod method;
  final String? debugCode;
  final bool requestingCode;
  final bool submitting;
  final VoidCallback onChanged;
  final VoidCallback? onRequestCode;
  final ValueChanged<_LoginMethod> onSwitchMethod;
  final VoidCallback onRegisterTap;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;
  final bool acceptedLegal;
  final ValueChanged<bool> onAcceptedLegalChanged;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final isSms = method == _LoginMethod.sms;
    return _AuthFrame(
      topBar: const _TopBar(),
      form: _SoftPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PanelTitle(title: '登录', subtitle: '继续收藏、创作和听故事'),
            SizedBox(height: 10.h),
            _ModernInput(
              label: '手机号',
              hint: '输入手机号',
              icon: Icons.person_outline_rounded,
              controller: phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              onChanged: onChanged,
            ),
            SizedBox(height: 8.h),
            if (isSms)
              _CodeInputRow(
                controller: codeController,
                requesting: requestingCode,
                onChanged: onChanged,
                onRequestCode: onRequestCode,
              )
            else
              _ModernInput(
                label: '密码',
                hint: '输入密码',
                icon: Icons.lock_outline_rounded,
                controller: passwordController,
                obscureText: true,
                onChanged: onChanged,
              ),
            if (isSms && debugCode != null) ...[
              SizedBox(height: 7.h),
              _DebugCodeBadge(code: debugCode!),
            ],
            SizedBox(height: 10.h),
            _GradientButton(
              label: '登录',
              loading: submitting,
              onPressed: onSubmit,
            ),
            SizedBox(height: 6.h),
            _LegalConsentText(
              accepted: acceptedLegal,
              onAcceptedChanged: onAcceptedLegalChanged,
              onOpenTerms: onOpenTerms,
              onOpenPrivacy: onOpenPrivacy,
            ),
            SizedBox(height: 2.h),
            _TextSwitchButton(label: '新用户注册', onPressed: onRegisterTap),
          ],
        ),
      ),
      footer: _OtherLoginMethods(
        method: method,
        onSwitchMethod: onSwitchMethod,
      ),
    );
  }
}

class _AuthFrame extends StatelessWidget {
  const _AuthFrame({required this.topBar, required this.form, this.footer});

  final Widget topBar;
  final Widget form;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.fromLTRB(22.w, 16.h, 22.w, 20.h),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 420.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      topBar,
                      SizedBox(height: 20.h),
                      form,
                      if (footer != null) ...[SizedBox(height: 22.h), footer!],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FloatingMascot(size: 88.r),
        SizedBox(height: 14.h),
        Text(
          '乐鱼故事',
          style: TextStyle(
            color: AppTheme.navy,
            fontSize: 28.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppTheme.lemon,
            borderRadius: BorderRadius.circular(99.r),
          ),
          child: Text(
            '给小朋友的 AI 故事乐园',
            style: TextStyle(
              color: AppTheme.navy,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SoftPanel extends StatelessWidget {
  const _SoftPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StickerCard(
      padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 12.h),
      child: child,
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.navy,
            fontSize: 24.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.navyMuted,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 6.h),
      ],
    );
  }
}

class _ModernInput extends StatelessWidget {
  const _ModernInput({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          onChanged: (_) => onChanged(),
          style: _fieldTextStyle(),
          decoration: _fieldDecoration(hint: hint, icon: icon),
        ),
      ],
    );
  }
}

class _CodeInputRow extends StatelessWidget {
  const _CodeInputRow({
    required this.controller,
    required this.requesting,
    required this.onChanged,
    required this.onRequestCode,
  });

  final TextEditingController controller;
  final bool requesting;
  final VoidCallback onChanged;
  final VoidCallback? onRequestCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('手机验证码'),
        SizedBox(height: 6.h),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (_) => onChanged(),
                style: _fieldTextStyle(),
                decoration: _fieldDecoration(
                  hint: '验证码',
                  icon: Icons.verified_outlined,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            SizedBox(
              width: 112.w,
              child: CandyButton(
                label: '获取验证码',
                onPressed: onRequestCode,
                loading: requesting,
                color: AppTheme.lemon,
                foregroundColor: AppTheme.navy,
                disabledColor: const Color(0xFFE6EEF6),
                height: 50.h,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.navy,
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

TextStyle _fieldTextStyle() => TextStyle(
  fontSize: 17.sp,
  color: AppTheme.navy,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.5,
);

InputDecoration _fieldDecoration({
  required String hint,
  required IconData icon,
}) {
  final radius = BorderRadius.circular(25.r);
  return InputDecoration(
    isDense: true,
    hintText: hint,
    hintStyle: TextStyle(
      color: const Color(0xFF8D9AB5),
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
    ),
    prefixIcon: Icon(icon, color: AppTheme.skyBlue, size: 22.sp),
    prefixIconConstraints: BoxConstraints(minWidth: 46.w, minHeight: 50.h),
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
    border: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppTheme.fieldStroke, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppTheme.fieldStroke, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppTheme.candyPink, width: 2.5),
    ),
  );
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CandyButton(
      label: label,
      loading: loading,
      onPressed: onPressed,
      height: 56.h,
      fontSize: 18.sp,
    );
  }
}

class _TextSwitchButton extends StatelessWidget {
  const _TextSwitchButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.skyDeep,
          fontSize: 15.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LegalConsentText extends StatelessWidget {
  const _LegalConsentText({
    required this.accepted,
    required this.onAcceptedChanged,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
  });

  final bool accepted;
  final ValueChanged<bool> onAcceptedChanged;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      color: AppTheme.navyMuted,
      fontSize: 12.sp,
      fontWeight: FontWeight.w500,
      height: 1.35,
    );
    final linkStyle = baseStyle.copyWith(
      color: AppTheme.candyPink,
      fontWeight: FontWeight.w800,
      decoration: TextDecoration.underline,
      decorationColor: AppTheme.candyPink,
    );

    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 26.w,
            height: 26.w,
            child: Checkbox(
              value: accepted,
              onChanged: (value) => onAcceptedChanged(value ?? false),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('我已阅读并同意', style: baseStyle),
                _InlineLegalButton(
                  label: '用户协议',
                  style: linkStyle,
                  onPressed: onOpenTerms,
                ),
                Text('和', style: baseStyle),
                _InlineLegalButton(
                  label: '隐私政策',
                  style: linkStyle,
                  onPressed: onOpenPrivacy,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineLegalButton extends StatelessWidget {
  const _InlineLegalButton({
    required this.label,
    required this.style,
    required this.onPressed,
  });

  final String label;
  final TextStyle style;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
      ),
      child: Text(label, style: style),
    );
  }
}

class _DebugCodeBadge extends StatelessWidget {
  const _DebugCodeBadge({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: CandyChip(
        text: '调试验证码 $code',
        color: AppTheme.lemonSoft,
        icon: Icons.bug_report_outlined,
      ),
    );
  }
}

class _OtherLoginMethods extends StatelessWidget {
  const _OtherLoginMethods({
    required this.method,
    required this.onSwitchMethod,
  });

  final _LoginMethod method;
  final ValueChanged<_LoginMethod> onSwitchMethod;

  @override
  Widget build(BuildContext context) {
    final alternative = method == _LoginMethod.sms
        ? _LoginMethod.password
        : _LoginMethod.sms;
    final option = alternative == _LoginMethod.password
        ? const _LoginMethodOption(
            method: _LoginMethod.password,
            label: '密码',
            icon: Icons.lock_outline_rounded,
            color: AppTheme.grape,
          )
        : const _LoginMethodOption(
            method: _LoginMethod.sms,
            label: '短信',
            icon: Icons.sms_outlined,
            color: AppTheme.skyBlue,
          );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(color: AppTheme.navy.withValues(alpha: 0.15)),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Text(
                '其他方式登录',
                style: TextStyle(
                  color: AppTheme.navyMuted,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: AppTheme.navy.withValues(alpha: 0.15)),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LoginMethodBubble(
              option: option,
              onTap: () => onSwitchMethod(option.method),
            ),
          ],
        ),
      ],
    );
  }
}

class _LoginMethodOption {
  const _LoginMethodOption({
    required this.method,
    required this.label,
    required this.icon,
    required this.color,
  });

  final _LoginMethod method;
  final String label;
  final IconData icon;
  final Color color;
}

class _LoginMethodBubble extends StatelessWidget {
  const _LoginMethodBubble({required this.option, required this.onTap});

  final _LoginMethodOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '切换到${option.label}登录',
      excludeSemantics: true,
      child: Column(
        children: [
          CandyIconButton(
            icon: option.icon,
            tooltip: '${option.label}登录',
            onTap: onTap,
            color: option.color,
            iconColor: Colors.white,
            size: 54.r,
          ),
          SizedBox(height: 6.h),
          Text(
            '${option.label}登录',
            style: TextStyle(
              color: AppTheme.navy,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
