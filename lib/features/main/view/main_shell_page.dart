import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(
        18.w,
        0,
        18.w,
        bottomInset > 0 ? 8.h : 12.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: const Color(0xFFF0EBF8), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x160F172A),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
        child: Row(
          children: [
            _NavItem(
              label: '首页',
              icon: Icons.menu_book_outlined,
              activeIcon: Icons.menu_book_rounded,
              active: currentIndex == 0,
              onTap: () => onChanged(0),
            ),
            _NavItem(
              label: '创作',
              icon: Icons.auto_awesome_outlined,
              activeIcon: Icons.auto_awesome_rounded,
              active: currentIndex == 1,
              onTap: () => onChanged(1),
            ),
            _NavItem(
              label: '书架',
              icon: Icons.library_books_outlined,
              activeIcon: Icons.library_books_rounded,
              active: currentIndex == 2,
              onTap: () => onChanged(2),
            ),
            _NavItem(
              label: '我的',
              icon: Icons.stars_outlined,
              activeIcon: Icons.person_rounded,
              active: currentIndex == 3,
              onTap: () => onChanged(3),
            ),
          ],
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
    final color = active ? Colors.white : const Color(0xFF8792A8);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: active ? 62.h : 50.h,
            decoration: BoxDecoration(
              gradient: active
                  ? const LinearGradient(
                      colors: [Color(0xFF7357F6), Color(0xFF5B7CF6)],
                    )
                  : null,
              color: active ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(17.r),
              border:
                  active ? Border.all(color: Colors.white, width: 2.5) : null,
              boxShadow: active
                  ? const [
                      BoxShadow(
                        color: Color(0x257357F6),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(active ? activeIcon : icon, color: color, size: 24.sp),
                SizedBox(height: 3.h),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                    color: color,
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
