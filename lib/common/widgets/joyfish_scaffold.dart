import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../themes/app_theme.dart';

class JoyfishScaffold extends StatelessWidget {
  const JoyfishScaffold({
    super.key,
    required this.child,
    this.bottomNavigationBar,
    this.useSafeArea = true,
  });

  final Widget child;
  final Widget? bottomNavigationBar;
  final bool useSafeArea;

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8F7FC),
            Color(0xFFF2F0FB),
            Color(0xFFFFF8EE),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -80.w,
            right: -80.w,
            top: -120.h,
            child: Container(
              height: 220.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF7357F6).withValues(alpha: 0.12),
                    const Color(0xFFFFC53D).withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.elliptical(320.w, 120.h),
                ),
              ),
            ),
          ),
          Positioned(
            right: -30.w,
            top: 120.h,
            child: Container(
              width: 140.w,
              height: 140.w,
              decoration: BoxDecoration(
                color: const Color(0xFFFF7E9D).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(42.r),
              ),
            ),
          ),
          Positioned.fill(
            child: useSafeArea ? SafeArea(child: child) : child,
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.cream,
      extendBody: true,
      body: content,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class JoyfishCard extends StatelessWidget {
  const JoyfishCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.border,
    this.backgroundColor,
    this.shadow,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final Border? border;
  final Color? backgroundColor;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(radius ?? 26.r),
        border:
            border ?? Border.all(color: const Color(0xFFF1EDF7), width: 1.4),
        boxShadow: shadow ??
            const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
      ),
      child: child,
    );
  }
}

class JoyfishPageHeader extends StatelessWidget {
  const JoyfishPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        leading ??
            SizedBox(
              width: 48.w,
              height: 48.w,
              child: Image.asset(
                'assets/images/joyfish_logo.png',
                fit: BoxFit.contain,
              ),
            ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: const Color(0xFF2E3445),
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(
                  color: const Color(0xFF778197),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class JoyfishIconBubble extends StatelessWidget {
  const JoyfishIconBubble({
    super.key,
    required this.icon,
    required this.onTap,
    this.size,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: Ink(
          width: size ?? 44.w,
          height: size ?? 44.w,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x140F172A),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF6F7A91), size: 22.sp),
        ),
      ),
    );
  }
}
