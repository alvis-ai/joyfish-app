// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [AuthPage]
class AuthRoute extends PageRouteInfo<void> {
  const AuthRoute({List<PageRouteInfo>? children})
      : super(
          AuthRoute.name,
          initialChildren: children,
        );

  static const String name = 'AuthRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AuthPage();
    },
  );
}

/// generated route for
/// [ChildProfilePage]
class ChildProfileRoute extends PageRouteInfo<void> {
  const ChildProfileRoute({List<PageRouteInfo>? children})
      : super(
          ChildProfileRoute.name,
          initialChildren: children,
        );

  static const String name = 'ChildProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ChildProfilePage();
    },
  );
}

/// generated route for
/// [MainShellPage]
class MainShellRoute extends PageRouteInfo<void> {
  const MainShellRoute({List<PageRouteInfo>? children})
      : super(
          MainShellRoute.name,
          initialChildren: children,
        );

  static const String name = 'MainShellRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MainShellPage();
    },
  );
}

/// generated route for
/// [SplashPage]
class SplashRoute extends PageRouteInfo<void> {
  const SplashRoute({List<PageRouteInfo>? children})
      : super(
          SplashRoute.name,
          initialChildren: children,
        );

  static const String name = 'SplashRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SplashPage();
    },
  );
}

/// generated route for
/// [StoryComposerPage]
class StoryComposerRoute extends PageRouteInfo<void> {
  const StoryComposerRoute({List<PageRouteInfo>? children})
      : super(
          StoryComposerRoute.name,
          initialChildren: children,
        );

  static const String name = 'StoryComposerRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const StoryComposerPage();
    },
  );
}

/// generated route for
/// [StoryDetailPage]
class StoryDetailRoute extends PageRouteInfo<StoryDetailRouteArgs> {
  StoryDetailRoute({
    Key? key,
    required int storyId,
    List<PageRouteInfo>? children,
  }) : super(
          StoryDetailRoute.name,
          args: StoryDetailRouteArgs(
            key: key,
            storyId: storyId,
          ),
          rawPathParams: {'storyId': storyId},
          initialChildren: children,
        );

  static const String name = 'StoryDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<StoryDetailRouteArgs>(
          orElse: () =>
              StoryDetailRouteArgs(storyId: pathParams.getInt('storyId')));
      return StoryDetailPage(
        key: args.key,
        storyId: args.storyId,
      );
    },
  );
}

class StoryDetailRouteArgs {
  const StoryDetailRouteArgs({
    this.key,
    required this.storyId,
  });

  final Key? key;

  final int storyId;

  @override
  String toString() {
    return 'StoryDetailRouteArgs{key: $key, storyId: $storyId}';
  }
}

/// generated route for
/// [StoryGeneratingPage]
class StoryGeneratingRoute extends PageRouteInfo<StoryGeneratingRouteArgs> {
  StoryGeneratingRoute({
    Key? key,
    required int requestId,
    List<PageRouteInfo>? children,
  }) : super(
          StoryGeneratingRoute.name,
          args: StoryGeneratingRouteArgs(
            key: key,
            requestId: requestId,
          ),
          rawPathParams: {'requestId': requestId},
          initialChildren: children,
        );

  static const String name = 'StoryGeneratingRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<StoryGeneratingRouteArgs>(
          orElse: () => StoryGeneratingRouteArgs(
              requestId: pathParams.getInt('requestId')));
      return StoryGeneratingPage(
        key: args.key,
        requestId: args.requestId,
      );
    },
  );
}

class StoryGeneratingRouteArgs {
  const StoryGeneratingRouteArgs({
    this.key,
    required this.requestId,
  });

  final Key? key;

  final int requestId;

  @override
  String toString() {
    return 'StoryGeneratingRouteArgs{key: $key, requestId: $requestId}';
  }
}

/// generated route for
/// [VoiceStudioPage]
class VoiceStudioRoute extends PageRouteInfo<void> {
  const VoiceStudioRoute({List<PageRouteInfo>? children})
      : super(
          VoiceStudioRoute.name,
          initialChildren: children,
        );

  static const String name = 'VoiceStudioRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const VoiceStudioPage();
    },
  );
}
