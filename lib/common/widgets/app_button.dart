import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../themes/app_theme.dart';
import 'candy_widgets.dart';

/// General-purpose button in the candy "sticker" style: thick navy outline,
/// solid drop shadow and a small bounce on press. The transparent
/// [AppButton.text] variant drops the outline and shadow.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final Gradient? gradient;

  /// Kept for API compatibility. Sticker buttons always use the navy outline;
  /// a non-null value only matters for the transparent text variant.
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
  }) : backgroundColor = null,
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
  }) : backgroundColor = Colors.white,
       textColor = AppTheme.navy;

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
  }) : backgroundColor = Colors.transparent,
       textColor = null;

  bool get _isTextVariant => backgroundColor == Colors.transparent;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final h = height ?? 56.h;
    final radius = borderRadius ?? BorderRadius.circular(h / 2);
    final fill = backgroundColor ?? AppTheme.candyPink;
    final resolvedColor = enabled
        ? fill
        : (_isTextVariant ? Colors.transparent : const Color(0xFFE6EEF6));
    final resolvedGradient = enabled && !_isTextVariant ? gradient : null;
    final foreground =
        textColor ??
        (_isTextVariant || fill == Colors.white
            ? AppTheme.candyPink
            : Colors.white);
    final resolvedForeground = enabled
        ? foreground
        : AppTheme.navyMuted.withValues(alpha: 0.7);

    final decoration = BoxDecoration(
      color: resolvedGradient == null ? resolvedColor : null,
      gradient: resolvedGradient,
      borderRadius: radius,
      border: _isTextVariant
          ? (borderSide == null ? null : Border.fromBorderSide(borderSide!))
          : AppTheme.stickerBorder(
              color: enabled
                  ? AppTheme.navy
                  : AppTheme.navy.withValues(alpha: 0.25),
            ),
      boxShadow: _isTextVariant
          ? null
          : enabled
          ? AppTheme.stickerShadow(offset: 4)
          : AppTheme.stickerShadow(
              color: AppTheme.navy.withValues(alpha: 0.12),
              offset: 3,
            ),
    );

    final button = SizedBox(
      width: width ?? double.infinity,
      height: h,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: radius,
          child: Ink(
            decoration: decoration,
            child: Center(
              child: Padding(
                padding:
                    padding ??
                    EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                child: isLoading
                    ? SizedBox(
                        width: 22.r,
                        height: 22.r,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          valueColor: AlwaysStoppedAnimation<Color>(foreground),
                        ),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: IconTheme.merge(
                          data: IconThemeData(
                            color: resolvedForeground,
                            size: 22.sp,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (icon != null) ...[
                                icon!,
                                SizedBox(width: 6.r),
                              ],
                              Text(
                                text,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: resolvedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );

    return BouncyTap(enabled: enabled && !_isTextVariant, child: button);
  }
}
