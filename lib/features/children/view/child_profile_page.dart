import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/joyfish_scaffold.dart';
import '../models/child_profile.dart';
import '../providers/child_providers.dart';

@RoutePage()
class ChildProfilePage extends ConsumerStatefulWidget {
  const ChildProfilePage({super.key});

  @override
  ConsumerState<ChildProfilePage> createState() => _ChildProfilePageState();
}

class _ChildProfilePageState extends ConsumerState<ChildProfilePage> {
  final _nicknameController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _themeController = TextEditingController();
  String? _gender;
  bool _showCreateForm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(childControllerProvider.notifier).loadChildren();
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _birthdateController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(childControllerProvider);
    final notifier = ref.read(childControllerProvider.notifier);

    return JoyfishScaffold(
      child: ListView(
        padding: EdgeInsets.fromLTRB(24.w, 22.h, 24.w, 30.h),
        children: [
          Row(
            children: [
              Icon(Icons.child_care_outlined, color: AppTheme.purpleLight, size: 28.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text('选择小朋友', style: Theme.of(context).textTheme.displayMedium),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            '请选择或创建小朋友档案',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.mutedInk,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 28.h),
          ...state.items.map(
            (child) => Padding(
              padding: EdgeInsets.only(bottom: 18.h),
                child: _ChildCard(
                child: child,
                active: state.selectedChildId == child.id,
                onTap: () async {
                  final router = context.router;
                  await notifier.selectChild(child);
                  if (!mounted) return;
                  router.popForced();
                },
              ),
            ),
          ),
          if (state.items.isEmpty)
            JoyfishCard(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 18.h),
                child: Text(
                  '还没有孩子档案，先创建一个吧。',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          SizedBox(height: 18.h),
          InkWell(
            onTap: () => setState(() => _showCreateForm = !_showCreateForm),
            borderRadius: BorderRadius.circular(26.r),
            child: JoyfishCard(
              border: Border.all(
                color: AppTheme.pageLavender,
                width: 2,
                style: BorderStyle.solid,
              ),
              backgroundColor: Colors.white.withValues(alpha: 0.42),
              child: SizedBox(
                height: 66.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('+', style: TextStyle(fontSize: 30.sp, color: AppTheme.purpleLight)),
                    SizedBox(width: 12.w),
                    Text(
                      '添加新的小朋友',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.purpleLight,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showCreateForm) ...[
            SizedBox(height: 18.h),
            JoyfishCard(
              child: Column(
                children: [
                  TextField(
                    controller: _nicknameController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(hintText: '昵称，例如 小明、小美'),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _birthdateController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(hintText: '生日 YYYY-MM-DD'),
                  ),
                  SizedBox(height: 12.h),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_gender),
                    initialValue: _gender,
                    decoration: const InputDecoration(hintText: '选择性别'),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('男孩')),
                      DropdownMenuItem(value: 'female', child: Text('女孩')),
                      DropdownMenuItem(value: 'other', child: Text('暂不选择')),
                    ],
                    onChanged: (value) => setState(() => _gender = value),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: _themeController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(hintText: '喜欢的主题，例如 海洋、森林'),
                  ),
                  SizedBox(height: 18.h),
                  AppButton(
                    text: '保存并使用',
                    isLoading: state.isSubmitting,
                        onPressed: _nicknameController.text.trim().isEmpty
                        ? null
                        : () async {
                            final router = context.router;
                            await notifier.createChild(
                              nickname: _nicknameController.text.trim(),
                              birthdate: _birthdateController.text.trim().isEmpty
                                  ? null
                                  : _birthdateController.text.trim(),
                              gender: _gender,
                              preferences: _themeController.text.trim().isEmpty
                                  ? null
                                  : {'favorite_theme': _themeController.text.trim()},
                            );
                            final latest = ref.read(childControllerProvider);
                            if (!mounted) return;
                            if (latest.error == null) {
                              setState(() => _showCreateForm = false);
                              router.popForced();
                            }
                          },
                  ),
                ],
              ),
            ),
          ],
          if (state.error != null) ...[
            SizedBox(height: 12.h),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.child,
    required this.active,
    required this.onTap,
  });

  final ChildProfile child;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28.r),
        child: JoyfishCard(
          child: Row(
            children: [
              Container(
                width: 66.w,
                height: 66.w,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF6EAEF7), Color(0xFF9A6BF7)],
                  ),
                ),
                child: Text(
                  child.gender == 'female' || child.gender == 'girl'
                      ? '👧'
                      : '🧒',
                  style: TextStyle(fontSize: 34.sp),
                ),
              ),
              SizedBox(width: 18.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.nickname, style: Theme.of(context).textTheme.headlineLarge),
                    SizedBox(height: 6.h),
                    Text(
                      _ageText(child.birthdate),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppTheme.mutedInk,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                active ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
                color: active ? AppTheme.purpleLight : AppTheme.mutedInk,
                size: active ? 28.sp : 18.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ageText(String? birthdate) {
    if (birthdate == null || birthdate.isEmpty) return '未填写年龄';
    final date = DateTime.tryParse(birthdate);
    if (date == null) return birthdate;
    final now = DateTime.now();
    var age = now.year - date.year;
    if (DateTime(now.year, date.month, date.day).isAfter(now)) {
      age -= 1;
    }
    return '$age 岁';
  }
}
