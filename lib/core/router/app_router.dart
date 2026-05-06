import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import '../../features/auth/view/auth_page.dart';
import '../../features/children/view/child_profile_page.dart';
import '../../features/main/view/main_shell_page.dart';
import '../../features/splash/view/splash_page.dart';
import '../../features/story/view/story_composer_page.dart';
import '../../features/story/view/story_detail_page.dart';
import '../../features/story/view/story_generating_page.dart';
import '../../features/voice/view/voice_studio_page.dart';
import '../storage/storage_manager.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  final AuthGuard _authGuard = AuthGuard();

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: SplashRoute.page),
        AutoRoute(page: AuthRoute.page, initial: true),
        AutoRoute(page: MainShellRoute.page, guards: [_authGuard]),
        AutoRoute(page: ChildProfileRoute.page, guards: [_authGuard]),
        AutoRoute(page: VoiceStudioRoute.page, guards: [_authGuard]),
        AutoRoute(page: StoryComposerRoute.page, guards: [_authGuard]),
        AutoRoute(page: StoryGeneratingRoute.page, guards: [_authGuard]),
        AutoRoute(page: StoryDetailRoute.page, guards: [_authGuard]),
      ];
}

class AuthGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    final isLoggedIn = await StorageManager.isLoggedIn();
    if (isLoggedIn) {
      resolver.next(true);
      return;
    }
    resolver.redirect(const AuthRoute());
  }
}
