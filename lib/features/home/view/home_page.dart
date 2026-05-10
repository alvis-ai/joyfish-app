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
              mainAxisExtent: 268.h,
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
    final visual = item is StoryRecord
        ? storyVisualOf(item as StoryRecord)
        : (item as _DemoStory).visual;

    return JoyfishStoryCard(
      visual: visual,
      title: title,
      meta: meta,
      badge: visual.subtitle,
      onTap: onTap,
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

class _DemoStory {
  const _DemoStory(this.title, this.meta, this.visual);

  final String title;
  final String meta;
  final StoryVisual visual;
}

const _demoStories = [
  _DemoStory(
    '魔法森林',
    '24 页 · 冒险',
    StoryVisual(emoji: '🌳', color: Color(0xFF18D67C), subtitle: '魔法森林'),
  ),
  _DemoStory(
    '勇敢的小星星',
    '12 页 · 睡前故事',
    StoryVisual(emoji: '⭐', color: Color(0xFFA075F5), subtitle: '睡前故事'),
  ),
  _DemoStory(
    '海洋探险记',
    '18 页 · 教育',
    StoryVisual(emoji: '🌊', color: Color(0xFF19BCE1), subtitle: '海底世界'),
  ),
  _DemoStory(
    '机器人伙伴',
    '30 页 · 未来',
    StoryVisual(emoji: '🤖', color: Color(0xFFFF9B67), subtitle: '未来伙伴'),
  ),
];
