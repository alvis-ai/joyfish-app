import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/widgets/joyfish_scaffold.dart';
import '../../../core/router/app_router.dart';
import '../../children/providers/child_providers.dart';
import '../../profile/view/profile_page.dart';
import '../../story/providers/story_providers.dart';
import '../../story/view/story_composer_page.dart';
import '../../story/view/story_library_page.dart';
import '../../voice/providers/voice_providers.dart';

@RoutePage()
class MainShellPage extends ConsumerStatefulWidget {
  const MainShellPage({super.key});

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends ConsumerState<MainShellPage> {
  int _currentIndex = 0;

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
    final pages = [
      StoryLibraryPage(
        onCompose: () => setState(() => _currentIndex = 1),
        onOpenStory: (storyId) => context.router.push(StoryDetailRoute(storyId: storyId)),
      ),
      const StoryComposerPage(embedded: true),
      ProfilePage(
        onManageChildren: () => context.router.push(const ChildProfileRoute()),
        onManageVoice: () => context.router.push(const VoiceStudioRoute()),
      ),
    ];

    return JoyfishScaffold(
      bottomNavigationBar: _JoyfishBottomNav(
        currentIndex: _currentIndex,
        onChanged: (value) => setState(() => _currentIndex = value),
      ),
      child: IndexedStack(index: _currentIndex, children: pages),
    );
  }
}

class _JoyfishBottomNav extends StatelessWidget {
  const _JoyfishBottomNav({
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        border: const Border(top: BorderSide(color: Color(0x11A1A5B5))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 12.h),
          child: Row(
            children: [
              _NavItem(
                label: '首页',
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                active: currentIndex == 0,
                onTap: () => onChanged(0),
              ),
              _NavItem(
                label: '创作',
                icon: Icons.add_circle_outline_rounded,
                activeIcon: Icons.add_circle_rounded,
                active: currentIndex == 1,
                onTap: () => onChanged(1),
              ),
              _NavItem(
                label: '我的',
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                active: currentIndex == 2,
                onTap: () => onChanged(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.purpleLight : AppTheme.mutedInk;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? activeIcon : icon, color: color, size: 28.sp),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
              SizedBox(height: 4.h),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: active ? 6.w : 0,
                height: 6.h,
                decoration: const BoxDecoration(
                  color: AppTheme.purpleLight,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
