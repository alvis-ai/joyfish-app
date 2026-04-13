import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/utils/story_presenter.dart';
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
            return Center(child: Text('故事加载失败: ${snapshot.error ?? 'unknown'}'));
          }

          final story = snapshot.data!;
          final visual = storyVisualOf(story);
          final totalDuration = _player.duration ?? Duration(minutes: story.readingMinutes ?? 8);

          return ListView(
            padding: EdgeInsets.fromLTRB(24.w, 22.h, 24.w, 36.h),
            children: [
              TextButton.icon(
                onPressed: () => context.router.maybePop(),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.zero,
                  foregroundColor: AppTheme.purple,
                ),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('返回'),
              ),
              SizedBox(height: 50.h),
              Center(
                child: Container(
                  width: 196.w,
                  height: 196.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: visual.color,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x28D6A9A7),
                        blurRadius: 28,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Text(visual.emoji, style: TextStyle(fontSize: 84.sp)),
                ),
              ),
              SizedBox(height: 26.h),
              Text(
                story.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppTheme.ink),
              ),
              SizedBox(height: 10.h),
              Text(
                visual.subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.mutedInk,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              SizedBox(height: 34.h),
              StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final totalMs = totalDuration.inMilliseconds == 0 ? 1 : totalDuration.inMilliseconds;
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20.r),
                        child: LinearProgressIndicator(
                          minHeight: 10.h,
                          value: (position.inMilliseconds / totalMs).clamp(0, 1),
                          backgroundColor: const Color(0xFFE3EAF0),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.purpleLight),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Text(
                            _formatDuration(position),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: const Color(0xFF72778A),
                                ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDuration(totalDuration),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: const Color(0xFF72778A),
                                ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 30.h),
              StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data?.playing ?? false;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CircleActionButton(
                        icon: Icons.skip_previous_rounded,
                        onTap: () => _player.seek(Duration.zero),
                      ),
                      SizedBox(width: 28.w),
                      _CircleActionButton(
                        icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        filled: true,
                        onTap: () async {
                          if (isPlaying) {
                            await _player.pause();
                          } else {
                            await _player.play();
                          }
                        },
                      ),
                      SizedBox(width: 28.w),
                      _CircleActionButton(
                        icon: Icons.skip_next_rounded,
                        onTap: () async {
                          final current = _player.position;
                          await _player.seek(current + const Duration(seconds: 15));
                        },
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 40.h),
              JoyfishCard(
                child: MarkdownBody(
                  data: story.bodyMd,
                  styleSheet: MarkdownStyleSheet(
                    p: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7),
                    h1: Theme.of(context).textTheme.headlineLarge,
                    h2: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100.r),
        child: Container(
          width: filled ? 92.w : 72.w,
          height: filled ? 92.w : 72.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: filled
                ? const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFFFB400)])
                : null,
            color: filled ? null : Colors.white.withValues(alpha: 0.92),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1FD4A3A3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: filled ? Colors.white : AppTheme.purple,
            size: filled ? 42.sp : 34.sp,
          ),
        ),
      ),
    );
  }
}
