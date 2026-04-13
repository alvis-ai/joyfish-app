import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final Gradient? gradient;
  final BorderSide? borderSide;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Widget? icon;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.gradient,
    this.borderSide,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.icon,
  });

  const AppButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.icon,
    this.gradient,
    this.borderSide,
  })  : backgroundColor = null,
        textColor = null;

  const AppButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.icon,
    this.gradient,
    this.borderSide,
  })  : backgroundColor = Colors.white,
        textColor = const Color(0xFF7A39D8);

  const AppButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.icon,
    this.gradient,
    this.borderSide,
  })  : backgroundColor = Colors.transparent,
        textColor = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null && !isLoading;
    final radius = borderRadius ?? BorderRadius.circular(28.r);
    final textStyle = TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700);
    final resolvedGradient = enabled ? gradient : null;
    final resolvedColor = enabled
        ? backgroundColor ?? theme.colorScheme.primary
        : const Color(0xFFDCD9E2);

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 58.h,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              color: resolvedGradient == null ? resolvedColor : null,
              gradient: resolvedGradient,
              borderRadius: radius,
              border: borderSide == null ? null : Border.fromBorderSide(borderSide!),
              boxShadow: enabled && backgroundColor != Colors.transparent
                  ? const [
                      BoxShadow(
                        color: Color(0x1FD4A3A3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Padding(
                padding: padding ?? EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                child: isLoading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(textColor ?? Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            icon!,
                            SizedBox(width: 8.w),
                          ],
                          Text(
                            text,
                            style: textStyle.copyWith(
                              color: textColor ??
                                  (backgroundColor == Colors.transparent ||
                                          borderSide != null ||
                                          backgroundColor == Colors.white
                                      ? theme.colorScheme.primary
                                      : Colors.white),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
