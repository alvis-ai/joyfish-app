import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/widgets/joyfish_scaffold.dart';
import '../../../core/router/app_router.dart';
import '../../children/providers/child_providers.dart';
import '../../home/view/home_page.dart';
import '../../profile/view/profile_page.dart';
import '../../story/providers/story_providers.dart';
import '../../story/view/story_composer_page.dart';
import '../../story/view/story_library_page.dart';
import '../../voice/providers/voice_providers.dart';

enum _MainPanel { library, composer, membership }

@RoutePage()
class MainShellPage extends ConsumerStatefulWidget {
  const MainShellPage({super.key});

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends ConsumerState<MainShellPage> {
  _MainPanel? _panel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(childControllerProvider.notifier).loadChildren();
      ref.read(voiceControllerProvider.notifier).loadVoices();
      ref.read(storyLibraryControllerProvider.notifier).loadStories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return JoyfishScaffold(
      child: Stack(
        children: [
          HomePage(
            onManageChildren: () =>
                context.router.push(const ChildProfileRoute()),
            onManageVoice: () => context.router.push(const VoiceStudioRoute()),
            onCreateStory: () => _openPanel(_MainPanel.composer),
            onOpenLibrary: () => _openPanel(_MainPanel.library),
            onOpenStory: (storyId) =>
                context.router.push(StoryDetailRoute(storyId: storyId)),
          ),
          Positioned(
            left: 22.r,
            right: 22.r,
            top: 10.h,
            child: _FloatingDock(
              onOpenLibrary: () => _openPanel(_MainPanel.library),
              onCreateStory: () => _openPanel(_MainPanel.composer),
              onOpenMembership: () => _openPanel(_MainPanel.membership),
              onOpenProfile: () =>
                  context.router.push(const ChildProfileRoute()),
            ),
          ),
          if (_panel != null)
            _WarmPanelOverlay(
              panel: _panel!,
              onClose: () => setState(() => _panel = null),
              onCompose: () => _openPanel(_MainPanel.composer),
              onOpenStory: (storyId) {
                setState(() => _panel = null);
                context.router.push(StoryDetailRoute(storyId: storyId));
              },
              onManageChildren: () =>
                  context.router.push(const ChildProfileRoute()),
              onManageVoice: () =>
                  context.router.push(const VoiceStudioRoute()),
            ),
        ],
      ),
    );
  }

  void _openPanel(_MainPanel panel) {
    setState(() => _panel = panel);
  }
}

class _FloatingDock extends StatelessWidget {
  const _FloatingDock({
    required this.onOpenLibrary,
    required this.onCreateStory,
    required this.onOpenMembership,
    required this.onOpenProfile,
  });

  final VoidCallback onOpenLibrary;
  final VoidCallback onCreateStory;
  final VoidCallback onOpenMembership;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DockButton(
          tooltip: '个人设置',
          icon: Icons.child_care_rounded,
          onTap: onOpenProfile,
        ),
        const Spacer(),
        _DockCluster(
          children: [
            _DockButton(
              tooltip: '故事书架',
              icon: Icons.auto_stories_rounded,
              onTap: onOpenLibrary,
              compact: true,
            ),
            _DockButton(
              tooltip: '会员中心',
              icon: Icons.workspace_premium_rounded,
              onTap: onOpenMembership,
              compact: true,
            ),
            _DockButton(
              tooltip: '创作故事',
              icon: Icons.auto_awesome_rounded,
              onTap: onCreateStory,
              compact: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _DockCluster extends StatelessWidget {
  const _DockCluster({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6.r, vertical: 6.r),
          decoration: BoxDecoration(
            color: AppTheme.olive.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 1,
            ),
          ),
          child: Row(children: children),
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 42.r : 46.r;
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 2.r : 0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(99.r),
            child: Ink(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EC).withValues(alpha: 0.86),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F5D3F1D),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: AppTheme.olive, size: 22.sp),
            ),
          ),
        ),
      ),
    );
  }
}

class _WarmPanelOverlay extends StatelessWidget {
  const _WarmPanelOverlay({
    required this.panel,
    required this.onClose,
    required this.onCompose,
    required this.onOpenStory,
    required this.onManageChildren,
    required this.onManageVoice,
  });

  final _MainPanel panel;
  final VoidCallback onClose;
  final VoidCallback onCompose;
  final ValueChanged<int> onOpenStory;
  final VoidCallback onManageChildren;
  final VoidCallback onManageVoice;

  @override
  Widget build(BuildContext context) {
    final title = switch (panel) {
      _MainPanel.library => '书架',
      _MainPanel.composer => '想听什么故事？',
      _MainPanel.membership => '会员中心',
    };
    final child = switch (panel) {
      _MainPanel.library => StoryLibraryPage(
        sheetMode: true,
        onCompose: onCompose,
        onOpenStory: onOpenStory,
      ),
      _MainPanel.composer => const StoryComposerPage(embedded: true),
      _MainPanel.membership => ProfilePage(
        sheetMode: true,
        onManageChildren: onManageChildren,
        onManageVoice: onManageVoice,
      ),
    };

    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(color: AppTheme.ink.withValues(alpha: 0.16)),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 74.h, 14.w, 12.h),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6E6).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(34.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.48),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x245D3F1D),
                      blurRadius: 30,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(14.w, 12.h, 18.w, 4.h),
                      child: Row(
                        children: [
                          _DockButton(
                            tooltip: '关闭',
                            icon: Icons.close_rounded,
                            onTap: onClose,
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(color: AppTheme.olive),
                              ),
                            ),
                          ),
                          SizedBox(width: 46.r),
                        ],
                      ),
                    ),
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
