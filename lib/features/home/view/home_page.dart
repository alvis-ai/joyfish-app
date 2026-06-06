import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/utils/story_presenter.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/joyfish_cached_image.dart';
import '../../../common/widgets/joyfish_scaffold.dart';
import '../../../core/config/app_config.dart';
import '../../story/models/story_models.dart';
import '../../story/providers/story_providers.dart';
import '../../story/service/story_audio_cache.dart';

class HomePage extends ConsumerStatefulWidget {
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
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final AudioPlayer _player = AudioPlayer();
  final StoryAudioCache _audioCache = const StoryAudioCache();
  StreamSubscription<PlayerState>? _playerStateSubscription;
  int? _preparedStoryId;
  bool _audioLoading = false;
  bool _audioReady = false;
  String? _audioError;

  @override
  void initState() {
    super.initState();
    _playerStateSubscription = _player.playerStateStream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyLibraryControllerProvider);
    final story = state.items.isEmpty ? null : state.items.first;
    _scheduleAudioPreparation(story);
    final visual = story == null
        ? const StoryVisual(
            emoji: '☀️',
            color: Color(0xFFFFB35A),
            subtitle: '睡前故事',
          )
        : storyVisualOf(story);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            _HomePlayerBackground(story: story, visual: visual),
            RefreshIndicator(
              color: AppTheme.coral,
              onRefresh: () => ref
                  .read(storyLibraryControllerProvider.notifier)
                  .loadStories(force: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(22.w, 92.h, 22.w, 30.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _HomeGreeting(),
                        const Spacer(),
                        if (_audioError != null && story != null) ...[
                          Text(
                            _audioError!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x993A2819),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                          ),
                          SizedBox(height: 10.h),
                        ],
                        if (state.error != null) ...[
                          JoyfishCard(
                            padding: EdgeInsets.all(14.w),
                            backgroundColor: const Color(
                              0xFFFFEFE7,
                            ).withValues(alpha: 0.92),
                            child: Text(
                              state.error!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFFB64231),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          SizedBox(height: 10.h),
                        ],
                        _StoryPlayerPanel(
                          story: story,
                          visual: visual,
                          meta: story == null ? '故事小岛待开张' : _storyMeta(story),
                          summary: _storySummary(
                            story,
                            fallback: '选一个角色、场景和主题，乐鱼故事会把它编成温暖又童趣的睡前故事。',
                          ),
                          primaryText: _primaryButtonText(story),
                          primaryIcon: story == null
                              ? Icons.auto_awesome_rounded
                              : _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          onPrimary: story == null
                              ? widget.onCreateStory
                              : _togglePlayback,
                          onOpenStory: story == null
                              ? null
                              : () => widget.onOpenStory(story.id),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  bool get _isPlaying {
    final state = _player.playerState;
    return state.playing && state.processingState == ProcessingState.ready;
  }

  String _primaryButtonText(StoryRecord? story) {
    if (story == null) return '开启故事';
    if (_audioLoading) return '音频加载中';
    if (!_audioReady) return '查看故事';
    return _isPlaying ? '暂停播放' : '开始播放';
  }

  void _scheduleAudioPreparation(StoryRecord? story) {
    if (story == null) {
      if (_preparedStoryId != null) {
        scheduleMicrotask(() async {
          await _player.stop();
          if (mounted) {
            setState(() {
              _preparedStoryId = null;
              _audioReady = false;
              _audioError = null;
            });
          }
        });
      }
      return;
    }

    if (_preparedStoryId == story.id || _audioLoading) {
      return;
    }

    scheduleMicrotask(() => _prepareAudio(story));
  }

  Future<void> _prepareAudio(StoryRecord story) async {
    if (_preparedStoryId == story.id || _audioLoading) {
      return;
    }
    final audioUrl = AppConfig.instance.resolveMediaUrl(story.audioUrl);
    setState(() {
      _preparedStoryId = story.id;
      _audioLoading = true;
      _audioReady = false;
      _audioError = null;
    });
    await _player.stop();
    await _player.setLoopMode(LoopMode.off);

    if (audioUrl == null) {
      if (mounted) {
        setState(() {
          _audioLoading = false;
          _audioError = '当前故事暂无音频';
        });
      }
      return;
    }

    try {
      final localPath = await _audioCache.resolve(
        storyId: story.id,
        audioUrl: audioUrl,
      );
      await _player.setFilePath(localPath);
      if (mounted) {
        setState(() {
          _audioLoading = false;
          _audioReady = true;
        });
      }
    } catch (_) {
      try {
        await _player.setUrl(audioUrl);
        if (mounted) {
          setState(() {
            _audioLoading = false;
            _audioReady = true;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _audioLoading = false;
            _audioError = '音频暂时无法播放';
          });
        }
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (!_audioReady) {
      final stories = ref.read(storyLibraryControllerProvider).items;
      if (stories.isNotEmpty) {
        final story = stories.first;
        widget.onOpenStory(story.id);
      }
      return;
    }

    final state = _player.playerState;
    if (state.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
      await _player.play();
      return;
    }
    if (state.playing) {
      await _player.pause();
      return;
    }
    await _player.play();
  }

  static String _storyMeta(StoryRecord story) {
    final minutes = story.readingMinutes ?? 8;
    final age = story.ageRange?.isNotEmpty == true
        ? ' · ${story.ageRange}'
        : '';
    return '约 $minutes 分钟$age';
  }

  static String _storySummary(StoryRecord? story, {required String fallback}) {
    if (story == null) {
      return fallback;
    }
    if (story.summary?.isNotEmpty == true) {
      return story.summary!;
    }
    return _firstParagraph(story.bodyMd);
  }

  static String _firstParagraph(String body) {
    final text = body
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .join(' ');
    if (text.length <= 96) return text;
    return '${text.substring(0, 96)}...';
  }
}

class _HomeGreeting extends StatelessWidget {
  const _HomeGreeting();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '乐鱼故事',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  height: 1.05,
                  shadows: const [
                    Shadow(color: Color(0x993A2819), blurRadius: 12),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '今天想去哪里冒险？',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontWeight: FontWeight.w800,
                  shadows: const [
                    Shadow(color: Color(0x883A2819), blurRadius: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 58.w,
          height: 58.w,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.68),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A7E5730),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(8.w),
            child: Image.asset('assets/images/joyfish_logo.png'),
          ),
        ),
      ],
    );
  }
}

class _HomePlayerBackground extends StatelessWidget {
  const _HomePlayerBackground({required this.story, required this.visual});

  final StoryRecord? story;
  final StoryVisual visual;

  @override
  Widget build(BuildContext context) {
    final imageUrl = story == null
        ? null
        : AppConfig.instance.resolveMediaUrl(story!.coverImageUrl);

    return Stack(
      fit: StackFit.expand,
      children: [
        _WarmBackgroundFallback(visual: visual),
        if (imageUrl != null)
          JoyfishCachedImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_) => const SizedBox.shrink(),
            errorBuilder: (context, error, stackTrace) =>
                _WarmBackgroundFallback(visual: visual),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x1AFFF5DE), Color(0x663A2819), Color(0xCC2C2119)],
              stops: [0.0, 0.46, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.64, -0.58),
              radius: 0.74,
              colors: [
                AppTheme.peach.withValues(alpha: 0.28),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StoryPlayerPanel extends StatelessWidget {
  const _StoryPlayerPanel({
    required this.story,
    required this.visual,
    required this.meta,
    required this.summary,
    required this.primaryText,
    required this.primaryIcon,
    required this.onPrimary,
    required this.onOpenStory,
  });

  final StoryRecord? story;
  final StoryVisual visual;
  final String meta;
  final String summary;
  final String primaryText;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final VoidCallback? onOpenStory;

  @override
  Widget build(BuildContext context) {
    return JoyfishCard(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 18.h),
      radius: 28.r,
      backgroundColor: const Color(0xFFFFFBF0).withValues(alpha: 0.86),
      border: Border.all(color: Colors.white.withValues(alpha: 0.58)),
      shadow: const [
        BoxShadow(
          color: Color(0x593A2819),
          blurRadius: 28,
          offset: Offset(0, 16),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _TinyBadge(text: visual.subtitle),
              SizedBox(height: 14.h),
              _StoryTitleBlock(
                title: story?.title ?? '今晚还没有故事',
                meta: meta,
                centered: true,
              ),
              SizedBox(height: 14.h),
              _PlayerGroove(color: visual.color),
              SizedBox(height: 14.h),
              Text(
                summary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.58,
                  color: AppTheme.olive,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 18.h),
              Builder(
                builder: (context) {
                  final primary = AppButton(
                    text: primaryText,
                    height: 52.h,
                    backgroundColor: AppTheme.coral,
                    textColor: Colors.white,
                    borderRadius: BorderRadius.circular(26.r),
                    icon: Icon(primaryIcon, color: Colors.white, size: 22.sp),
                    onPressed: onPrimary,
                  );
                  if (story == null) return primary;
                  return Row(
                    children: [
                      Expanded(child: primary),
                      SizedBox(width: 10.w),
                      _PillTextButton(
                        icon: Icons.menu_book_rounded,
                        text: '阅读',
                        onTap: onOpenStory!,
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StoryTitleBlock extends StatelessWidget {
  const _StoryTitleBlock({
    required this.title,
    required this.meta,
    this.centered = false,
  });

  final String title;
  final String meta;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppTheme.ink,
            height: 1.16,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          meta,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.coral,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _WarmBackgroundFallback extends StatelessWidget {
  const _WarmBackgroundFallback({required this.visual});

  final StoryVisual visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.peach,
            visual.color.withValues(alpha: 0.82),
            AppTheme.leaf.withValues(alpha: 0.68),
          ],
        ),
      ),
      child: Align(
        alignment: const Alignment(0, -0.16),
        child: Text(visual.emoji, style: TextStyle(fontSize: 116.sp)),
      ),
    );
  }
}

class _PlayerGroove extends StatelessWidget {
  const _PlayerGroove({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99.r),
            child: LinearProgressIndicator(
              minHeight: 6.h,
              value: 0.36,
              backgroundColor: const Color(0xFFFFE8C9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Icon(Icons.graphic_eq_rounded, color: color, size: 22.sp),
      ],
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.leaf.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(99.r),
          border: Border.all(color: AppTheme.leaf.withValues(alpha: 0.16)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.skyDeep,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _PillTextButton extends StatelessWidget {
  const _PillTextButton({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: AppTheme.skyDeep.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(26.r),
          border: Border.all(color: AppTheme.skyDeep.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.skyDeep, size: 18.sp),
            SizedBox(width: 5.w),
            Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.skyDeep,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
