import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/widgets/app_button.dart';
import '../../../core/router/app_router.dart';
import '../models/story_models.dart';
import '../providers/story_providers.dart';

@RoutePage()
class StoryGeneratingPage extends ConsumerStatefulWidget {
  const StoryGeneratingPage({
    super.key,
    @PathParam('requestId') required this.requestId,
  });

  final int requestId;

  @override
  ConsumerState<StoryGeneratingPage> createState() =>
      _StoryGeneratingPageState();
}

class _StoryGeneratingPageState extends ConsumerState<StoryGeneratingPage>
    with WidgetsBindingObserver {
  Timer? _timer;
  StoryRequestRecord? _request;
  bool _loading = true;
  bool _appVisible = true;
  bool _polling = false;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_appVisible) {
        _poll();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appVisible = state == AppLifecycleState.resumed;
    if (_appVisible) {
      _poll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    final status = request?.status ?? 'pending';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          unawaited(_syncAfterExit());
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('故事生成中')),
        body: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              SizedBox(height: 50.h),
              Container(
                width: 112.w,
                height: 112.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5FF),
                  borderRadius: BorderRadius.circular(36.r),
                ),
                child: const Icon(Icons.auto_stories_rounded,
                    size: 54, color: AppTheme.skyDeep),
              ),
              SizedBox(height: 24.h),
              Text('正在编织今晚的故事',
                  style: Theme.of(context).textTheme.displaySmall),
              SizedBox(height: 10.h),
              Text(
                _statusText(status),
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppTheme.mutedInk),
              ),
              SizedBox(height: 26.h),
              if (_loading)
                const CircularProgressIndicator()
              else
                Container(
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      _InfoLine(label: '状态', value: status),
                      _InfoLine(
                        label: '尝试次数',
                        value:
                            '${request?.attemptCount ?? 0}/${request?.maxAttempts ?? 0}',
                      ),
                      _InfoLine(
                          label: '主题',
                          value: request?.themeTags.join('、') ?? '未设置'),
                      if ((request?.lastError ?? '').isNotEmpty)
                        _InfoLine(label: '错误', value: request!.lastError!),
                    ],
                  ),
                ),
              const Spacer(),
              if (status == 'failed')
                AppButton.secondary(
                  text: '返回重新编辑',
                  onPressed: _returnToComposer,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusText(String status) {
    switch (status) {
      case 'running':
        return '后端已经接单，正在生成正文、配图和音频。';
      case 'succeeded':
        return '故事已经准备好了，正在同步到你的书架。';
      case 'failed':
        return '这次生成没有成功，可以返回重新尝试。';
      default:
        return '请求已提交，正在排队处理中。';
    }
  }

  Future<void> _poll() async {
    if (_polling || _navigating) {
      return;
    }
    _polling = true;
    try {
      final repository = ref.read(storyRepositoryProvider);
      final request = await repository.getStoryRequest(widget.requestId);
      if (!mounted) return;
      setState(() {
        _request = request;
        _loading = false;
      });

      if (request.status == 'succeeded' && !_navigating) {
        final stories = await repository.listStories();
        StoryRecord? match;
        for (final story in stories) {
          if (story.requestId == widget.requestId) {
            match = story;
            break;
          }
        }
        if (match != null && mounted) {
          _navigating = true;
          await ref
              .read(storyLibraryControllerProvider.notifier)
              .loadStories(force: true);
          if (!mounted) return;
          context.router.replace(StoryDetailRoute(storyId: match.id));
        } else {
          await ref
              .read(storyLibraryControllerProvider.notifier)
              .loadStories(force: true);
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    } finally {
      _polling = false;
    }
  }

  Future<void> _syncAfterExit() {
    return ref
        .read(storyLibraryControllerProvider.notifier)
        .loadStories(force: true);
  }

  Future<void> _returnToComposer() async {
    await _syncAfterExit();
    if (!mounted) return;
    final popped = await context.router.maybePop();
    if (!popped && mounted) {
      context.router.replace(const StoryComposerRoute());
    }
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72.w,
            child:
                Text(label, style: const TextStyle(color: AppTheme.mutedInk)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
