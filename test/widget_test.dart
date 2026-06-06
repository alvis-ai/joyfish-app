import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyfish_app/core/config/app_config.dart';
import 'package:joyfish_app/core/network/api_envelope.dart';
import 'package:joyfish_app/features/auth/models/auth_models.dart';
import 'package:joyfish_app/features/auth/providers/session_providers.dart';
import 'package:joyfish_app/features/auth/view/auth_page.dart';
import 'package:joyfish_app/features/children/models/child_profile.dart';
import 'package:joyfish_app/features/children/providers/child_providers.dart';
import 'package:joyfish_app/features/home/view/home_page.dart';
import 'package:joyfish_app/features/main/view/main_shell_page.dart';
import 'package:joyfish_app/features/story/models/story_models.dart';
import 'package:joyfish_app/features/story/providers/story_providers.dart';
import 'package:joyfish_app/features/story/view/story_composer_page.dart';
import 'package:joyfish_app/features/voice/providers/voice_providers.dart';

void main() {
  setUpAll(() async {
    await AppConfig.init();
  });

  test('ApiEnvelope parses backend payload', () {
    final envelope = ApiEnvelope<String>.fromJson({
      'code': '00000',
      'message': 'success',
      'data': 'hello',
    }, (data) => data as String);

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

    var registerButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '立即注册'),
    );
    expect(registerButton.onPressed, isNull);

    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    registerButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '立即注册'),
    );
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

    expect(find.text('登录'), findsWidgets);
    expect(find.text('继续收藏、创作和听故事'), findsOneWidget);
    expect(find.text('手机验证码'), findsOneWidget);
    expect(find.text('获取验证码'), findsOneWidget);
    expect(find.text('其他方式登录'), findsOneWidget);
    expect(find.text('用户协议'), findsOneWidget);
    expect(find.text('隐私政策'), findsOneWidget);
    expect(find.text('密码'), findsNothing);
  });

  testWidgets('Immersive home renders empty story state', (tester) async {
    await _configurePhoneSurface(tester);
    await tester.pumpWidget(
      _testApp(
        overrides: _storyOverrides(),
        child: HomePage(
          onManageChildren: () {},
          onManageVoice: () {},
          onCreateStory: () {},
          onOpenLibrary: () {},
          onOpenStory: (_) {},
        ),
      ),
    );

    expect(find.textContaining('今晚还没有故事'), findsOneWidget);
    expect(find.text('开启故事'), findsOneWidget);
    expect(find.text('乐鱼故事'), findsOneWidget);
    expect(find.text('故事工具箱'), findsNothing);
  });

  testWidgets('Immersive home renders current story player', (tester) async {
    await _configurePhoneSurface(tester);
    var openedStoryCount = 0;
    await tester.pumpWidget(
      _testApp(
        overrides: _storyOverrides(stories: [_sampleStory]),
        child: HomePage(
          onManageChildren: () {},
          onManageVoice: () {},
          onCreateStory: () {},
          onOpenLibrary: () {},
          onOpenStory: (_) => openedStoryCount++,
        ),
      ),
    );

    expect(find.text('橙果轻铃'), findsWidgets);
    expect(find.byType(AspectRatio), findsNothing);
    expect(find.text('查看故事'), findsOneWidget);
    expect(find.text('阅读'), findsOneWidget);
    expect(find.textContaining('约 8 分钟'), findsOneWidget);
    expect(find.text('正在书桌上'), findsNothing);
    expect(find.text('故事工具箱'), findsNothing);
    expect(find.byIcon(Icons.repeat_rounded), findsNothing);
    expect(openedStoryCount, 0);
  });

  testWidgets('Story composer exposes template choices', (tester) async {
    await _configurePhoneSurface(tester);
    await tester.pumpWidget(
      _testApp(
        overrides: _storyOverrides(children: [_sampleChild]),
        child: const StoryComposerPage(embedded: true),
      ),
    );

    expect(find.text('你想听什么故事？'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('魔法森林'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('魔法森林'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('小狐狸'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('小狐狸'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('友谊互助'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('友谊互助'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('开启故事'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('开启故事'), findsOneWidget);
  });

  testWidgets('Main shell opens library overlay', (tester) async {
    await _configurePhoneSurface(tester);
    await tester.pumpWidget(
      _testApp(
        overrides: _storyOverrides(stories: [_sampleStory]),
        child: const MainShellPage(),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.auto_stories_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('书架'), findsWidgets);
    expect(find.text('故事书架'), findsOneWidget);
    expect(find.text('本月故事进度'), findsOneWidget);
  });
}

Future<void> _configurePhoneSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(375, 812));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget _testApp({required Widget child, List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, _) {
        return MaterialApp(home: Scaffold(body: child));
      },
    ),
  );
}

List<Override> _storyOverrides({
  List<StoryRecord> stories = const [],
  List<ChildProfile> children = const [],
}) {
  return [
    storyLibraryControllerProvider.overrideWith(
      (ref) => _TestStoryLibraryController(ref, stories),
    ),
    childControllerProvider.overrideWith(
      (ref) => _TestChildController(ref, children),
    ),
    voiceControllerProvider.overrideWith((ref) => _TestVoiceController(ref)),
    sessionControllerProvider.overrideWith(
      (ref) => _TestSessionController(ref),
    ),
    monthlyStoryCreationCountProvider.overrideWith(
      (ref) async => stories.length,
    ),
  ];
}

class _TestStoryLibraryController extends StoryLibraryController {
  _TestStoryLibraryController(super.ref, List<StoryRecord> stories) {
    state = StoryLibraryState(loaded: true, items: stories);
  }

  @override
  Future<void> loadStories({bool force = false}) async {}
}

class _TestChildController extends ChildController {
  _TestChildController(super.ref, List<ChildProfile> children) {
    state = ChildrenState(
      loaded: true,
      items: children,
      selectedChildId: children.isEmpty ? null : children.first.id,
    );
  }

  @override
  Future<void> loadChildren({bool force = false}) async {}
}

class _TestVoiceController extends VoiceController {
  _TestVoiceController(super.ref) {
    state = const VoiceState(loaded: true);
  }

  @override
  Future<void> loadVoices({bool force = false}) async {}
}

class _TestSessionController extends SessionController {
  _TestSessionController(super.ref) {
    state = const SessionState(
      initialized: true,
      user: AuthUser(
        id: 1,
        email: null,
        phoneNumber: '13800138000',
        provider: 'password',
        providerUid: null,
        locale: 'zh-CN',
        timezone: 'Asia/Shanghai',
        createdAt: null,
      ),
    );
  }
}

const _sampleChild = ChildProfile(
  id: 1,
  userId: 1,
  nickname: '均均',
  birthdate: '2023-01-01',
  gender: 'female',
  preferences: null,
  createdAt: null,
);

final _sampleStory = StoryRecord(
  id: 7,
  requestId: 3,
  title: '橙果轻铃',
  summary: '晚风裹着树叶的清香，吹过古老的森林。',
  language: 'zh',
  readingMinutes: 8,
  ageRange: '3-6 岁',
  bodyMd: '晚风裹着树叶的清香，吹过古老的森林。',
  coverImageUrl: null,
  audioUrl: null,
  visibility: 'private',
  createdAt: DateTime(2026, 5, 30),
  publishedAt: DateTime(2026, 5, 30),
);
