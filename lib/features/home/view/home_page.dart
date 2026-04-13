import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/widgets/app_button.dart';
import '../../children/providers/child_providers.dart';
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
    final selectedChild = ref.watch(selectedChildProvider);
    final voiceState = ref.watch(voiceControllerProvider);
    final recentStories = ref.watch(recentStoriesProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await ref.read(childControllerProvider.notifier).loadChildren(force: true);
          await ref.read(voiceControllerProvider.notifier).loadVoices(force: true);
          await ref.read(storyLibraryControllerProvider.notifier).loadStories(force: true);
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
          children: [
            Text('晚上好', style: Theme.of(context).textTheme.bodyLarge),
            SizedBox(height: 6.h),
            Text('今天想给孩子讲什么故事？', style: Theme.of(context).textTheme.displaySmall),
            SizedBox(height: 18.h),
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE0F5FF), Color(0xFFFFF5DA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('快速发起故事', style: Theme.of(context).textTheme.headlineMedium),
                        SizedBox(height: 10.h),
                        Text(
                          '选择孩子、套用家长音色，3 步开始生成今晚的专属故事。',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.mutedInk,
                              ),
                        ),
                        SizedBox(height: 16.h),
                        AppButton.primary(
                          text: '开始创作',
                          width: 144.w,
                          onPressed: onCreateStory,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  SizedBox(
                    width: 92.w,
                    height: 92.w,
                    child: SvgPicture.asset('assets/images/home_hero.svg'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 18.h),
            _SectionCard(
              title: '当前孩子',
              actionLabel: selectedChild == null ? '创建' : '切换',
              onAction: onManageChildren,
              child: selectedChild == null
                  ? Text(
                      '还没有孩子档案。先创建一个，故事会根据孩子场景生成。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(selectedChild.nickname, style: Theme.of(context).textTheme.headlineMedium),
                        SizedBox(height: 6.h),
                        Text(
                          selectedChild.birthdate == null
                              ? '未填写生日信息'
                              : '生日 ${selectedChild.birthdate}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.mutedInk,
                              ),
                        ),
                        if (selectedChild.gender != null) SizedBox(height: 4.h),
                        if (selectedChild.gender != null)
                          Text(
                            '性别 ${selectedChild.gender}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.mutedInk,
                                ),
                          ),
                      ],
                    ),
            ),
            SizedBox(height: 14.h),
            _SectionCard(
              title: '家长音色',
              actionLabel: voiceState.items.isEmpty ? '去录制' : '管理',
              onAction: onManageVoice,
              child: voiceState.items.isEmpty
                  ? Text(
                      '还没有录制音色。录入爸爸或妈妈的声音后，故事音频会更有陪伴感。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  : Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: voiceState.items
                          .map(
                            (item) => Chip(
                              label: Text(item.displayName ?? item.role),
                              avatar: Icon(
                                item.role == 'dad' ? Icons.face_5_rounded : Icons.favorite_rounded,
                                color: AppTheme.coral,
                              ),
                              backgroundColor: const Color(0xFFFFF4E0),
                              side: BorderSide.none,
                            ),
                          )
                          .toList(),
                    ),
            ),
            SizedBox(height: 14.h),
            _SectionCard(
              title: '最近故事',
              actionLabel: recentStories.isEmpty ? '去创作' : '查看全部',
              onAction: recentStories.isEmpty ? onCreateStory : () {},
              child: recentStories.isEmpty
                  ? Text(
                      '故事库还空着。先生成第一篇，让首页热闹起来。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  : Column(
                      children: recentStories
                          .map(
                            (story) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFEAF5FF),
                                child: const Icon(Icons.auto_stories_rounded, color: AppTheme.skyDeep),
                              ),
                              title: Text(story.title),
                              subtitle: Text(story.summary ?? '点击查看完整故事'),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => onOpenStory(story.id),
                            ),
                          )
                          .toList(),
                    ),
            ),
            SizedBox(height: 14.h),
            if (childrenState.error != null || voiceState.error != null)
              Text(
                childrenState.error ?? voiceState.error ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(18.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
                ),
                TextButton(onPressed: onAction, child: Text(actionLabel)),
              ],
            ),
            SizedBox(height: 6.h),
            child,
          ],
        ),
      ),
    );
  }
}
