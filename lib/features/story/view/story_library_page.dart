import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/utils/story_presenter.dart';
import '../../../common/widgets/joyfish_scaffold.dart';
import '../../../common/widgets/story_cards.dart';
import '../../../core/config/app_config.dart';
import '../../auth/providers/session_providers.dart';
import '../models/story_models.dart';
import '../providers/story_providers.dart';

class StoryLibraryPage extends ConsumerWidget {
  const StoryLibraryPage({
    super.key,
    required this.onCompose,
    required this.onOpenStory,
  });

  final VoidCallback onCompose;
  final ValueChanged<int> onOpenStory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storyLibraryControllerProvider);
    final user = ref.watch(sessionControllerProvider).user;
    final creationCount = ref.watch(monthlyStoryCreationCountProvider);
    final stories = state.items;
    final monthlyLimit = user?.hasActiveMembership == true ? 60 : 6;
    final used = creationCount.maybeWhen(
      data: (count) => count.clamp(0, monthlyLimit).toInt(),
      orElse: () => stories.length.clamp(0, monthlyLimit).toInt(),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(monthlyStoryCreationCountProvider);
        await ref
            .read(storyLibraryControllerProvider.notifier)
            .loadStories(force: true);
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(28.w, 0, 28.w, 132.h),
        children: [
          SizedBox(height: 14.h),
          JoyfishPageHeader(
            title: '故事书架',
            subtitle: '收藏和回看每一个好故事',
            trailing: JoyfishIconBubble(
              icon: Icons.add_rounded,
              onTap: onCompose,
            ),
          ),
          SizedBox(height: 28.h),
          _ProgressCard(used: used, limit: monthlyLimit, onCreate: onCompose),
          SizedBox(height: 28.h),
          Row(
            children: [
              CircleAvatar(
                radius: 38.r,
                backgroundColor: AppTheme.leaf,
                child: Icon(
                  Icons.library_books_rounded,
                  color: AppTheme.olive,
                  size: 34.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Text('我的故事屋', style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
          SizedBox(height: 24.h),
          if (stories.isEmpty)
            _EmptyLibrary(onCreate: onCompose)
          else
            GridView.builder(
              itemCount: stories.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 22.w,
                mainAxisSpacing: 24.h,
                mainAxisExtent: 342.h,
              ),
              itemBuilder: (context, index) {
                final story = stories[index];
                return _LibraryStoryCard(
                  story: story,
                  onTap: () => onOpenStory(story.id),
                  onDelete: () => _handleDeleteStory(
                    context,
                    ref,
                    story,
                    canDelete: user?.hasActiveMembership == true,
                  ),
                );
              },
            ),
          if (state.error != null) ...[
            SizedBox(height: 12.h),
            Text(
              state.error!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleDeleteStory(
    BuildContext context,
    WidgetRef ref,
    StoryRecord story, {
    required bool canDelete,
  }) async {
    if (!canDelete) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('会员专属功能'),
          content: const Text('开通会员后可以删除书架里的故事。删除不会返还本月创作额度。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这个故事？'),
        content: Text('《${story.title}》删除后不能恢复，也不会返还或减少已创建故事的整体数量。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final deleted = await ref
        .read(storyLibraryControllerProvider.notifier)
        .deleteStory(story.id);
    if (!context.mounted) {
      return;
    }

    final message = deleted
        ? '故事已删除，已创建故事数量不受影响'
        : ref.read(storyLibraryControllerProvider).error ?? '删除失败，请稍后重试';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.used,
    required this.limit,
    required this.onCreate,
  });

  final int used;
  final int limit;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final remaining = (limit - used).clamp(0, limit).toInt();
    return GestureDetector(
      onTap: onCreate,
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFD45A), Color(0xFFFFBE54)],
          ),
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 24,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: AppTheme.olive,
                  size: 28.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    '本月故事进度',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: AppTheme.olive),
                  ),
                ),
                Text(
                  '$used / $limit',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: AppTheme.olive),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(99.r),
              child: LinearProgressIndicator(
                minHeight: 16.h,
                value: limit == 0 ? 0 : used / limit,
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.skyDeep,
                ),
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              '你还可以创作 $remaining 个新故事！',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppTheme.olive),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(28.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: const Color(0xFFD8D0BD), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33716B5D),
            blurRadius: 0,
            offset: Offset(5, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.menu_book_rounded, color: AppTheme.skyDeep, size: 76.sp),
          SizedBox(height: 14.h),
          Text('还没有故事', style: Theme.of(context).textTheme.headlineLarge),
          SizedBox(height: 8.h),
          Text(
            '先生成第一篇，故事屋会马上热闹起来。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 18.h),
          FilledButton(onPressed: onCreate, child: const Text('去创作')),
        ],
      ),
    );
  }
}

class _LibraryStoryCard extends StatelessWidget {
  const _LibraryStoryCard({
    required this.story,
    required this.onTap,
    required this.onDelete,
  });

  final StoryRecord story;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final visual = storyVisualOf(story);
    final created = story.publishedAt ?? story.createdAt;
    return JoyfishStoryCard(
      visual: visual,
      title: story.title,
      meta: storyDayLabel(created),
      badge: visual.subtitle,
      imageUrl: AppConfig.instance.resolveMediaUrl(story.coverImageUrl),
      onTap: onTap,
      onDelete: onDelete,
    );
  }
}
