import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/utils/story_presenter.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/joyfish_scaffold.dart';
import '../../../core/config/app_config.dart';
import '../models/story_models.dart';
import '../repository/story_repository.dart';

@RoutePage()
class StoryDetailPage extends StatefulWidget {
  const StoryDetailPage({
    super.key,
    @PathParam('storyId') required this.storyId,
  });

  final int storyId;

  @override
  State<StoryDetailPage> createState() => _StoryDetailPageState();
}

class _StoryDetailPageState extends State<StoryDetailPage> {
  final AudioPlayer _player = AudioPlayer();
  late Future<StoryRecord> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadStory();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<StoryRecord> _loadStory() async {
    final story = await StoryRepository().getStory(widget.storyId);
    final audioUrl = AppConfig.instance.resolveMediaUrl(story.audioUrl);
    if (audioUrl != null) {
      await _player.setUrl(audioUrl);
    }
    return story;
  }

  @override
  Widget build(BuildContext context) {
    return JoyfishScaffold(
      child: FutureBuilder<StoryRecord>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
                child: Text('故事加载失败: ${snapshot.error ?? 'unknown'}'));
          }

          final story = snapshot.data!;
          final visual = storyVisualOf(story);
          final totalDuration =
              _player.duration ?? Duration(minutes: story.readingMinutes ?? 8);

          return Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.18,
                  child: GridPaper(
                    color: AppTheme.purpleLight,
                    interval: 22.w,
                    divisions: 1,
                    subdivisions: 1,
                  ),
                ),
              ),
              ListView(
                padding: EdgeInsets.fromLTRB(26.w, 10.h, 26.w, 40.h),
                children: [
                  _StoryTopBar(onBack: () => context.router.maybePop()),
                  SizedBox(height: 26.h),
                  Container(
                    height: 220.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30.r),
                      border: Border.all(color: Colors.white, width: 5),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x33716B5D),
                            blurRadius: 0,
                            offset: Offset(5, 8)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24.r),
                      child: _DetailCover(visual: visual),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => Container(
                        width: index == 0 ? 14.w : 10.w,
                        height: index == 0 ? 14.w : 10.w,
                        margin: EdgeInsets.symmetric(horizontal: 7.w),
                        decoration: BoxDecoration(
                          color: index == 0
                              ? AppTheme.peach
                              : const Color(0xFFD8D0BD),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 26.h),
                  Text(
                    story.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(color: AppTheme.skyDeep),
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28.r),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x33716B5D),
                            blurRadius: 0,
                            offset: Offset(4, 6)),
                      ],
                    ),
                    child: Text(
                      story.summary?.isNotEmpty == true
                          ? story.summary!
                          : _firstParagraph(story.bodyMd),
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(height: 1.7),
                    ),
                  ),
                  SizedBox(height: 30.h),
                  Text(
                    '选一个好听的声音吧',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppTheme.olive),
                  ),
                  SizedBox(height: 18.h),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 0.86,
                    crossAxisSpacing: 22.w,
                    mainAxisSpacing: 22.h,
                    children: const [
                      _VoiceCard(
                          icon: Icons.man_rounded,
                          label: '爸爸的声音',
                          selected: false),
                      _VoiceCard(
                          icon: Icons.woman_rounded,
                          label: '妈妈的声音',
                          selected: true),
                      _VoiceCard(
                          icon: Icons.smart_toy_rounded,
                          label: '小机器人',
                          selected: false),
                      _VoiceCard(
                          icon: Icons.auto_fix_high_rounded,
                          label: '仙女姐姐',
                          selected: false),
                    ],
                  ),
                  SizedBox(height: 28.h),
                  StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data?.playing ?? false;
                      return AppButton(
                        text: isPlaying ? '暂停故事' : '开始讲故事',
                        height: 68.h,
                        backgroundColor: AppTheme.peach,
                        textColor: AppTheme.olive,
                        borderSide:
                            const BorderSide(color: AppTheme.olive, width: 2.4),
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_circle_outline_rounded
                              : Icons.play_circle_outline_rounded,
                          color: AppTheme.olive,
                        ),
                        onPressed: () async {
                          if (isPlaying) {
                            await _player.pause();
                          } else {
                            await _player.play();
                          }
                        },
                      );
                    },
                  ),
                  SizedBox(height: 20.h),
                  StreamBuilder<Duration>(
                    stream: _player.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final totalMs = totalDuration.inMilliseconds == 0
                          ? 1
                          : totalDuration.inMilliseconds;
                      return Column(
                        children: [
                          LinearProgressIndicator(
                            minHeight: 10.h,
                            value:
                                (position.inMilliseconds / totalMs).clamp(0, 1),
                            backgroundColor: const Color(0xFFE3EAF0),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.skyDeep),
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Text(_formatDuration(position),
                                  style: Theme.of(context).textTheme.bodySmall),
                              const Spacer(),
                              Text(_formatDuration(totalDuration),
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 26.h),
                  Container(
                    padding: EdgeInsets.all(22.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: MarkdownBody(
                      data: story.bodyMd,
                      styleSheet: MarkdownStyleSheet(
                        p: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(height: 1.7),
                        h1: Theme.of(context).textTheme.headlineLarge,
                        h2: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _firstParagraph(String body) {
    final text = body
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .join(' ');
    if (text.length <= 92) return text;
    return '${text.substring(0, 92)}...';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _StoryTopBar extends StatelessWidget {
  const _StoryTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: const Color(0xFF11C4E6),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33716B5D), blurRadius: 0, offset: Offset(0, 7)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25.r,
            backgroundColor: Colors.white,
            child: IconButton(
              onPressed: onBack,
              icon: Icon(Icons.arrow_back_rounded,
                  color: AppTheme.skyDeep, size: 24.sp),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              'Story Paradise',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 21.sp,
                  fontWeight: FontWeight.w900),
            ),
          ),
          Icon(Icons.home_rounded, color: Colors.white, size: 28.sp),
        ],
      ),
    );
  }
}

class _DetailCover extends StatelessWidget {
  const _DetailCover({required this.visual});

  final StoryVisual visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            visual.color.withValues(alpha: 0.95),
            const Color(0xFF092B34)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(visual.emoji, style: TextStyle(fontSize: 96.sp)),
      ),
    );
  }
}

class _VoiceCard extends StatelessWidget {
  const _VoiceCard({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: selected ? AppTheme.leaf : Colors.white,
          width: selected ? 4 : 1,
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33716B5D), blurRadius: 0, offset: Offset(4, 6)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 42.r,
            backgroundColor: selected ? AppTheme.leaf : const Color(0xFFD8E9FF),
            child: Icon(icon,
                color: selected ? const Color(0xFF2F7D00) : AppTheme.skyDeep,
                size: 38.sp),
          ),
          SizedBox(height: 24.h),
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
