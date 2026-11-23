import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../themes/app_theme.dart';

/// Squashes its child a little while pressed and springs back on release.
class BouncyTap extends StatefulWidget {
  const BouncyTap({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = 0.94,
  });

  final Widget child;
  final bool enabled;
  final double pressedScale;

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap> {
  bool _pressed = false;

  void _set(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: Duration(milliseconds: _pressed ? 90 : 260),
        curve: _pressed ? Curves.easeOut : Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}

/// Chunky sticker-style button. Built on [FilledButton] so it keeps Material
/// semantics, focus handling and disabled state.
class CandyButton extends StatelessWidget {
  const CandyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppTheme.candyPink,
    this.foregroundColor = Colors.white,
    this.disabledColor = const Color(0xFFFFC4D4),
    this.loading = false,
    this.height,
    this.fontSize,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final Color foregroundColor;
  final Color disabledColor;
  final bool loading;
  final double? height;
  final double? fontSize;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final h = height ?? 56.h;
    final radius = BorderRadius.circular(h / 2);
    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: h,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: AppTheme.stickerBorder(
          color: enabled
              ? AppTheme.navy
              : AppTheme.navy.withValues(alpha: 0.25),
        ),
        boxShadow: enabled
            ? AppTheme.stickerShadow(offset: 4)
            : AppTheme.stickerShadow(
                color: AppTheme.navy.withValues(alpha: 0.12),
                offset: 3,
              ),
      ),
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: disabledColor,
          disabledForegroundColor: foregroundColor.withValues(alpha: 0.9),
          minimumSize: Size(expand ? double.infinity : 0, h),
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          shape: RoundedRectangleBorder(borderRadius: radius),
          elevation: 0,
        ),
        child: loading
            ? SizedBox(
                width: 22.r,
                height: 22.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: foregroundColor,
                ),
              )
            // Scale the label down instead of overflowing in tight rows.
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 22.sp),
                      SizedBox(width: 6.w),
                    ],
                    Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: fontSize ?? 17.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
    return BouncyTap(enabled: enabled, child: button);
  }
}

/// White card with a thick outline and a solid drop shadow.
class StickerCard extends StatelessWidget {
  const StickerCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.color = Colors.white,
    this.borderColor = AppTheme.navy,
    this.shadowColor = AppTheme.navy,
    this.shadowOffset = 6,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;
  final Color color;
  final Color borderColor;
  final Color shadowColor;
  final double shadowOffset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius ?? 30.r),
        border: AppTheme.stickerBorder(color: borderColor),
        boxShadow: AppTheme.stickerShadow(
          color: shadowColor,
          offset: shadowOffset,
        ),
      ),
      child: child,
    );
  }
}

/// Small rounded label, e.g. a story category.
class CandyChip extends StatelessWidget {
  const CandyChip({
    super.key,
    required this.text,
    this.color = AppTheme.lemon,
    this.textColor = AppTheme.navy,
    this.icon,
  });

  final String text;
  final Color color;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99.r),
        border: AppTheme.stickerBorder(width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14.sp, color: textColor),
            SizedBox(width: 4.w),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Round sticker icon button with a per-button accent color.
class CandyIconButton extends StatelessWidget {
  const CandyIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.iconColor = AppTheme.navy,
    this.color = Colors.white,
    this.size,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color iconColor;
  final Color color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final s = size ?? 46.r;
    return Tooltip(
      message: tooltip,
      child: BouncyTap(
        pressedScale: 0.88,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Ink(
              width: s,
              height: s,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: AppTheme.stickerBorder(),
                boxShadow: AppTheme.stickerShadow(offset: 3),
              ),
              child: Icon(icon, color: iconColor, size: s * 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bright sky background with soft candy-colored bubbles and sparkles.
class CandyBackground extends StatelessWidget {
  const CandyBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Bubble(left: -60.w, top: -40.h, size: 180.r, color: AppTheme.lemon),
          _Bubble(
            right: -50.w,
            top: 140.h,
            size: 130.r,
            color: AppTheme.candyPink,
          ),
          _Bubble(
            left: -40.w,
            bottom: 120.h,
            size: 120.r,
            color: AppTheme.mint,
          ),
          _Bubble(
            right: -70.w,
            bottom: -50.h,
            size: 200.r,
            color: AppTheme.skyBlue,
          ),
          // Sparkles hug the screen edges so they never sit under text.
          Positioned(
            left: 4.w,
            top: 430.h,
            child: _Sparkle(color: AppTheme.candyPink, size: 14.r),
          ),
          Positioned(
            right: 4.w,
            top: 520.h,
            child: _Sparkle(color: AppTheme.grape, size: 12.r),
          ),
          Positioned(
            left: 8.w,
            bottom: 24.h,
            child: _Sparkle(color: AppTheme.lemon, size: 18.r),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.size,
    required this.color,
  });

  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.22),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform.rotate(
        angle: math.pi / 4,
        child: Icon(Icons.auto_awesome, color: color, size: size),
      ),
    );
  }
}

/// The JoyFish mascot in a sticker circle, gently bobbing up and down.
class FloatingMascot extends StatefulWidget {
  const FloatingMascot({super.key, this.size});

  final double? size;

  @override
  State<FloatingMascot> createState() => _FloatingMascotState();
}

class _FloatingMascotState extends State<FloatingMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Bob a few times when the screen appears, then rest. A finite animation
    // keeps CPU idle and lets widget tests settle; reduced-motion skips it.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.repeat(reverse: true, count: 6);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size ?? 96.r;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, -6 * t),
          child: Transform.rotate(angle: (t - 0.5) * 0.08, child: child),
        );
      },
      child: Container(
        width: s,
        height: s,
        padding: EdgeInsets.all(s * 0.1),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: AppTheme.stickerBorder(width: 3),
          boxShadow: AppTheme.stickerShadow(
            color: AppTheme.candyPink,
            offset: 6,
          ),
        ),
        child: Image.asset('assets/images/joyfish_logo.png'),
      ),
    );
  }
}
