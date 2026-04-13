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
    expect(find.text('手机号登录'), findsWidgets);
    expect(find.text('获取验证码'), findsOneWidget);
  });
}
