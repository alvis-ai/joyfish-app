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
      HomePage(
        onManageChildren: () => context.router.push(const ChildProfileRoute()),
        onManageVoice: () => context.router.push(const VoiceStudioRoute()),
        onCreateStory: () => setState(() => _currentIndex = 1),
        onOpenStory: (storyId) =>
            context.router.push(StoryDetailRoute(storyId: storyId)),
      ),
      const StoryComposerPage(embedded: true),
      StoryLibraryPage(
        onCompose: () => setState(() => _currentIndex = 1),
        onOpenStory: (storyId) =>
            context.router.push(StoryDetailRoute(storyId: storyId)),
      ),
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
      margin: EdgeInsets.fromLTRB(18.w, 0, 18.w, 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: const Color(0xFFE5E0D4), width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33716B5D),
            blurRadius: 0,
            offset: Offset(0, 7),
          ),
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
          child: Row(
            children: [
              _NavItem(
                label: 'HOME',
                icon: Icons.menu_book_outlined,
                activeIcon: Icons.menu_book_rounded,
                active: currentIndex == 0,
                onTap: () => onChanged(0),
              ),
              _NavItem(
                label: 'CREATE',
                icon: Icons.auto_awesome_outlined,
                activeIcon: Icons.auto_awesome_rounded,
                active: currentIndex == 1,
                onTap: () => onChanged(1),
              ),
              _NavItem(
                label: 'LIBRARY',
                icon: Icons.library_books_outlined,
                activeIcon: Icons.library_books_rounded,
                active: currentIndex == 2,
                onTap: () => onChanged(2),
              ),
              _NavItem(
                label: 'VIP',
                icon: Icons.stars_outlined,
                activeIcon: Icons.stars_rounded,
                active: currentIndex == 3,
                onTap: () => onChanged(3),
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
    final color = active ? Colors.white : AppTheme.purpleLight;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: active ? 68.h : 54.h,
            decoration: BoxDecoration(
              color: active ? AppTheme.skyDeep : Colors.transparent,
              borderRadius: BorderRadius.circular(18.r),
              border: active ? Border.all(color: Colors.white, width: 3) : null,
              boxShadow: active
                  ? const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(active ? activeIcon : icon, color: color, size: 25.sp),
                SizedBox(height: 4.h),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
