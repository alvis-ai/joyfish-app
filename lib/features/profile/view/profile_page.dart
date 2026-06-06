import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/themes/app_theme.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/joyfish_scaffold.dart';
import '../../../core/router/app_router.dart';
import '../../auth/providers/session_providers.dart';
import '../../children/providers/child_providers.dart';
import '../providers/subscription_providers.dart';
import '../../story/providers/story_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({
    super.key,
    required this.onManageChildren,
    required this.onManageVoice,
    this.sheetMode = false,
  });

  final VoidCallback onManageChildren;
  final VoidCallback onManageVoice;
  final bool sheetMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final childState = ref.watch(childControllerProvider);
    final storyState = ref.watch(storyLibraryControllerProvider);
    final subscriptionState = ref.watch(subscriptionControllerProvider);
    final phone = session.user?.phoneNumber ?? '未设置手机号';
    final isVip = session.user?.hasActiveMembership == true;
    final monthlyProduct = subscriptionState.products[joyfishMonthlyProductId];
    final annualProduct = subscriptionState.products[joyfishAnnualProductId];

    ref.listen(subscriptionControllerProvider, (previous, next) {
      final messenger = ScaffoldMessenger.of(context);
      final error = next.error;
      final message = next.message;
      if (error != null && error != previous?.error) {
        messenger.showSnackBar(SnackBar(content: Text(error)));
      } else if (message != null && message != previous?.message) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return ListView(
      padding: EdgeInsets.fromLTRB(
        22.w,
        sheetMode ? 6.h : 10.h,
        22.w,
        sheetMode ? 36.h : 140.h,
      ),
      children: [
        JoyfishPageHeader(
          title: '会员中心',
          subtitle: '管理故事额度、孩子档案和会员权益',
          trailing: JoyfishIconBubble(
            icon: Icons.refresh_rounded,
            onTap: () => ref
                .read(subscriptionControllerProvider.notifier)
                .loadProducts(),
          ),
        ),
        SizedBox(height: 26.h),
        _StatusCard(
          phone: phone,
          storyCount: storyState.items.length,
          isVip: isVip,
          membershipTier: session.user?.membershipTier ?? 'free',
          expiresAt: session.user?.membershipExpiresAt,
        ),
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
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.olive),
          ),
        ),
        SizedBox(height: 22.h),
        _PlanCard(
          icon: Icons.calendar_month_rounded,
          title: '连续包月会员',
          subtitle: '随时取消，轻松开启',
          price: monthlyProduct?.price ?? '¥12',
          unit: '/月',
          button: isVip ? '续订包月' : '立即订阅',
          highlighted: false,
          isLoading: subscriptionState.purchasing,
          onPressed: subscriptionState.storeAvailable
              ? () => ref
                    .read(subscriptionControllerProvider.notifier)
                    .buy(joyfishMonthlyProductId)
              : null,
        ),
        SizedBox(height: 24.h),
        _PlanCard(
          icon: Icons.workspace_premium_rounded,
          title: '年度探险家会员',
          subtitle: '平均每月仅需 ¥8.2',
          price: annualProduct?.price ?? '¥98',
          unit: '/年',
          button: '立即开启一整年',
          highlighted: true,
          isLoading: subscriptionState.purchasing,
          onPressed: subscriptionState.storeAvailable
              ? () => ref
                    .read(subscriptionControllerProvider.notifier)
                    .buy(joyfishAnnualProductId)
              : null,
        ),
        SizedBox(height: 14.h),
        AppButton.secondary(
          text: subscriptionState.restoring ? '正在恢复购买...' : '恢复购买',
          height: 50.h,
          isLoading: subscriptionState.restoring,
          icon: const Icon(Icons.restore_rounded, color: AppTheme.skyDeep),
          onPressed: subscriptionState.storeAvailable
              ? () => ref
                    .read(subscriptionControllerProvider.notifier)
                    .restorePurchases()
              : null,
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
          borderSide: const BorderSide(color: Color(0xFFF0EBF8), width: 1.4),
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.phone,
    required this.storyCount,
    required this.isVip,
    required this.membershipTier,
    required this.expiresAt,
  });

  final String phone;
  final int storyCount;
  final bool isVip;
  final String membershipTier;
  final DateTime? expiresAt;

  @override
  Widget build(BuildContext context) {
    return JoyfishCard(
      padding: EdgeInsets.all(24.w),
      backgroundColor: const Color(0xFFEAF2FF),
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
          Text(
            '当前状态',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.skyDeep),
          ),
          SizedBox(height: 8.h),
          Text(
            isVip ? _tierLabel(membershipTier) : '普通小读者',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 8.h),
          Text(
            '${_maskPhone(phone)} · 已创作 $storyCount 篇故事${_expiryLabel()}',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.skyDeep),
          ),
          SizedBox(height: 20.h),
          Icon(
            Icons.emoji_events_rounded,
            color: const Color(0xFFB7C6EE),
            size: 58.sp,
          ),
        ],
      ),
    );
  }

  static String _maskPhone(String phone) {
    if (phone.length < 7) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 4)}';
  }

  String _expiryLabel() {
    final value = expiresAt;
    if (!isVip || value == null) {
      return '';
    }
    return ' · 有效期至 ${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';
  }

  static String _tierLabel(String tier) {
    switch (tier.trim().toLowerCase()) {
      case 'monthly':
        return '连续包月会员';
      case 'annual':
      case 'yearly':
        return '年度探险家会员';
      default:
        return 'VIP 探索者';
    }
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
    return JoyfishCard(
      padding: EdgeInsets.all(22.w),
      backgroundColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  icon,
                  color: positive ? AppTheme.olive : AppTheme.mutedInk,
                ),
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
    required this.onPressed,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final String unit;
  final String button;
  final bool highlighted;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return JoyfishCard(
      padding: EdgeInsets.all(24.w),
      backgroundColor: highlighted ? const Color(0xFFFFE087) : Colors.white,
      border: Border.all(
        color: highlighted ? const Color(0xFFFFD45A) : const Color(0xFFF0EBF8),
        width: 1.4,
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
                fontWeight: FontWeight.w900,
              ),
              children: [
                TextSpan(
                  text: unit,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          AppButton(
            text: button,
            height: 54.h,
            isLoading: isLoading,
            backgroundColor: highlighted
                ? AppTheme.olive
                : AppTheme.purpleLight,
            textColor: highlighted ? Colors.white : AppTheme.skyDeep,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: JoyfishCard(
        padding: EdgeInsets.symmetric(vertical: 16.h),
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
