import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/joyfish_scaffold.dart';
import '../../../core/router/app_router.dart';
import '../../auth/providers/session_providers.dart';
import '../../children/providers/child_providers.dart';
import '../../story/providers/story_providers.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({
    super.key,
    required this.onManageChildren,
    required this.onManageVoice,
  });

  final VoidCallback onManageChildren;
  final VoidCallback onManageVoice;

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _nightMode = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final childState = ref.watch(childControllerProvider);
    final storyState = ref.watch(storyLibraryControllerProvider);
    final phone = session.user?.phoneNumber ?? '未设置手机号';

    return ListView(
      padding: EdgeInsets.fromLTRB(26.w, 24.h, 26.w, 140.h),
      children: [
        JoyfishCard(
          radius: 30.r,
          padding: EdgeInsets.all(22.w),
          backgroundColor: Colors.transparent,
          shadow: const [
            BoxShadow(
              color: Color(0x24C7A4C9),
              blurRadius: 24,
              offset: Offset(0, 14),
            ),
          ],
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5D9BF0), Color(0xFFA86AFD)],
              ),
              borderRadius: BorderRadius.circular(30.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
            child: Row(
              children: [
                Container(
                  width: 72.w,
                  height: 72.w,
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset('assets/images/home_hero.svg'),
                ),
                SizedBox(width: 20.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_displayNameFromPhone(phone)}女士',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        _maskPhone(phone),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                      ),
                      SizedBox(height: 18.h),
                      Row(
                        children: [
                          _StatBlock(label: '故事总数', value: '${storyState.items.length}'),
                          SizedBox(width: 28.w),
                          _StatBlock(
                            label: '播放次数',
                            value: '${storyState.items.fold<int>(0, (sum, item) => sum + (item.readingMinutes ?? 6))}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 26.h),
        _SectionLabel(text: '账户信息'),
        SizedBox(height: 14.h),
        JoyfishCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _MenuTile(
                icon: Icons.person_outline_rounded,
                title: '个人资料',
                trailingText: '${_displayNameFromPhone(phone)}女士',
              ),
              const Divider(height: 1),
              _MenuTile(
                icon: Icons.child_care_outlined,
                title: '孩子管理',
                trailingText: '${childState.items.length}个小朋友',
                onTap: widget.onManageChildren,
              ),
            ],
          ),
        ),
        SizedBox(height: 22.h),
        _SectionLabel(text: '音频设置'),
        SizedBox(height: 14.h),
        JoyfishCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _MenuTile(
                icon: Icons.volume_up_outlined,
                title: '音色管理',
                trailingText: '已录制',
                onTap: widget.onManageVoice,
              ),
              const Divider(height: 1),
              const _MenuTile(
                icon: Icons.notifications_none_rounded,
                title: '定时提醒',
                trailingText: '晚上8:00',
              ),
            ],
          ),
        ),
        SizedBox(height: 22.h),
        _SectionLabel(text: '通用设置'),
        SizedBox(height: 14.h),
        JoyfishCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SwitchTile(
                icon: Icons.dark_mode_outlined,
                title: '夜间模式',
                value: _nightMode,
                onChanged: (value) => setState(() => _nightMode = value),
              ),
              const Divider(height: 1),
              const _MenuTile(
                icon: Icons.shield_outlined,
                title: '隐私设置',
              ),
              const Divider(height: 1),
              const _MenuTile(
                icon: Icons.help_outline_rounded,
                title: '帮助与反馈',
              ),
            ],
          ),
        ),
        SizedBox(height: 26.h),
        AppButton(
          text: '退出登录',
          backgroundColor: Colors.white,
          textColor: const Color(0xFFFF4D4D),
          icon: const Icon(Icons.logout_rounded, color: Color(0xFFFF4D4D)),
          onPressed: () async {
            await ref.read(sessionControllerProvider.notifier).logout();
            if (context.mounted) {
              context.router.replaceAll([const AuthRoute()]);
            }
          },
        ),
      ],
    );
  }

  String _maskPhone(String phone) {
    if (phone.length < 7) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 4)}';
  }

  String _displayNameFromPhone(String phone) {
    return '张';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: const Color(0xFF72778A),
          ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    this.trailingText,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppTheme.purpleLight),
      title: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.mutedInk),
            ),
          SizedBox(width: 6.w),
          Icon(Icons.chevron_right_rounded, color: AppTheme.mutedInk, size: 24.sp),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.purpleLight),
      title: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}
