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
  _StoryThemePreset(
      label: '勇敢冒险',
      emoji: '🗺️',
      color: Color(0xFFFF7B53),
      scenario: '踏上一段勇敢冒险的旅程'),
  _StoryThemePreset(
      label: '友谊互助',
      emoji: '🤝',
      color: Color(0xFFF76AA7),
      scenario: '朋友之间一起互相帮助'),
  _StoryThemePreset(
      label: '海底世界',
      emoji: '🌊',
      color: Color(0xFF1CBCE1),
      scenario: '探索神秘又温柔的海底世界'),
  _StoryThemePreset(
      label: '太空探索',
      emoji: '🚀',
      color: Color(0xFFA075F5),
      scenario: '去太空寻找发光的小秘密'),
  _StoryThemePreset(
      label: '魔法森林',
      emoji: '🌳',
      color: Color(0xFF17D67C),
      scenario: '在森林里遇见会说话的树和精灵'),
  _StoryThemePreset(
      label: '可爱动物',
      emoji: '🐰',
      color: Color(0xFFF9BF17),
      scenario: '和可爱动物们做朋友'),
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
            _customStoryController.text =
                '请写一个关于${preset.label}的睡前故事，${preset.scenario}。';
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
    return _selectedTheme != null ||
        _customStoryController.text.trim().isNotEmpty;
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
      final request = await ref
          .read(storyRepositoryProvider)
          .createStoryRequest(
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
      padding: EdgeInsets.fromLTRB(22.w, 12.h, 22.w, 140.h),
      children: [
        const _ComposerTopBar(),
        SizedBox(height: 28.h),
        const _StepDots(),
        SizedBox(height: 28.h),
        _BlockTitle(icon: Icons.pets_rounded, title: '选择你的主角'),
        SizedBox(height: 14.h),
        _HeroChoice(
          title: selectedChild == null ? '小兔子' : selectedChild.nickname,
          icon: Icons.cruelty_free_rounded,
          selected: true,
          onTap: () {},
        ),
        SizedBox(height: 14.h),
        _HeroChoice(
          title: '大狮子',
          icon: Icons.local_florist_rounded,
          selected: false,
          onTap: () {},
        ),
        SizedBox(height: 28.h),
        _BlockTitle(icon: Icons.landscape_rounded, title: '选择故事场景'),
        SizedBox(height: 14.h),
        ..._presets.take(3).map((item) {
          final selected = item.label == selectedTheme;
          return Padding(
            padding: EdgeInsets.only(bottom: 14.h),
            child: _SceneTile(
              preset: item,
              selected: selected,
              onTap: () => onThemeSelected(item.label),
            ),
          );
        }),
        SizedBox(height: 14.h),
        _BlockTitle(icon: Icons.auto_awesome_rounded, title: '故事主题'),
        SizedBox(height: 14.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: _presets.map((item) {
            final selected = item.label == selectedTheme;
            return _ThemeChip(
              label: item.label,
              selected: selected,
              onTap: () => onThemeSelected(item.label),
            );
          }).toList(),
        ),
        SizedBox(height: 22.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF3FFE8),
            borderRadius: BorderRadius.circular(26.r),
            border: Border.all(
              color: const Color(0xFF2F7D00),
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFF2F7D00)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'VIP Feature: 写下你的奇思妙想',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF2F7D00),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: customStoryController,
                minLines: 4,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: '例如：我想听一个关于会飞的小猫去月球吃蛋糕的故事...',
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 28.h),
        AppButton(
          text: '生成我的故事',
          isLoading: submitting,
          height: 72.h,
          backgroundColor: AppTheme.peach,
          textColor: AppTheme.ink,
          borderSide: const BorderSide(color: AppTheme.ink, width: 2.4),
          onPressed: onSubmit,
          icon: const Icon(Icons.auto_awesome_rounded, color: AppTheme.ink),
        ),
        if (selectedChild == null) ...[
          SizedBox(height: 14.h),
          Text(
            '还没有小朋友档案时，提交后会先引导创建档案。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _ComposerTopBar extends StatelessWidget {
  const _ComposerTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppTheme.purpleLight,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33716B5D), blurRadius: 0, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.home_rounded, color: Colors.white, size: 25.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Story Paradise',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Icon(Icons.account_circle_outlined, color: AppTheme.ink, size: 24.sp),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StepBadge(label: '1', active: true),
        _StepLine(active: true),
        _StepBadge(label: '2', active: false),
        _StepLine(active: false),
        _StepBadge(label: '3', active: false),
      ],
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24.w,
      height: 24.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppTheme.olive : AppTheme.purpleLight,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
              color: Color(0x33716B5D), blurRadius: 0, offset: Offset(2, 3)),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
            color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38.w,
      height: 4.h,
      margin: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: active ? AppTheme.peach : const Color(0xFFBFE3FF),
        borderRadius: BorderRadius.circular(99.r),
      ),
    );
  }
}

class _BlockTitle extends StatelessWidget {
  const _BlockTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.olive, size: 24.sp),
        SizedBox(width: 8.w),
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
      ],
    );
  }
}

class _HeroChoice extends StatelessWidget {
  const _HeroChoice({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 126.h,
        decoration: BoxDecoration(
          color: selected ? AppTheme.peach : Colors.white,
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(
              color: selected ? AppTheme.ink : const Color(0xFFD8D0BD),
              width: 2.4),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33716B5D), blurRadius: 0, offset: Offset(4, 6)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30.r,
              backgroundColor: selected
                  ? Colors.white.withValues(alpha: 0.45)
                  : AppTheme.leaf,
              child: Icon(icon, color: AppTheme.olive, size: 30.sp),
            ),
            SizedBox(height: 10.h),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _SceneTile extends StatelessWidget {
  const _SceneTile({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final _StoryThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 88.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              preset.color.withValues(alpha: 0.95),
              preset.color.withValues(alpha: 0.58)
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(26.r),
          border: Border.all(
              color: selected ? AppTheme.ink : Colors.white,
              width: selected ? 2.6 : 3),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33716B5D), blurRadius: 0, offset: Offset(4, 6)),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 20.w),
            Text(preset.emoji, style: TextStyle(fontSize: 34.sp)),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                preset.label,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
            ),
            if (selected)
              Padding(
                padding: EdgeInsets.only(right: 18.w),
                child:
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: selected ? AppTheme.peach : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
              color: selected ? AppTheme.ink : AppTheme.peach, width: 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.ink : AppTheme.olive,
            fontWeight: FontWeight.w900,
            fontSize: 13.sp,
          ),
        ),
      ),
    );
  }
}
