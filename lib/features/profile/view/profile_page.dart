import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/widgets/app_button.dart';
import '../../../core/router/app_router.dart';
import '../../auth/providers/session_providers.dart';
import '../../children/providers/child_providers.dart';
import '../../story/providers/story_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({
    super.key,
    required this.onManageChildren,
    required this.onManageVoice,
  });

  final VoidCallback onManageChildren;
  final VoidCallback onManageVoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final childState = ref.watch(childControllerProvider);
    final storyState = ref.watch(storyLibraryControllerProvider);
    final phone = session.user?.phoneNumber ?? '未设置手机号';

    return ListView(
      padding: EdgeInsets.fromLTRB(22.w, 10.h, 22.w, 140.h),
      children: [
        const _VipTopBar(),
        SizedBox(height: 26.h),
        _StatusCard(phone: phone, storyCount: storyState.items.length),
        SizedBox(height: 22.h),
        _BenefitCard(
          title: '普通用户',
          color: const Color(0xFFE7E3DA),
          icon: Icons.person_outline_rounded,
          items: const ['每月 6 篇故事', '标准应用主题', '包含部分广告'],
          positive: false,
        ),
        SizedBox(height: 18.h),
        _BenefitCard(
          title: 'VIP 探索者',
          color: AppTheme.peach,
          icon: Icons.stars_rounded,
          items: const ['每月 60 篇故事', '专属梦幻主题', '全程无广告干扰'],
          positive: true,
        ),
        SizedBox(height: 28.h),
        Center(
          child: Text(
            '选择你的魔法计划',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppTheme.olive),
          ),
        ),
        SizedBox(height: 22.h),
        _PlanCard(
          icon: Icons.calendar_month_rounded,
          title: '连续包月会员',
          subtitle: '随时取消，轻松开启',
          price: '¥16',
          unit: '/月',
          button: '立即订阅',
          highlighted: false,
        ),
        SizedBox(height: 24.h),
        _PlanCard(
          icon: Icons.workspace_premium_rounded,
          title: '年度探险家会员',
          subtitle: '平均每月仅需 ¥12.5',
          price: '¥150',
          unit: '/年',
          button: '立即开启一整年',
          highlighted: true,
        ),
        SizedBox(height: 26.h),
        Row(
          children: [
            Expanded(
              child: _MiniAction(
                icon: Icons.child_care_rounded,
                title: '${childState.items.length} 个孩子',
                onTap: onManageChildren,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: _MiniAction(
                icon: Icons.record_voice_over_rounded,
                title: '音色管理',
                onTap: onManageVoice,
              ),
            ),
          ],
        ),
        SizedBox(height: 18.h),
        AppButton(
          text: '退出登录',
          backgroundColor: Colors.white,
          textColor: const Color(0xFFD23A3A),
          borderSide: const BorderSide(color: Color(0xFFD8D0BD), width: 2),
          icon: const Icon(Icons.logout_rounded, color: Color(0xFFD23A3A)),
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
}

class _VipTopBar extends StatelessWidget {
  const _VipTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppTheme.purpleLight,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33716B5D), blurRadius: 0, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.home_rounded, color: Colors.white, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Story Paradise',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1.5),
              borderRadius: BorderRadius.circular(99.r),
            ),
            child: Text('VIP 中心',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.phone, required this.storyCount});

  final String phone;
  final int storyCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color(0xFFDDEEFF),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33716B5D), blurRadius: 0, offset: Offset(5, 7)),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 92.w,
            height: 92.w,
            child: Image.asset(
              'assets/images/joyfish_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 14.h),
          Text('当前状态',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.skyDeep)),
          SizedBox(height: 8.h),
          Text('普通小读者', style: Theme.of(context).textTheme.headlineMedium),
          SizedBox(height: 8.h),
          Text(
            '${_maskPhone(phone)} · 已创作 $storyCount 篇故事',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.skyDeep),
          ),
          SizedBox(height: 20.h),
          Icon(Icons.emoji_events_rounded,
              color: Colors.white.withValues(alpha: 0.55), size: 58.sp),
        ],
      ),
    );
  }

  static String _maskPhone(String phone) {
    if (phone.length < 7) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 4)}';
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.title,
    required this.color,
    required this.icon,
    required this.items,
    required this.positive,
  });

  final String title;
  final Color color;
  final IconData icon;
  final List<String> items;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33716B5D), blurRadius: 0, offset: Offset(4, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(icon,
                    color: positive ? AppTheme.olive : AppTheme.mutedInk),
              ),
              SizedBox(width: 14.w),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
          SizedBox(height: 14.h),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 9.h),
              child: Row(
                children: [
                  Icon(
                    positive
                        ? Icons.check_circle_outline_rounded
                        : Icons.close_rounded,
                    color: positive
                        ? const Color(0xFF2F7D00)
                        : const Color(0xFFD23A3A),
                    size: 18.sp,
                  ),
                  SizedBox(width: 10.w),
                  Text(item, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.unit,
    required this.button,
    required this.highlighted,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final String unit;
  final String button;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: highlighted ? AppTheme.peach : Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        border:
            highlighted ? Border.all(color: AppTheme.olive, width: 2.4) : null,
        boxShadow: const [
          BoxShadow(
              color: Color(0x33716B5D), blurRadius: 0, offset: Offset(4, 7)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.skyDeep, size: 34.sp),
          SizedBox(height: 14.h),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          SizedBox(height: 6.h),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          SizedBox(height: 24.h),
          RichText(
            text: TextSpan(
              text: price,
              style: TextStyle(
                  color: AppTheme.olive,
                  fontSize: 34.sp,
                  fontWeight: FontWeight.w900),
              children: [
                TextSpan(
                  text: unit,
                  style:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          AppButton(
            text: button,
            height: 54.h,
            backgroundColor:
                highlighted ? AppTheme.olive : AppTheme.purpleLight,
            textColor: highlighted ? Colors.white : AppTheme.skyDeep,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction(
      {required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: const Color(0xFFD8D0BD), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.skyDeep),
            SizedBox(height: 8.h),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
