import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/utils/story_presenter.dart';
import '../../../common/widgets/joyfish_cached_image.dart';
import '../../../common/widgets/joyfish_scaffold.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../models/story_models.dart';
import '../repository/story_repository.dart';
import '../service/story_audio_cache.dart';

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
  final StoryAudioCache _audioCache = const StoryAudioCache();
  late Future<StoryRecord> _future;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  Timer? _positionTicker;
  Duration _displayPosition = Duration.zero;
  DateTime? _lastPositionTick;
  bool _audioLoading = false;
  bool _audioReady = false;
  String? _audioLoadError;

  @override
  void initState() {
    super.initState();
    _playerStateSubscription = _player.playerStateStream.listen(
      _syncPositionTicker,
    );
    _future = _loadStory();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionTicker?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _syncPositionTicker(PlayerState state) {
    final shouldTick =
        state.playing && state.processingState == ProcessingState.ready;
    if (shouldTick && _positionTicker == null) {
      _lastPositionTick = DateTime.now();
      _positionTicker = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (mounted) {
          _advanceDisplayedPosition();
        }
      });
      return;
    }

    if (!shouldTick && _positionTicker != null) {
      _positionTicker?.cancel();
      _positionTicker = null;
      _lastPositionTick = null;
      if (mounted) {
        setState(() {
          _displayPosition = _syncedPositionFor(state);
        });
      }
    }
  }

  void _advanceDisplayedPosition() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastPositionTick ?? now);
    _lastPositionTick = now;

    final playerPosition = _player.position;
    var next = playerPosition > _displayPosition + elapsed
        ? playerPosition
        : _displayPosition + elapsed;
    final duration = _player.duration;
    if (duration != null && duration > Duration.zero && next > duration) {
      next = duration;
    }

    setState(() => _displayPosition = next);
  }

  Duration _syncedPositionFor(PlayerState state) {
    final duration = _player.duration;
    if (state.processingState == ProcessingState.completed &&
        duration != null &&
        duration > Duration.zero) {
      return duration;
    }

    final playerPosition = _player.position;
    if (playerPosition > _displayPosition) {
      return playerPosition;
    }
    return _displayPosition;
  }

  Future<StoryRecord> _loadStory() async {
    final story = await StoryRepository().getStory(widget.storyId);
    unawaited(_prepareAudio(story));
    return story;
  }

  Future<void> _prepareAudio(StoryRecord story) async {
    final audioUrl = AppConfig.instance.resolveMediaUrl(story.audioUrl);
    if (audioUrl != null) {
      if (mounted) {
        setState(() {
          _audioLoading = true;
          _audioReady = false;
          _audioLoadError = null;
          _displayPosition = Duration.zero;
        });
      }
      try {
        final localPath = await _audioCache.resolve(
          storyId: story.id,
          audioUrl: audioUrl,
        );
        await _player.setFilePath(localPath);
        if (mounted) {
          setState(() => _audioReady = true);
        }
      } catch (_) {
        try {
          await _player.setUrl(audioUrl);
          if (mounted) {
            setState(() => _audioReady = true);
          }
        } catch (_) {
          if (mounted) {
            setState(() {
              _audioReady = false;
              _audioLoadError = '音频暂时无法播放，可先阅读故事内容';
            });
          }
        }
      } finally {
        if (mounted) {
          setState(() => _audioLoading = false);
        }
      }
    } else if (mounted) {
      setState(() {
        _audioReady = false;
        _audioLoadError = '当前故事暂无音频，可先阅读故事内容';
      });
    }
  }

  Future<void> _togglePlayback() async {
    if (!_audioReady) {
      return;
    }

    final state = _player.playerState;
    if (state.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
      if (mounted) {
        setState(() => _displayPosition = Duration.zero);
      }
      await _player.play();
      return;
    }

    if (state.playing) {
      await _player.pause();
      return;
    }

    await _player.play();
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
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Text(
                  '故事加载失败：${userFacingErrorMessage(snapshot.error ?? Exception('unknown'))}',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppTheme.mutedInk),
                ),
              ),
            );
          }

          final story = snapshot.data!;
          final visual = storyVisualOf(story);
          final coverUrl = AppConfig.instance.resolveMediaUrl(
            story.coverImageUrl,
          );
          final fallbackDuration = Duration(minutes: story.readingMinutes ?? 8);

          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFFFE1AC).withValues(alpha: 0.48),
                        const Color(0xFFFFF8EC).withValues(alpha: 0.24),
                        const Color(0xFFEAF7E0).withValues(alpha: 0.34),
                      ],
                    ),
                  ),
                ),
              ),
              ListView(
                padding: EdgeInsets.fromLTRB(22.w, 8.h, 22.w, 128.h),
                children: [
                  _StoryTopBar(onBack: () => context.router.maybePop()),
                  SizedBox(height: 18.h),
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: JoyfishCard(
                      padding: EdgeInsets.zero,
                      radius: 24.r,
                      border: Border.all(
                        color: const Color(0xFFFFF3DF),
                        width: 1.2,
                      ),
                      shadow: const [
                        BoxShadow(
                          color: Color(0x247E5730),
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        ),
                      ],
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24.r),
                        child: _DetailCover(visual: visual, imageUrl: coverUrl),
                      ),
                    ),
                  ),
                  SizedBox(height: 22.h),
                  Text(
                    story.title,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.skyDeep,
                      height: 1.12,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  if ((story.summary ?? '').isNotEmpty ||
                      _firstParagraph(story.bodyMd).isNotEmpty)
                    Text(
                      story.summary?.isNotEmpty == true
                          ? story.summary!
                          : _firstParagraph(story.bodyMd),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.55,
                        color: AppTheme.olive,
                      ),
                    ),
                  if (_audioLoadError != null) ...[
                    SizedBox(height: 18.h),
                    JoyfishCard(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 14.h,
                      ),
                      backgroundColor: const Color(0xFFFFF7E6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.volume_off_rounded,
                            color: AppTheme.olive,
                            size: 22.sp,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              _audioLoadError!,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.olive),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 28.h),
                  _StoryBodyContent(story: story),
                ],
              ),
              Positioned(
                left: 22.w,
                right: 22.w,
                bottom: MediaQuery.paddingOf(context).bottom + 16.h,
                child: _FloatingAudioControl(
                  player: _player,
                  position: _displayPosition,
                  fallbackDuration: fallbackDuration,
                  loading: _audioLoading,
                  ready: _audioReady,
                  error: _audioLoadError,
                  onToggle: _togglePlayback,
                ),
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
}

class _FloatingAudioControl extends StatelessWidget {
  const _FloatingAudioControl({
    required this.player,
    required this.position,
    required this.fallbackDuration,
    required this.loading,
    required this.ready,
    required this.error,
    required this.onToggle,
  });

  final AudioPlayer player;
  final Duration position;
  final Duration fallbackDuration;
  final bool loading;
  final bool ready;
  final String? error;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, stateSnapshot) {
        final playerState = stateSnapshot.data ?? player.playerState;
        final completed =
            playerState.processingState == ProcessingState.completed;
        final isBuffering =
            playerState.processingState == ProcessingState.loading ||
            playerState.processingState == ProcessingState.buffering;
        final isPlaying =
            playerState.playing &&
            playerState.processingState == ProcessingState.ready;
        final enabled = ready && !loading;

        return JoyfishCard(
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 16.w, 12.h),
          radius: 28.r,
          backgroundColor: Colors.white.withValues(alpha: 0.96),
          border: Border.all(color: const Color(0xFFF0EBF8), width: 1.2),
          child: Row(
            children: [
              GestureDetector(
                onTap: enabled ? onToggle : null,
                child: Container(
                  width: 54.w,
                  height: 54.w,
                  decoration: BoxDecoration(
                    gradient: enabled
                        ? const LinearGradient(
                            colors: [Color(0xFFFFA05D), Color(0xFF327E71)],
                          )
                        : null,
                    color: enabled ? null : const Color(0xFFE4DFEA),
                    shape: BoxShape.circle,
                    boxShadow: enabled
                        ? const [
                            BoxShadow(
                              color: Color(0x33B66A32),
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: loading
                      ? Padding(
                          padding: EdgeInsets.all(16.w),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isPlaying && !completed
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: enabled ? Colors.white : AppTheme.mutedInk,
                          size: 34.sp,
                        ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: _FloatingAudioDetails(
                  player: player,
                  position: position,
                  fallbackDuration: fallbackDuration,
                  loading: loading,
                  buffering: isBuffering,
                  ready: ready,
                  isPlaying: isPlaying,
                  completed: completed,
                  error: error,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FloatingAudioDetails extends StatelessWidget {
  const _FloatingAudioDetails({
    required this.player,
    required this.position,
    required this.fallbackDuration,
    required this.loading,
    required this.buffering,
    required this.ready,
    required this.isPlaying,
    required this.completed,
    required this.error,
  });

  final AudioPlayer player;
  final Duration position;
  final Duration fallbackDuration;
  final bool loading;
  final bool buffering;
  final bool ready;
  final bool isPlaying;
  final bool completed;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final title = loading
        ? '正在准备音频'
        : buffering
        ? '正在缓冲音频'
        : ready
        ? (isPlaying
              ? '正在讲故事'
              : completed
              ? '点击重新播放'
              : '点击播放故事')
        : '音频暂不可用';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF2D3446),
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 6.h),
        _AudioProgress(
          position: position,
          actualDuration: player.duration,
          fallbackDuration: fallbackDuration,
          minHeight: 7.h,
          color: AppTheme.coral,
          enabled: ready,
        ),
        SizedBox(height: 5.h),
        Text(
          error ?? _formatAudioProgressLabel(position, player.duration),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.mutedInk,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AudioProgress extends StatelessWidget {
  const _AudioProgress({
    required this.position,
    required this.actualDuration,
    required this.fallbackDuration,
    required this.minHeight,
    required this.color,
    this.enabled = true,
  });

  final Duration position;
  final Duration? actualDuration;
  final Duration fallbackDuration;
  final double minHeight;
  final Color color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final hasActualDuration =
        actualDuration != null && actualDuration! > Duration.zero;
    final duration = hasActualDuration ? actualDuration! : fallbackDuration;
    final displayPosition = position > duration ? duration : position;
    final totalMs = duration.inMilliseconds == 0 ? 1 : duration.inMilliseconds;
    final value = enabled
        ? (displayPosition.inMilliseconds / totalMs).clamp(0.0, 1.0)
        : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(99.r),
      child: LinearProgressIndicator(
        minHeight: minHeight,
        value: value,
        backgroundColor: const Color(0xFFFFE7C7),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

String _formatAudioDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _formatAudioProgressLabel(Duration position, Duration? duration) {
  if (duration == null || duration <= Duration.zero) {
    return _formatAudioDuration(position);
  }
  return '${_formatAudioDuration(position)} / ${_formatAudioDuration(duration)}';
}

enum _StoryBlockType { heading, paragraph }

class _StoryContentBlock {
  const _StoryContentBlock(this.type, this.value);

  final _StoryBlockType type;
  final String value;
}

class _StoryBodyContent extends StatelessWidget {
  const _StoryBodyContent({required this.story});

  final StoryRecord story;

  @override
  Widget build(BuildContext context) {
    final blocks = _composeStoryBlocks(story);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < blocks.length; index++) ...[
          _StoryBlockView(block: blocks[index]),
          if (index != blocks.length - 1) SizedBox(height: 18.h),
        ],
      ],
    );
  }
}

class _StoryBlockView extends StatelessWidget {
  const _StoryBlockView({required this.block});

  final _StoryContentBlock block;

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case _StoryBlockType.heading:
        return Text(
          block.value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.skyDeep,
            height: 1.18,
          ),
        );
      case _StoryBlockType.paragraph:
        return Text(
          block.value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.72,
            color: const Color(0xFF363023),
          ),
        );
    }
  }
}

List<_StoryContentBlock> _composeStoryBlocks(StoryRecord story) {
  return _parseStoryBlocks(story.bodyMd);
}

List<_StoryContentBlock> _parseStoryBlocks(String markdown) {
  final blocks = <_StoryContentBlock>[];
  final paragraph = StringBuffer();

  void flushParagraph() {
    final text = paragraph.toString().trim();
    paragraph.clear();
    if (text.isEmpty) {
      return;
    }
    blocks.add(_StoryContentBlock(_StoryBlockType.paragraph, text));
  }

  for (final rawLine in markdown.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) {
      flushParagraph();
      continue;
    }
    if (line.startsWith('<audio')) {
      flushParagraph();
      continue;
    }
    if (line.startsWith('> 对应片段')) {
      flushParagraph();
      continue;
    }

    final imageUrl = _extractMarkdownImageUrl(line);
    if (imageUrl != null) {
      flushParagraph();
      continue;
    }

    if (line.startsWith('# ')) {
      flushParagraph();
      continue;
    }
    if (line == '## 插图分镜') {
      flushParagraph();
      continue;
    }
    if (line.startsWith('## ')) {
      flushParagraph();
      blocks.add(
        _StoryContentBlock(_StoryBlockType.heading, line.substring(3).trim()),
      );
      continue;
    }

    final cleaned = _cleanInlineMarkdown(line);
    if (cleaned.isEmpty) {
      continue;
    }
    if (paragraph.isNotEmpty) {
      paragraph.write('\n');
    }
    paragraph.write(cleaned);
  }

  flushParagraph();
  return blocks;
}

String? _extractMarkdownImageUrl(String line) {
  final match = RegExp(r'^!\[[^\]]*\]\(([^)]+)\)$').firstMatch(line);
  return match?.group(1)?.trim();
}

String _cleanInlineMarkdown(String line) {
  var text = line.trim();
  if (text.startsWith('_') && text.endsWith('_') && text.length > 1) {
    text = text.substring(1, text.length - 1);
  }
  return text
      .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
      .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
      .trim();
}

class _StoryTopBar extends StatelessWidget {
  const _StoryTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        JoyfishIconBubble(icon: Icons.arrow_back_rounded, onTap: onBack),
        const Spacer(),
        JoyfishIconBubble(
          icon: Icons.home_rounded,
          onTap: () => context.router.popUntilRoot(),
        ),
      ],
    );
  }
}

class _DetailCover extends StatelessWidget {
  const _DetailCover({required this.visual, required this.imageUrl});

  final StoryVisual visual;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl != null)
          JoyfishCachedImage(
            imageUrl: imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _FallbackCover(visual: visual),
          )
        else
          _FallbackCover(visual: visual),
      ],
    );
  }
}

class _FallbackCover extends StatelessWidget {
  const _FallbackCover({required this.visual});

  final StoryVisual visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            visual.color.withValues(alpha: 0.95),
            const Color(0xFF222431),
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
