import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/utils/story_presenter.dart';
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
    final stories = state.items;
    final used = stories.length.clamp(0, 6);

    return RefreshIndicator(
      onRefresh: () => ref
          .read(storyLibraryControllerProvider.notifier)
          .loadStories(force: true),
      child: ListView(
        padding: EdgeInsets.fromLTRB(28.w, 0, 28.w, 132.h),
        children: [
          SizedBox(height: 14.h),
          const _LibraryTopBar(),
          SizedBox(height: 28.h),
          _ProgressCard(used: used, onCreate: onCompose),
          SizedBox(height: 28.h),
          Row(
            children: [
              CircleAvatar(
                radius: 38.r,
                backgroundColor: AppTheme.leaf,
                child: Icon(Icons.library_books_rounded,
                    color: AppTheme.olive, size: 34.sp),
              ),
              SizedBox(width: 16.w),
              Text('我的故事屋', style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
          SizedBox(height: 24.h),
          if (stories.isEmpty)
            _EmptyLibrary(onCreate: onCompose)
          else
            ...stories.map(
              (story) => Padding(
                padding: EdgeInsets.only(bottom: 28.h),
                child: _LibraryStoryCard(
                  story: story,
                  onTap: () => onOpenStory(story.id),
                ),
              ),
            ),
          if (state.error != null) ...[
            SizedBox(height: 12.h),
            Text(
              state.error!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }
}

class _LibraryTopBar extends StatelessWidget {
  const _LibraryTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92.h,
      padding: EdgeInsets.symmetric(horizontal: 26.w),
      decoration: BoxDecoration(
        color: AppTheme.purpleLight,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.r)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33716B5D), blurRadius: 0, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34.r,
            backgroundColor: Colors.white.withValues(alpha: 0.28),
            child:
                Icon(Icons.home_rounded, color: AppTheme.skyDeep, size: 30.sp),
          ),
          SizedBox(width: 22.w),
          Expanded(
            child: Text('Story Paradise',
                style: Theme.of(context).textTheme.displaySmall),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.used, required this.onCreate});

  final int used;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final remaining = 6 - used;
    return GestureDetector(
      onTap: onCreate,
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: AppTheme.peach,
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33716B5D), blurRadius: 0, offset: Offset(5, 7)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    color: AppTheme.olive, size: 28.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text('本月故事进度',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: AppTheme.olive)),
                ),
                Text('$used / 6',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: AppTheme.olive)),
              ],
            ),
            SizedBox(height: 18.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(99.r),
              child: LinearProgressIndicator(
                minHeight: 16.h,
                value: used / 6,
                backgroundColor: Colors.white,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.skyDeep),
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              '你还可以创作 $remaining 个新故事！',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: AppTheme.olive),
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
              color: Color(0x33716B5D), blurRadius: 0, offset: Offset(5, 7)),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.menu_book_rounded, color: AppTheme.skyDeep, size: 76.sp),
          SizedBox(height: 14.h),
          Text('还没有故事', style: Theme.of(context).textTheme.headlineLarge),
          SizedBox(height: 8.h),
          Text('先生成第一篇，故事屋会马上热闹起来。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge),
          SizedBox(height: 18.h),
          FilledButton(onPressed: onCreate, child: const Text('去创作')),
        ],
      ),
    );
  }
}

class _LibraryStoryCard extends StatelessWidget {
  const _LibraryStoryCard({required this.story, required this.onTap});

  final StoryRecord story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = storyVisualOf(story);
    final created = story.publishedAt ?? story.createdAt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: Colors.white, width: 5),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33716B5D), blurRadius: 0, offset: Offset(5, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 214.h,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                child: _StoryCover(visual: visual),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 22.h, 24.w, 22.h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(story.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineMedium),
                        SizedBox(height: 18.h),
                        Text(storyDayLabel(created),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(color: AppTheme.mutedInk)),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 27.r,
                    backgroundColor: AppTheme.skyDeep,
                    child: Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 30.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryCover extends StatelessWidget {
  const _StoryCover({required this.visual});

  final StoryVisual visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            visual.color.withValues(alpha: 0.95),
            const Color(0xFF12333A)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.16,
              child: GridPaper(
                color: Colors.white,
                divisions: 2,
                interval: 36.w,
                subdivisions: 1,
              ),
            ),
          ),
          Center(child: Text(visual.emoji, style: TextStyle(fontSize: 84.sp))),
          Positioned(
            left: 18.w,
            top: 18.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppTheme.skyDeep,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Text(visual.subtitle,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}
