import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/joyfish_scaffold.dart';
import '../../../common/widgets/story_cards.dart';
import '../../../common/utils/story_presenter.dart';
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
    required this.onOpenLibrary,
    required this.onOpenStory,
  });

  final VoidCallback onManageChildren;
  final VoidCallback onManageVoice;
  final VoidCallback onCreateStory;
  final VoidCallback onOpenLibrary;
  final ValueChanged<int> onOpenStory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenState = ref.watch(childControllerProvider);
    final voiceState = ref.watch(voiceControllerProvider);
    final stories = ref.watch(storyLibraryControllerProvider).items;
    final shelfStories = stories.take(4).toList();

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
          JoyfishPageHeader(
            title: '故事首页',
            subtitle: '给小朋友的 AI 故事乐园',
            trailing: JoyfishIconBubble(
              icon: Icons.auto_awesome_rounded,
              onTap: onCreateStory,
            ),
          ),
          SizedBox(height: 26.h),
          _SectionTitle(
            title: '精选故事',
            action: '查看全部',
            onAction: stories.isEmpty ? null : onOpenLibrary,
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
          if (shelfStories.isEmpty)
            _EmptyShelfCard(onCreateStory: onCreateStory)
          else
            GridView.builder(
              itemCount: shelfStories.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 22.w,
                mainAxisSpacing: 24.h,
                mainAxisExtent: 268.h,
              ),
              itemBuilder: (context, index) {
                final story = shelfStories[index];
                return _ShelfCard(
                  story: story,
                  onTap: () => onOpenStory(story.id),
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
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF2D3446),
                ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              action!,
              style: TextStyle(
                color: const Color(0xFF7357F6),
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
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
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: const Color(0xFF2D3446),
          ),
    );
  }
}

class _FeaturedStoryCard extends StatelessWidget {
  const _FeaturedStoryCard({required this.story, required this.onTap});

  final StoryRecord? story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const fallback = StoryVisual(
      emoji: '🐶',
      color: Color(0xFF2B8A64),
      subtitle: '冒险故事',
    );
    return JoyfishFeaturedStoryCard(
      visual: story == null ? fallback : storyVisualOf(story!),
      title: story?.title ?? '勇敢的小狗大冒险',
      label: '今日推荐',
      onTap: onTap,
    );
  }
}

class _ShelfCard extends StatelessWidget {
  const _ShelfCard({required this.story, required this.onTap});

  final StoryRecord story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = storyVisualOf(story);

    return JoyfishStoryCard(
      visual: visual,
      title: story.title,
      meta: '${story.readingMinutes ?? 8} 页 · 故事',
      badge: visual.subtitle,
      onTap: onTap,
    );
  }
}

class _EmptyShelfCard extends StatelessWidget {
  const _EmptyShelfCard({required this.onCreateStory});

  final VoidCallback onCreateStory;

  @override
  Widget build(BuildContext context) {
    return JoyfishCard(
      padding: EdgeInsets.all(22.w),
      radius: 28.r,
      child: Row(
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD45A), Color(0xFFFF8C9E)],
              ),
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 30.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '还没有收藏故事',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF2D3446),
                      ),
                ),
                SizedBox(height: 6.h),
                Text(
                  '创作第一个故事后，会自动出现在这里。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF78839A),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          TextButton(
            onPressed: onCreateStory,
            child: Text(
              '去创作',
              style: TextStyle(
                color: const Color(0xFF7357F6),
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD45A), Color(0xFFFFB950)],
        ),
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
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
            backgroundColor: const Color(0x4D705E00),
            child: Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 42.sp),
          ),
        ],
      ),
    );
  }
}
