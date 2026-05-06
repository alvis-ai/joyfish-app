import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'common/themes/app_theme.dart';
import 'core/network/auth_session_bus.dart';
import 'core/router/app_router.dart';
import 'features/auth/providers/session_providers.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  late final AppRouter _appRouter;
  StreamSubscription<AuthSessionEvent>? _authSubscription;

  @override
  void initState() {
    super.initState();
    debugPrint('JOYFISH App.initState()');
    _appRouter = AppRouter();
    _authSubscription = AuthSessionBus.stream.listen((event) async {
      await ref.read(sessionControllerProvider.notifier).handleSessionExpired();
      _appRouter.replaceAll([const AuthRoute()]);
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('JOYFISH App.build()');
    return MaterialApp.router(
      title: '乐鱼故事',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: _appRouter.config(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
