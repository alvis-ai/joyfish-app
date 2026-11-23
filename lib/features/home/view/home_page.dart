import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/utils/story_presenter.dart';
import '../../../common/widgets/candy_widgets.dart';
import '../../../common/widgets/joyfish_cached_image.dart';
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
        return RefreshIndicator(
          color: AppTheme.candyPink,
          onRefresh: () => ref
              .read(storyLibraryControllerProvider.notifier)
              .loadStories(force: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: SizedBox(
              height: constraints.maxHeight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(22.w, 82.h, 22.w, 26.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _HomeGreeting(),
                    SizedBox(height: 16.h),
                    Expanded(
                      child: _CoverSticker(
                        story: story,
                        visual: visual,
                        notice: story == null ? null : _audioError,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    if (state.error != null) ...[
                      StickerCard(
                        padding: EdgeInsets.all(14.w),
                        color: AppTheme.candyPinkSoft,
                        shadowOffset: 4,
                        child: Text(
                          state.error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.navy,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      SizedBox(height: 14.h),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '乐鱼故事',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppTheme.navy,
                  height: 1.05,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(
                    Icons.wb_sunny_rounded,
                    color: AppTheme.lemon,
                    size: 20.sp,
                  ),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      '今天想去哪里冒险？',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.navyMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        FloatingMascot(size: 62.r),
      ],
    );
  }
}

/// The current story's cover, framed like a slightly tilted sticker.
class _CoverSticker extends StatelessWidget {
  const _CoverSticker({
    required this.story,
    required this.visual,
    required this.notice,
  });

  final StoryRecord? story;
  final StoryVisual visual;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final imageUrl = story == null
        ? null
        : AppConfig.instance.resolveMediaUrl(story!.coverImageUrl);
    final radius = BorderRadius.circular(32.r);

    return Transform.rotate(
      angle: -0.025,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: AppTheme.stickerBorder(width: 3),
          boxShadow: AppTheme.stickerShadow(color: AppTheme.skyBlue, offset: 8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(29.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _CoverFallback(visual: visual),
              if (imageUrl != null)
                JoyfishCachedImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_) => const SizedBox.shrink(),
                  errorBuilder: (context, error, stackTrace) =>
                      _CoverFallback(visual: visual),
                ),
              Positioned(
                left: 14.w,
                top: 14.h,
                child: CandyChip(
                  text: visual.subtitle,
                  color: AppTheme.lemon,
                  icon: Icons.auto_awesome_rounded,
                ),
              ),
              if (notice != null)
                Positioned(
                  left: 14.w,
                  right: 14.w,
                  bottom: 14.h,
                  child: Center(
                    child: CandyChip(
                      text: notice!,
                      color: Colors.white,
                      icon: Icons.volume_off_rounded,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback({required this.visual});

  final StoryVisual visual;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.lemonSoft, visual.color.withValues(alpha: 0.55)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -30.w,
            top: -30.h,
            child: _Dot(size: 120.r, color: Colors.white),
          ),
          Positioned(
            left: -20.w,
            bottom: -24.h,
            child: _Dot(size: 90.r, color: AppTheme.candyPinkSoft),
          ),
          Center(
            child: Text(visual.emoji, style: TextStyle(fontSize: 108.sp)),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.55),
        shape: BoxShape.circle,
      ),
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
    return StickerCard(
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            story?.title ?? '今晚还没有故事',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppTheme.navy,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Flexible(
                child: CandyChip(
                  text: meta,
                  color: AppTheme.skySoft,
                  icon: Icons.schedule_rounded,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (story != null) ...[
            _PlayerGroove(color: AppTheme.candyPink),
            SizedBox(height: 12.h),
          ],
          Text(
            summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: AppTheme.navyMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: CandyButton(
                  label: primaryText,
                  icon: primaryIcon,
                  onPressed: onPrimary,
                  height: 54.h,
                ),
              ),
              if (story != null) ...[
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: CandyButton(
                    label: '阅读',
                    icon: Icons.menu_book_rounded,
                    onPressed: onOpenStory,
                    color: AppTheme.lemon,
                    foregroundColor: AppTheme.navy,
                    height: 54.h,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ],
          ),
        ],
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
          child: Container(
            height: 12.h,
            decoration: BoxDecoration(
              color: AppTheme.candyPinkSoft,
              borderRadius: BorderRadius.circular(99.r),
              border: AppTheme.stickerBorder(width: 2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.36,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(99.r),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Icon(Icons.graphic_eq_rounded, color: color, size: 24.sp),
      ],
    );
  }
}
