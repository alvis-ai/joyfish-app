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
    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.text('我已阅读并同意'), findsOneWidget);
    expect(find.text('用户协议'), findsOneWidget);
    expect(find.text('隐私政策'), findsOneWidget);
    expect(find.textContaining('继续即表示你'), findsNothing);
    expect(find.text('已有账号？立即登录'), findsOneWidget);
  });

  testWidgets('Register button requires legal consent', (tester) async {
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

    await tester.enterText(find.byType(TextField).at(0), '13800138000');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.enterText(find.byType(TextField).at(2), 'secret1');
    await tester.pump();

    var registerButton =
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, '立即注册'));
    expect(registerButton.onPressed, isNull);

    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    registerButton =
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, '立即注册'));
    expect(registerButton.onPressed, isNotNull);
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

    expect(find.text('继续上次的奇幻阅读冒险'), findsOneWidget);
    expect(find.text('回到故事书架'), findsOneWidget);
    expect(find.text('手机验证码'), findsOneWidget);
    expect(find.text('获取验证码'), findsOneWidget);
    expect(find.text('其他方式登录'), findsOneWidget);
    expect(find.text('用户协议'), findsOneWidget);
    expect(find.text('隐私政策'), findsOneWidget);
    expect(find.text('密码'), findsNothing);
  });
}
