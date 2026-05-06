import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/widgets/app_button.dart';
import '../../children/providers/child_providers.dart';
import '../../story/models/story_models.dart';
import '../../story/providers/story_providers.dart';
import '../../voice/providers/voice_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({
    super.key,
    required this.onManageChildren,
    required this.onManageVoice,
    required this.onCreateStory,
    required this.onOpenStory,
  });

  final VoidCallback onManageChildren;
  final VoidCallback onManageVoice;
  final VoidCallback onCreateStory;
  final ValueChanged<int> onOpenStory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenState = ref.watch(childControllerProvider);
    final voiceState = ref.watch(voiceControllerProvider);
    final stories = ref.watch(storyLibraryControllerProvider).items;
    final shelfItems =
        stories.isEmpty ? _demoStories : stories.take(4).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(childControllerProvider.notifier)
            .loadChildren(force: true);
        await ref
            .read(voiceControllerProvider.notifier)
            .loadVoices(force: true);
        await ref
            .read(storyLibraryControllerProvider.notifier)
            .loadStories(force: true);
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(28.w, 0, 28.w, 132.h),
        children: [
          SizedBox(height: 14.h),
          const _HomeHeader(),
          SizedBox(height: 26.h),
          _SectionTitle(
            title: '精选故事',
            action: '查看全部',
            onAction: stories.isEmpty ? null : () {},
          ),
          SizedBox(height: 14.h),
          _FeaturedStoryCard(
            story: stories.isEmpty ? null : stories.first,
            onTap: stories.isEmpty
                ? onCreateStory
                : () => onOpenStory(stories.first.id),
          ),
          SizedBox(height: 30.h),
          const _PlainTitle('我的书架'),
          SizedBox(height: 14.h),
          GridView.builder(
            itemCount: shelfItems.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 22.w,
              mainAxisSpacing: 24.h,
              mainAxisExtent: 236.h,
            ),
            itemBuilder: (context, index) {
              final item = shelfItems[index];
              return _ShelfCard(
                item: item,
                onTap: item is StoryRecord
                    ? () => onOpenStory(item.id)
                    : onCreateStory,
              );
            },
          ),
          SizedBox(height: 28.h),
          _VipBanner(onTap: onCreateStory),
          SizedBox(height: 16.h),
          if (childrenState.error != null || voiceState.error != null)
            Text(
              childrenState.error ?? voiceState.error ?? '',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.red),
            ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84.h,
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      decoration: BoxDecoration(
        color: AppTheme.purpleLight,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33716B5D), blurRadius: 0, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          _RoundIcon(icon: Icons.home_rounded),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              '乐鱼故事',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _RoundIcon(icon: Icons.search_rounded),
          SizedBox(width: 12.w),
          SizedBox(
            width: 46.w,
            height: 46.w,
            child: Image.asset(
              'assets/images/joyfish_logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.28),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 26.sp),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child:
                Text(title, style: Theme.of(context).textTheme.headlineMedium)),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child:
                Text(action!, style: const TextStyle(color: AppTheme.skyDeep)),
          ),
      ],
    );
  }
}

class _PlainTitle extends StatelessWidget {
  const _PlainTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.headlineMedium);
  }
}

class _FeaturedStoryCard extends StatelessWidget {
  const _FeaturedStoryCard({required this.story, required this.onTap});

  final StoryRecord? story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = story?.title ?? '勇敢的小狗大冒险';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 248.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32.r),
          border: Border.all(color: Colors.white, width: 5),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33716B5D), blurRadius: 0, offset: Offset(6, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _IllustrationBackdrop(kind: _StoryKind.forest),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xAA302900)],
                  ),
                ),
              ),
              Positioned(
                left: 18.w,
                bottom: 18.h,
                right: 18.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text('今日推荐',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: Colors.white,
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShelfCard extends StatelessWidget {
  const _ShelfCard({required this.item, required this.onTap});

  final Object item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = item is StoryRecord
        ? (item as StoryRecord).title
        : (item as _DemoStory).title;
    final meta = item is StoryRecord
        ? '${(item as StoryRecord).readingMinutes ?? 8} 页 · 故事'
        : (item as _DemoStory).meta;
    final kind = item is StoryRecord
        ? _kindForTitle((item as StoryRecord).title)
        : (item as _DemoStory).kind;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28.r),
                border: Border.all(color: Colors.white, width: 5),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x33716B5D),
                      blurRadius: 0,
                      offset: Offset(5, 7)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22.r),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _IllustrationBackdrop(kind: kind),
                    Positioned(
                      right: 10.w,
                      bottom: 10.h,
                      child: CircleAvatar(
                        radius: 22.r,
                        backgroundColor: const Color(0xFF2F7D00),
                        child: Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 22.sp),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 4.h),
          Text(meta,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppTheme.mutedInk)),
        ],
      ),
    );
  }
}

class _VipBanner extends StatelessWidget {
  const _VipBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: AppTheme.peach,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33716B5D), blurRadius: 0, offset: Offset(5, 7)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('解锁 1000+ 故事',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: AppTheme.olive)),
                SizedBox(height: 8.h),
                Text('加入 VIP 会员，开启无限想象空间',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppTheme.olive)),
                SizedBox(height: 16.h),
                SizedBox(
                  width: 132.w,
                  child: AppButton(
                    text: '立即升级',
                    height: 48.h,
                    backgroundColor: AppTheme.olive,
                    textColor: Colors.white,
                    onPressed: onTap,
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 44.r,
            backgroundColor: const Color(0x66705E00),
            child: Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 42.sp),
          ),
        ],
      ),
    );
  }
}

enum _StoryKind { forest, star, ocean, future }

class _IllustrationBackdrop extends StatelessWidget {
  const _IllustrationBackdrop({required this.kind});

  final _StoryKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = switch (kind) {
      _StoryKind.forest => const [Color(0xFF102B2B), Color(0xFF315E35)],
      _StoryKind.star => const [Color(0xFF121A44), Color(0xFF614C99)],
      _StoryKind.ocean => const [Color(0xFF05B4CF), Color(0xFF035C83)],
      _StoryKind.future => const [Color(0xFFFFD39B), Color(0xFF75D8FF)],
    };
    final icon = switch (kind) {
      _StoryKind.forest => Icons.forest_rounded,
      _StoryKind.star => Icons.star_rounded,
      _StoryKind.ocean => Icons.water_rounded,
      _StoryKind.future => Icons.rocket_launch_rounded,
    };

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -24.w,
            top: -16.h,
            child: Icon(Icons.eco_rounded,
                size: 88.sp, color: Colors.white.withValues(alpha: 0.09)),
          ),
          Positioned(
            right: -12.w,
            bottom: -10.h,
            child: Icon(icon,
                size: 96.sp, color: Colors.white.withValues(alpha: 0.22)),
          ),
          Center(
            child: Icon(icon,
                size: 76.sp, color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}

_StoryKind _kindForTitle(String title) {
  if (title.contains('海')) return _StoryKind.ocean;
  if (title.contains('星') || title.contains('太空')) return _StoryKind.star;
  if (title.contains('机器') || title.contains('未来')) return _StoryKind.future;
  return _StoryKind.forest;
}

class _DemoStory {
  const _DemoStory(this.title, this.meta, this.kind);

  final String title;
  final String meta;
  final _StoryKind kind;
}

const _demoStories = [
  _DemoStory('魔法森林', '24 页 · 冒险', _StoryKind.forest),
  _DemoStory('勇敢的小星星', '12 页 · 睡前故事', _StoryKind.star),
  _DemoStory('海洋探险记', '18 页 · 教育', _StoryKind.ocean),
  _DemoStory('机器人伙伴', '30 页 · 未来', _StoryKind.future),
];
