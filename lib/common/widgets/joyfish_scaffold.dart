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
    final content = Container(
      decoration: const BoxDecoration(color: AppTheme.cream),
      child: Stack(
        children: [
          Positioned(
            left: -60.w,
            right: -60.w,
            bottom: bottomNavigationBar == null ? -28.h : 70.h,
            child: Container(
              height: 112.h,
              decoration: BoxDecoration(
                color: const Color(0x24D4CDBD),
                borderRadius: BorderRadius.vertical(
                  top: Radius.elliptical(280.w, 42.h),
                ),
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
        border: border ?? Border.all(color: const Color(0xFFD8D0BD), width: 2),
        boxShadow: shadow ??
            const [
              BoxShadow(
                color: Color(0x33716B5D),
                blurRadius: 0,
                offset: Offset(5, 7),
              ),
            ],
      ),
      child: child,
    );
  }
}
