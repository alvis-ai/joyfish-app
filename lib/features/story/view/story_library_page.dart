import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/utils/story_presenter.dart';
import '../../../common/widgets/joyfish_scaffold.dart';
import '../models/story_models.dart';
import '../providers/story_providers.dart';

class StoryLibraryPage extends ConsumerStatefulWidget {
  const StoryLibraryPage({
    super.key,
    required this.onCompose,
    required this.onOpenStory,
  });

  final VoidCallback onCompose;
  final ValueChanged<int> onOpenStory;

  @override
  ConsumerState<StoryLibraryPage> createState() => _StoryLibraryPageState();
}

class _StoryLibraryPageState extends ConsumerState<StoryLibraryPage> {
  final Set<int> _likedIds = <int>{};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyLibraryControllerProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(storyLibraryControllerProvider.notifier).loadStories(force: true),
      child: ListView(
        padding: EdgeInsets.fromLTRB(26.w, 22.h, 26.w, 140.h),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('我的故事', style: Theme.of(context).textTheme.displayMedium),
                    SizedBox(height: 8.h),
                    Text(
                      '${state.items.length} 个精彩故事',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppTheme.mutedInk,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
                padding: EdgeInsets.all(6.w),
                child: SvgPicture.asset('assets/images/home_hero.svg'),
              ),
            ],
          ),
          SizedBox(height: 26.h),
          if (state.items.isEmpty)
            JoyfishCard(
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  SvgPicture.asset('assets/images/empty_library.svg', height: 140.h),
                  SizedBox(height: 18.h),
                  Text('还没有故事', style: Theme.of(context).textTheme.headlineLarge),
                  SizedBox(height: 8.h),
                  Text(
                    '先去创作一篇新故事，乐鱼会把它收进专属故事书里。',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mutedInk,
                        ),
                  ),
                  SizedBox(height: 18.h),
                  SizedBox(
                    width: 180.w,
                    child: FilledButton(
                      onPressed: widget.onCompose,
                      child: const Text('去创作'),
                    ),
                  ),
                ],
              ),
            )
          else
            ...state.items.map((story) => Padding(
                  padding: EdgeInsets.only(bottom: 18.h),
                  child: _StoryCard(
                    story: story,
                    liked: _likedIds.contains(story.id),
                    onToggleLike: () {
                      setState(() {
                        if (!_likedIds.remove(story.id)) {
                          _likedIds.add(story.id);
                        }
                      });
                    },
                    onTap: () => widget.onOpenStory(story.id),
                  ),
                )),
          if (state.error != null) ...[
            SizedBox(height: 12.h),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.story,
    required this.liked,
    required this.onToggleLike,
    required this.onTap,
  });

  final StoryRecord story;
  final bool liked;
  final VoidCallback onToggleLike;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = storyVisualOf(story);
    final created = story.publishedAt ?? story.createdAt;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30.r),
        child: JoyfishCard(
          child: Row(
            children: [
              Container(
                width: 92.w,
                height: 92.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: visual.color,
                  borderRadius: BorderRadius.circular(22.r),
                ),
                child: Text(visual.emoji, style: TextStyle(fontSize: 38.sp)),
              ),
              SizedBox(width: 18.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            story.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: onToggleLike,
                          splashRadius: 18.r,
                          icon: Icon(
                            liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: liked ? const Color(0xFFFF4D4D) : const Color(0xFFD3D8E5),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      visual.subtitle,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppTheme.mutedInk,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 18.sp, color: const Color(0xFF807B80)),
                        SizedBox(width: 4.w),
                        Text(
                          storyDurationLabel(story),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: const Color(0xFF807B80),
                              ),
                        ),
                        SizedBox(width: 20.w),
                        Text(
                          storyDayLabel(created),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: const Color(0xFF807B80),
                              ),
                        ),
                      ],
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
