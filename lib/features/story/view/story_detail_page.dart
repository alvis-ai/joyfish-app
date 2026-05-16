import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/utils/story_presenter.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/joyfish_cached_image.dart';
import '../../../common/widgets/joyfish_scaffold.dart';
import '../../../common/widgets/story_cards.dart';
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
    _playerStateSubscription =
        _player.playerStateStream.listen(_syncPositionTicker);
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
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppTheme.mutedInk),
                ),
              ),
            );
          }

          final story = snapshot.data!;
          final visual = storyVisualOf(story);
          final coverUrl =
              AppConfig.instance.resolveMediaUrl(story.coverImageUrl);
          final fallbackDuration = Duration(minutes: story.readingMinutes ?? 8);

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
                padding: EdgeInsets.fromLTRB(26.w, 10.h, 26.w, 128.h),
                children: [
                  _StoryTopBar(onBack: () => context.router.maybePop()),
                  SizedBox(height: 26.h),
                  AspectRatio(
                    aspectRatio: joyfishGoldenRatio,
                    child: JoyfishCard(
                      padding: EdgeInsets.zero,
                      radius: 30.r,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30.r),
                        child: _DetailCover(visual: visual, imageUrl: coverUrl),
                      ),
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
                  JoyfishCard(
                    padding: EdgeInsets.all(24.w),
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
                  if (_audioLoadError != null) ...[
                    SizedBox(height: 16.h),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppTheme.olive),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 28.h),
                  StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder: (context, snapshot) {
                      final state = snapshot.data ?? _player.playerState;
                      final completed =
                          state.processingState == ProcessingState.completed;
                      final isBuffering = state.processingState ==
                              ProcessingState.loading ||
                          state.processingState == ProcessingState.buffering;
                      final isPlaying = state.playing &&
                          state.processingState == ProcessingState.ready;
                      return AppButton(
                        text: _audioLoading
                            ? '音频加载中'
                            : isBuffering
                                ? '音频缓冲中'
                                : _audioReady
                                    ? (isPlaying
                                        ? '暂停故事'
                                        : completed
                                            ? '重新讲故事'
                                            : '开始讲故事')
                                    : '音频暂不可用',
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
                        onPressed: _audioReady ? _togglePlayback : null,
                      );
                    },
                  ),
                  SizedBox(height: 20.h),
                  _AudioProgress(
                    position: _displayPosition,
                    actualDuration: _player.duration,
                    fallbackDuration: fallbackDuration,
                    minHeight: 10.h,
                    color: AppTheme.skyDeep,
                    showTotal: true,
                  ),
                  SizedBox(height: 26.h),
                  JoyfishCard(
                    padding: EdgeInsets.all(22.w),
                    child: _StoryBodyContent(story: story),
                  ),
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
        final isPlaying = playerState.playing &&
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
                            colors: [Color(0xFF7357F6), Color(0xFF5B7CF6)],
                          )
                        : null,
                    color: enabled ? null : const Color(0xFFE4DFEA),
                    shape: BoxShape.circle,
                    boxShadow: enabled
                        ? const [
                            BoxShadow(
                              color: Color(0x2F7357F6),
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
          color: const Color(0xFF7357F6),
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
    this.showTotal = false,
  });

  final Duration position;
  final Duration? actualDuration;
  final Duration fallbackDuration;
  final double minHeight;
  final Color color;
  final bool enabled;
  final bool showTotal;

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

    final progress = ClipRRect(
      borderRadius: BorderRadius.circular(99.r),
      child: LinearProgressIndicator(
        minHeight: minHeight,
        value: value,
        backgroundColor: const Color(0xFFE8E2F2),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );

    if (!showTotal) {
      return progress;
    }

    return Column(
      children: [
        progress,
        SizedBox(height: 8.h),
        Row(
          children: [
            Text(
              _formatAudioDuration(displayPosition),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            Text(
              hasActualDuration
                  ? _formatAudioDuration(duration)
                  : '约 ${_formatAudioDuration(duration)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
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

enum _StoryBlockType { heading, paragraph, image }

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
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: AppTheme.skyDeep),
        );
      case _StoryBlockType.image:
        final url = AppConfig.instance.resolveMediaUrl(block.value);
        if (url == null) {
          return const SizedBox.shrink();
        }
        return _StoryImage(url: url);
      case _StoryBlockType.paragraph:
        return Text(
          block.value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7),
        );
    }
  }
}

List<_StoryContentBlock> _composeStoryBlocks(StoryRecord story) {
  final parsed = _parseStoryBlocks(story.bodyMd);
  if (parsed.any((block) => block.type == _StoryBlockType.image)) {
    return parsed;
  }

  final paragraphs = parsed
      .where((block) => block.type == _StoryBlockType.paragraph)
      .map((block) => block.value)
      .toList();
  final images = _deriveStoryImageUrls(story);
  if (images.isEmpty || paragraphs.isEmpty) {
    return parsed;
  }

  final blocks = <_StoryContentBlock>[];
  for (var index = 0; index < paragraphs.length; index++) {
    blocks
        .add(_StoryContentBlock(_StoryBlockType.paragraph, paragraphs[index]));
    final imageIndex = index + 1;
    if (imageIndex < images.length) {
      blocks.add(_StoryContentBlock(_StoryBlockType.image, images[imageIndex]));
    }
  }
  return blocks;
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
      blocks.add(_StoryContentBlock(_StoryBlockType.image, imageUrl));
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

List<String> _deriveStoryImageUrls(StoryRecord story) {
  final urls = <String>[];
  if ((story.coverImageUrl ?? '').trim().isNotEmpty) {
    urls.add(story.coverImageUrl!.trim());
  }

  final cover = story.coverImageUrl ?? '';
  final match = RegExp(r'^(.*)/cover\.[a-zA-Z0-9]+$').firstMatch(cover);
  final base = match?.group(1);
  if (base != null) {
    for (var index = 1; index <= 4; index++) {
      urls.add('$base/scene-${index.toString().padLeft(2, '0')}.png');
    }
  }

  return urls;
}

class _StoryImage extends StatelessWidget {
  const _StoryImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: AspectRatio(
        aspectRatio: 1,
        child: JoyfishCachedImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (context) => Container(
            color: const Color(0xFFEAF5FF),
            alignment: Alignment.center,
            child: SizedBox(
              width: 24.w,
              height: 24.w,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFFEAF5FF),
            alignment: Alignment.center,
            child: Icon(
              Icons.image_not_supported_rounded,
              color: AppTheme.mutedInk,
              size: 32.sp,
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryTopBar extends StatelessWidget {
  const _StoryTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return JoyfishPageHeader(
      title: '故事详情',
      subtitle: '阅读绘本并选择喜欢的声音',
      leading: JoyfishIconBubble(
        icon: Icons.arrow_back_rounded,
        onTap: onBack,
      ),
      trailing: JoyfishIconBubble(
        icon: Icons.home_rounded,
        onTap: () => context.router.popUntilRoot(),
      ),
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
        Positioned(
          left: 20.w,
          top: 20.h,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Text(
              visual.subtitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
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
            const Color(0xFF222431)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          visual.emoji,
          style: TextStyle(fontSize: 96.sp),
        ),
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
    return JoyfishCard(
      radius: 28.r,
      backgroundColor: Colors.white,
      border: Border.all(
        color: selected ? const Color(0xFF9AE86B) : const Color(0xFFF0EBF8),
        width: selected ? 3 : 1.2,
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
