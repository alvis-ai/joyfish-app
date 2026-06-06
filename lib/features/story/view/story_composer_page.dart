import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/joyfish_scaffold.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../auth/providers/session_providers.dart';
import '../../children/providers/child_providers.dart';
import '../../voice/providers/voice_providers.dart';
import '../providers/story_providers.dart';

class _StoryCharacterPreset {
  const _StoryCharacterPreset({
    required this.label,
    required this.emoji,
    required this.description,
    required this.color,
  });

  final String label;
  final String emoji;
  final String description;
  final Color color;
}

class _StoryScenePreset {
  const _StoryScenePreset({
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

class _StoryTopicPreset {
  const _StoryTopicPreset({
    required this.label,
    required this.emoji,
    required this.instruction,
  });

  final String label;
  final String emoji;
  final String instruction;
}

const _characters = [
  _StoryCharacterPreset(
    label: '小兔子',
    emoji: '🐰',
    description: '好奇、温柔，喜欢发现小秘密',
    color: Color(0xFFFFD84D),
  ),
  _StoryCharacterPreset(
    label: '小海豚',
    emoji: '🐬',
    description: '活泼、聪明，擅长帮助朋友',
    color: Color(0xFF48C8E8),
  ),
  _StoryCharacterPreset(
    label: '小宇航员',
    emoji: '🚀',
    description: '勇敢、爱探索，想去星星上旅行',
    color: Color(0xFF8F7AF8),
  ),
  _StoryCharacterPreset(
    label: '小狐狸',
    emoji: '🦊',
    description: '机灵、善良，喜欢解开谜题',
    color: Color(0xFFFF9A4D),
  ),
  _StoryCharacterPreset(
    label: '小猫咪',
    emoji: '🐱',
    description: '软萌、胆小但愿意尝试',
    color: Color(0xFFFF7EA8),
  ),
  _StoryCharacterPreset(
    label: '小机器人',
    emoji: '🤖',
    description: '认真、有礼貌，正在学习情绪',
    color: Color(0xFF73D879),
  ),
];

const _scenes = [
  _StoryScenePreset(
    label: '海底世界',
    emoji: '🌊',
    color: Color(0xFF1CBCE1),
    scenario: '探索神秘又温柔的海底世界',
  ),
  _StoryScenePreset(
    label: '太空探索',
    emoji: '🚀',
    color: Color(0xFFA075F5),
    scenario: '去太空寻找发光的小秘密',
  ),
  _StoryScenePreset(
    label: '魔法森林',
    emoji: '🌳',
    color: Color(0xFF17D67C),
    scenario: '在森林里遇见会说话的树和精灵',
  ),
  _StoryScenePreset(
    label: '云朵城堡',
    emoji: '☁️',
    color: Color(0xFFF9BF17),
    scenario: '走进软软的云朵城堡寻找彩虹门',
  ),
];

const _topics = [
  _StoryTopicPreset(
    label: '勇敢冒险',
    emoji: '🗺️',
    instruction: '让主角学会勇敢尝试，同时保持安全感',
  ),
  _StoryTopicPreset(
    label: '友谊互助',
    emoji: '🤝',
    instruction: '讲述朋友之间理解、合作和互相帮助',
  ),
  _StoryTopicPreset(label: '睡前安抚', emoji: '🌙', instruction: '语气温柔放松，适合睡前慢慢听'),
  _StoryTopicPreset(label: '好奇探索', emoji: '🔍', instruction: '鼓励观察、提问和发现世界的奥秘'),
  _StoryTopicPreset(
    label: '情绪成长',
    emoji: '💛',
    instruction: '帮助主角认识情绪，并学会表达和调整',
  ),
  _StoryTopicPreset(
    label: '习惯养成',
    emoji: '⭐',
    instruction: '把收拾、刷牙、分享等习惯自然融入故事',
  ),
];

@RoutePage()
class StoryComposerPage extends ConsumerStatefulWidget {
  const StoryComposerPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<StoryComposerPage> createState() => _StoryComposerPageState();
}

class _StoryComposerPageState extends ConsumerState<StoryComposerPage> {
  final _customStoryController = TextEditingController();
  String _selectedCharacter = _characters.first.label;
  String _selectedScene = _scenes.first.label;
  String _selectedTheme = _topics.first.label;
  int _characterCount = 1;
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
    final canUseCustomPrompt =
        ref.watch(sessionControllerProvider).user?.canUseCustomStoryPrompt ??
        false;
    final child = _ComposerBody(
      selectedCharacter: _selectedCharacter,
      selectedScene: _selectedScene,
      selectedTheme: _selectedTheme,
      characterCount: _characterCount,
      canUseCustomPrompt: canUseCustomPrompt,
      customStoryController: _customStoryController,
      submitting: _submitting,
      onCharacterSelected: (character) {
        setState(() => _selectedCharacter = character);
      },
      onSceneSelected: (scene) {
        setState(() => _selectedScene = scene);
      },
      onThemeSelected: (theme) {
        setState(() => _selectedTheme = theme);
      },
      onCharacterCountChanged: (count) {
        setState(() => _characterCount = count);
      },
      onSubmit: _canSubmit() ? _submit : null,
    );

    if (widget.embedded) {
      return child;
    }

    return JoyfishScaffold(child: child);
  }

  bool _canSubmit() {
    return _selectedCharacter.isNotEmpty &&
        _selectedScene.isNotEmpty &&
        _selectedTheme.isNotEmpty;
  }

  Future<void> _submit() async {
    final selectedChild = ref.read(selectedChildProvider);
    if (selectedChild == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请先选择一个小朋友档案')));
        context.router.push(const ChildProfileRoute());
      }
      return;
    }

    setState(() => _submitting = true);
    try {
      final character = _characters.firstWhere(
        (item) => item.label == _selectedCharacter,
      );
      final scene = _scenes.firstWhere((item) => item.label == _selectedScene);
      final topic = _topics.firstWhere((item) => item.label == _selectedTheme);
      final canUseCustomPrompt =
          ref.read(sessionControllerProvider).user?.canUseCustomStoryPrompt ??
          false;
      final customPrompt = canUseCustomPrompt
          ? _customStoryController.text.trim()
          : '';
      final voices = ref.read(voiceControllerProvider).items;
      final request = await ref
          .read(storyRepositoryProvider)
          .createStoryRequest(
            childId: selectedChild.id,
            titleHint: '${topic.label}故事',
            scenario: [
              '主角是$_characterCount个${character.label}，${character.description}。',
              scene.scenario,
              topic.instruction,
              if (customPrompt.isNotEmpty) customPrompt,
            ].join(' '),
            timeOfDay: '睡前',
            characters: {
              'count': _characterCount,
              'items': [
                {'name': character.label, 'description': character.description},
              ],
            },
            themeTags: [
              character.label,
              scene.label,
              topic.label,
              if (customPrompt.isNotEmpty) '自定义故事',
            ],
            voiceRole: voices.isEmpty ? null : voices.first.role,
          );
      if (!mounted) return;
      await context.router.push(StoryGeneratingRoute(requestId: request.id));
      await ref
          .read(storyLibraryControllerProvider.notifier)
          .loadStories(force: true);
      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(userFacingErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _ComposerBody extends ConsumerWidget {
  const _ComposerBody({
    required this.selectedCharacter,
    required this.selectedScene,
    required this.selectedTheme,
    required this.characterCount,
    required this.canUseCustomPrompt,
    required this.customStoryController,
    required this.submitting,
    required this.onCharacterSelected,
    required this.onSceneSelected,
    required this.onThemeSelected,
    required this.onCharacterCountChanged,
    required this.onSubmit,
  });

  final String selectedCharacter;
  final String selectedScene;
  final String selectedTheme;
  final int characterCount;
  final bool canUseCustomPrompt;
  final TextEditingController customStoryController;
  final bool submitting;
  final ValueChanged<String> onCharacterSelected;
  final ValueChanged<String> onSceneSelected;
  final ValueChanged<String> onThemeSelected;
  final ValueChanged<int> onCharacterCountChanged;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChild = ref.watch(selectedChildProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(22.w, 8.h, 22.w, 40.h),
      children: [
        JoyfishPageHeader(
          title: '你想听什么故事？',
          subtitle: selectedChild == null
              ? '先选故事模板，提交时会引导创建孩子档案'
              : '为${selectedChild.nickname}定制今晚的小冒险',
          trailing: JoyfishIconBubble(
            icon: Icons.auto_awesome_rounded,
            onTap: () {},
          ),
        ),
        SizedBox(height: 22.h),
        _ChildStoryPrompt(childName: selectedChild?.nickname ?? '小朋友'),
        SizedBox(height: 24.h),
        _BlockTitle(icon: Icons.landscape_rounded, title: 'Ta 今天的梦境主题是'),
        SizedBox(height: 14.h),
        GridView.builder(
          itemCount: _scenes.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 112.h,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
          ),
          itemBuilder: (context, index) {
            final item = _scenes[index];
            final selected = item.label == selectedScene;
            return _SceneTile(
              preset: item,
              selected: selected,
              onTap: () => onSceneSelected(item.label),
            );
          },
        ),
        SizedBox(height: 24.h),
        _BlockTitle(icon: Icons.pets_rounded, title: '有这些伙伴在 Ta 身边'),
        SizedBox(height: 14.h),
        _CharacterGrid(
          selectedCharacter: selectedCharacter,
          onSelected: onCharacterSelected,
        ),
        SizedBox(height: 18.h),
        _CharacterCountSelector(
          value: characterCount,
          onChanged: onCharacterCountChanged,
        ),
        SizedBox(height: 24.h),
        _BlockTitle(icon: Icons.auto_awesome_rounded, title: '故事里想学会什么？'),
        SizedBox(height: 14.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: _topics.map((item) {
            final selected = item.label == selectedTheme;
            return _ThemeChip(
              emoji: item.emoji,
              label: item.label,
              selected: selected,
              onTap: () => onThemeSelected(item.label),
            );
          }).toList(),
        ),
        if (canUseCustomPrompt) ...[
          SizedBox(height: 22.h),
          JoyfishCard(
            padding: EdgeInsets.all(16.w),
            backgroundColor: const Color(0xFFF3FFE8),
            border: Border.all(color: const Color(0xFF9AD96C), width: 1.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFF2F7D00)),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        '写下你的奇思妙想',
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
        ],
        SizedBox(height: 24.h),
        AppButton(
          text: '开启故事',
          isLoading: submitting,
          height: 64.h,
          backgroundColor: AppTheme.skyDeep,
          textColor: Colors.white,
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.42),
            width: 1.2,
          ),
          onPressed: onSubmit,
          icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
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

class _ChildStoryPrompt extends StatelessWidget {
  const _ChildStoryPrompt({required this.childName});

  final String childName;

  @override
  Widget build(BuildContext context) {
    return JoyfishCard(
      padding: EdgeInsets.all(18.w),
      backgroundColor: Colors.white.withValues(alpha: 0.62),
      border: Border.all(color: Colors.white.withValues(alpha: 0.44)),
      child: Row(
        children: [
          Container(
            width: 54.w,
            height: 54.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD777), Color(0xFFFF8E68)],
              ),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              Icons.nightlight_round,
              color: Colors.white,
              size: 26.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              '$childName 的故事由主题、伙伴和成长愿望组成',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.olive,
                fontWeight: FontWeight.w900,
                height: 1.35,
              ),
            ),
          ),
        ],
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
        Icon(icon, color: AppTheme.olive, size: 24.r),
        SizedBox(width: 8.r),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ),
      ],
    );
  }
}

class _CharacterGrid extends StatelessWidget {
  const _CharacterGrid({
    required this.selectedCharacter,
    required this.onSelected,
  });

  final String selectedCharacter;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _characters.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        mainAxisExtent: 126.h,
      ),
      itemBuilder: (context, index) {
        final character = _characters[index];
        final selected = character.label == selectedCharacter;
        return _CharacterChoice(
          character: character,
          selected: selected,
          onTap: () => onSelected(character.label),
        );
      },
    );
  }
}

class _CharacterChoice extends StatelessWidget {
  const _CharacterChoice({
    required this.character,
    required this.selected,
    required this.onTap,
  });

  final _StoryCharacterPreset character;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: Ink(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: selected ? character.color : Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: selected ? Colors.white : const Color(0xFFF0EBF8),
              width: selected ? 2.4 : 1.4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(character.emoji, style: TextStyle(fontSize: 30.sp)),
                SizedBox(height: 8.r),
                Text(
                  character.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: selected ? Colors.white : AppTheme.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4.r),
                SizedBox(
                  width: 126.r,
                  child: Text(
                    character.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.88)
                          : AppTheme.mutedInk,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterCountSelector extends StatelessWidget {
  const _CharacterCountSelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return JoyfishCard(
      padding: EdgeInsets.symmetric(horizontal: 14.r, vertical: 12.r),
      child: Row(
        children: [
          Icon(Icons.group_rounded, color: AppTheme.olive, size: 22.r),
          SizedBox(width: 10.r),
          Expanded(
            child: Text(
              '角色数量',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          ...[1, 2, 3].map(
            (count) => Padding(
              padding: EdgeInsets.only(left: 8.r),
              child: _CountPill(
                label: '$count',
                selected: count == value,
                onTap: () => onChanged(count),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        width: 42.r,
        height: 34.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppTheme.peach : const Color(0xFFF7F4FB),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: selected ? AppTheme.ink : const Color(0xFFE9E3F2),
            width: selected ? 1.8 : 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.ink : AppTheme.mutedInk,
            fontWeight: FontWeight.w900,
          ),
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

  final _StoryScenePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              preset.color.withValues(alpha: 0.95),
              preset.color.withValues(alpha: 0.62),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(26.r),
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.7),
            width: selected ? 2.6 : 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              child: Text(preset.emoji, style: TextStyle(fontSize: 34.sp)),
            ),
            Positioned(
              left: 0,
              right: 8.w,
              bottom: 0,
              child: Text(
                preset.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  shadows: const [
                    Shadow(color: Color(0x33000000), blurRadius: 8),
                  ],
                ),
              ),
            ),
            if (selected)
              const Positioned(
                left: 0,
                top: 0,
                child: Icon(Icons.check_circle_rounded, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
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
          color: selected ? const Color(0xFFFFE18D) : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected ? const Color(0xFFFFD45A) : const Color(0xFFF0EBF8),
            width: 1.4,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D0F172A),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: 14.sp)),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppTheme.ink : AppTheme.olive,
                fontWeight: FontWeight.w900,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
