import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyfish_app/core/network/api_envelope.dart';
import 'package:joyfish_app/features/auth/view/auth_page.dart';

void main() {
  test('ApiEnvelope parses backend payload', () {
    final envelope = ApiEnvelope<String>.fromJson(
      {
        'code': '00000',
        'message': 'success',
        'data': 'hello',
      },
      (data) => data as String,
    );

    expect(envelope.isSuccess, isTrue);
    expect(envelope.data, 'hello');
  });

  testWidgets('Auth page renders core actions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          builder: (context, child) {
            return const MaterialApp(home: AuthPage());
          },
        ),
      ),
    );

    expect(find.text('乐鱼故事'), findsOneWidget);
    expect(find.text('新用户注册'), findsOneWidget);
    expect(find.text('获取验证码'), findsOneWidget);
    expect(find.text('立即注册'), findsOneWidget);
    expect(find.text('已有账号？立即登录'), findsOneWidget);
  });

  testWidgets('Login page uses sms code first', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          builder: (context, child) {
            return const MaterialApp(home: AuthPage());
          },
        ),
      ),
    );

    await tester.ensureVisible(find.text('已有账号？立即登录'));
    await tester.tap(find.text('已有账号？立即登录'));
    await tester.pumpAndSettle();

    expect(find.text('手机验证码快速进入故事世界'), findsOneWidget);
    expect(find.text('手机验证码'), findsOneWidget);
    expect(find.text('获取验证码'), findsOneWidget);
    expect(find.text('密码'), findsNothing);
  });
}
