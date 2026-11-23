import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../themes/app_theme.dart';
import 'candy_widgets.dart';

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
    final content = CandyBackground(
      child: Positioned.fill(
        child: useSafeArea ? SafeArea(child: child) : child,
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
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
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(radius ?? 26.r),
        border: border ?? AppTheme.stickerBorder(),
        boxShadow: shadow ?? AppTheme.stickerShadow(),
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
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
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
            color: Colors.white,
            shape: BoxShape.circle,
            border: AppTheme.stickerBorder(),
            boxShadow: AppTheme.stickerShadow(offset: 3),
          ),
          child: Icon(icon, color: AppTheme.navy, size: 22.sp),
        ),
      ),
    );
  }
}
