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
      decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
      child: Stack(
        children: [
          Positioned(
            left: -40.w,
            right: -40.w,
            bottom: bottomNavigationBar == null ? -16.h : 64.h,
            child: Container(
              height: 110.h,
              decoration: BoxDecoration(
                color: const Color(0x448FA6FF),
                borderRadius: BorderRadius.vertical(top: Radius.elliptical(260.w, 36.h)),
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
        borderRadius: BorderRadius.circular(radius ?? 28.r),
        border: border,
        boxShadow: shadow ??
            const [
              BoxShadow(
                color: Color(0x1ED6A9A7),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
      ),
      child: child,
    );
  }
}
