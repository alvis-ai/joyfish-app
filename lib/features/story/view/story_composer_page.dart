import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/joyfish_scaffold.dart';
import '../../../core/router/app_router.dart';
import '../../children/providers/child_providers.dart';
import '../../voice/providers/voice_providers.dart';
import '../providers/story_providers.dart';

class _StoryThemePreset {
  const _StoryThemePreset({
    required this.label,
    required this.emoji,
    required this.color,
    required this.scenario,
  });

  final String label;
  final String emoji;
  final Color color;
  final String scenario;
}

const _presets = [
  _StoryThemePreset(label: '勇敢冒险', emoji: '🗺️', color: Color(0xFFFF7B53), scenario: '踏上一段勇敢冒险的旅程'),
  _StoryThemePreset(label: '友谊互助', emoji: '🤝', color: Color(0xFFF76AA7), scenario: '朋友之间一起互相帮助'),
  _StoryThemePreset(label: '海底世界', emoji: '🌊', color: Color(0xFF1CBCE1), scenario: '探索神秘又温柔的海底世界'),
  _StoryThemePreset(label: '太空探索', emoji: '🚀', color: Color(0xFFA075F5), scenario: '去太空寻找发光的小秘密'),
  _StoryThemePreset(label: '魔法森林', emoji: '🌳', color: Color(0xFF17D67C), scenario: '在森林里遇见会说话的树和精灵'),
  _StoryThemePreset(label: '可爱动物', emoji: '🐰', color: Color(0xFFF9BF17), scenario: '和可爱动物们做朋友'),
];

@RoutePage()
class StoryComposerPage extends ConsumerStatefulWidget {
  const StoryComposerPage({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  ConsumerState<StoryComposerPage> createState() => _StoryComposerPageState();
}

class _StoryComposerPageState extends ConsumerState<StoryComposerPage> {
  final _customStoryController = TextEditingController();
  String? _selectedTheme;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _customStoryController.addListener(_onDraftChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(childControllerProvider.notifier).loadChildren();
      ref.read(voiceControllerProvider.notifier).loadVoices();
    });
  }

  @override
  void dispose() {
    _customStoryController.removeListener(_onDraftChanged);
    _customStoryController.dispose();
    super.dispose();
  }

  void _onDraftChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _ComposerBody(
      selectedTheme: _selectedTheme,
      customStoryController: _customStoryController,
      submitting: _submitting,
      onThemeSelected: (theme) {
        setState(() {
          _selectedTheme = theme;
          if (_customStoryController.text.trim().isEmpty) {
            final preset = _presets.firstWhere((item) => item.label == theme);
            _customStoryController.text = '请写一个关于${preset.label}的睡前故事，${preset.scenario}。';
          }
        });
      },
      onSubmit: _canSubmit() ? _submit : null,
    );

    if (widget.embedded) {
      return child;
    }

    return JoyfishScaffold(child: child);
  }

  bool _canSubmit() {
    return _selectedTheme != null || _customStoryController.text.trim().isNotEmpty;
  }

  Future<void> _submit() async {
    final selectedChild = ref.read(selectedChildProvider);
    if (selectedChild == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先选择一个小朋友档案')),
        );
        context.router.push(const ChildProfileRoute());
      }
      return;
    }

    setState(() => _submitting = true);
    try {
      final preset = _selectedTheme == null
          ? null
          : _presets.firstWhere((item) => item.label == _selectedTheme);
      final voices = ref.read(voiceControllerProvider).items;
      final request = await ref.read(storyRepositoryProvider).createStoryRequest(
            childId: selectedChild.id,
            titleHint: _selectedTheme ?? '定制睡前故事',
            scenario: preset?.scenario ?? _customStoryController.text.trim(),
            timeOfDay: '睡前',
            themeTags: [
              if (_selectedTheme != null) _selectedTheme!,
              if (_customStoryController.text.trim().isNotEmpty) '自定义故事',
            ],
            voiceRole: voices.isEmpty ? null : voices.first.role,
          );
      if (!mounted) return;
      context.router.push(StoryGeneratingRoute(requestId: request.id));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _ComposerBody extends ConsumerWidget {
  const _ComposerBody({
    required this.selectedTheme,
    required this.customStoryController,
    required this.submitting,
    required this.onThemeSelected,
    required this.onSubmit,
  });

  final String? selectedTheme;
  final TextEditingController customStoryController;
  final bool submitting;
  final ValueChanged<String> onThemeSelected;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChild = ref.watch(selectedChildProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 140.h),
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome_outlined, color: AppTheme.purpleLight, size: 30.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Text('创作新故事', style: Theme.of(context).textTheme.displayMedium),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Text(
          '选择主题或输入您想要的故事',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.mutedInk,
                fontWeight: FontWeight.w500,
              ),
        ),
        if (selectedChild != null) ...[
          SizedBox(height: 16.h),
          Text(
            '当前小朋友：${selectedChild.nickname}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.purple,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
        SizedBox(height: 28.h),
        Text('推荐主题', style: Theme.of(context).textTheme.headlineLarge),
        SizedBox(height: 18.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _presets.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 18.h,
            mainAxisExtent: 156.h,
          ),
          itemBuilder: (context, index) {
            final item = _presets[index];
            final selected = item.label == selectedTheme;
            return InkWell(
              onTap: () => onThemeSelected(item.label),
              borderRadius: BorderRadius.circular(26.r),
              child: JoyfishCard(
                border: selected
                    ? Border.all(color: AppTheme.purpleLight, width: 2)
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 84.w,
                      height: 72.w,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      alignment: Alignment.center,
                      child: Text(item.emoji, style: TextStyle(fontSize: 34.sp)),
                    ),
                    SizedBox(height: 18.h),
                    Text(item.label, style: Theme.of(context).textTheme.headlineLarge),
                  ],
                ),
              ),
            );
          },
        ),
        SizedBox(height: 26.h),
        Row(
          children: [
            const Expanded(child: Divider(color: AppTheme.softStroke)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                '或者',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.mutedInk),
              ),
            ),
            const Expanded(child: Divider(color: AppTheme.softStroke)),
          ],
        ),
        SizedBox(height: 26.h),
        Text('自定义故事', style: Theme.of(context).textTheme.headlineLarge),
        SizedBox(height: 14.h),
        TextField(
          controller: customStoryController,
          minLines: 4,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: '描述您想要的故事，例如：一只小兔子学习分享的故事...',
          ),
        ),
        SizedBox(height: 18.h),
        AppButton(
          text: '开始创作故事',
          isLoading: submitting,
          gradient: const LinearGradient(
            colors: [Color(0xFFF5D4DB), Color(0xFFEFDAE5)],
          ),
          textColor: Colors.white.withValues(alpha: 0.96),
          onPressed: onSubmit,
          icon: const Icon(Icons.auto_awesome_outlined, color: Colors.white),
        ),
      ],
    );
  }
}
