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
          colors: [Color(0xFFFFF7E8), Color(0xFFFFEBC3), Color(0xFFEAF7E0)],
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
                    const Color(0xFFFFC857).withValues(alpha: 0.26),
                    const Color(0xFFFF805D).withValues(alpha: 0.10),
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
                color: const Color(0xFFA9D66F).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(42.r),
              ),
            ),
          ),
          Positioned.fill(child: useSafeArea ? SafeArea(child: child) : child),
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
            border ?? Border.all(color: const Color(0xFFF0D8B2), width: 1.1),
        boxShadow:
            shadow ??
            const [
              BoxShadow(
                color: Color(0x18A96F2C),
                blurRadius: 24,
                offset: Offset(0, 12),
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
              width: 48.r,
              height: 48.r,
              child: Image.asset(
                'assets/images/joyfish_logo.png',
                fit: BoxFit.contain,
              ),
            ),
        SizedBox(width: 12.r),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.mutedInk,
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
          width: size ?? 44.r,
          height: size ?? 44.r,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9EF),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x140F172A),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: AppTheme.olive, size: 22.sp),
        ),
      ),
    );
  }
}
