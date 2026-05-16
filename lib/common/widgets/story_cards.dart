import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../themes/app_theme.dart';
import '../utils/story_presenter.dart';
import 'joyfish_cached_image.dart';
import 'joyfish_scaffold.dart';

const double joyfishGoldenRatio = 1.61803398875;

class JoyfishStoryCard extends StatelessWidget {
  const JoyfishStoryCard({
    super.key,
    required this.visual,
    required this.title,
    required this.meta,
    required this.onTap,
    this.badge,
    this.imageUrl,
    this.actionIcon = Icons.play_arrow_rounded,
    this.onDelete,
  });

  final StoryVisual visual;
  final String title;
  final String meta;
  final VoidCallback onTap;
  final String? badge;
  final String? imageUrl;
  final IconData actionIcon;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1 / joyfishGoldenRatio,
            child: JoyfishCard(
              padding: EdgeInsets.zero,
              radius: 28.r,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28.r),
                child: _StoryArt(
                  visual: visual,
                  badge: badge,
                  imageUrl: imageUrl,
                  actionIcon: actionIcon,
                  onDelete: onDelete,
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF2D3446),
                ),
          ),
          SizedBox(height: 4.h),
          Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF78839A),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class JoyfishFeaturedStoryCard extends StatelessWidget {
  const JoyfishFeaturedStoryCard({
    super.key,
    required this.visual,
    required this.title,
    required this.label,
    required this.onTap,
    this.imageUrl,
  });

  final StoryVisual visual;
  final String title;
  final String label;
  final VoidCallback onTap;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: joyfishGoldenRatio,
        child: JoyfishCard(
          padding: EdgeInsets.zero,
          radius: 30.r,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30.r),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _StoryArt(
                  visual: visual,
                  badge: label,
                  imageUrl: imageUrl,
                  actionIcon: Icons.auto_awesome_rounded,
                  onDelete: null,
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0xB8222431),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 22.w,
                  right: 22.w,
                  bottom: 20.h,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryArt extends StatelessWidget {
  const _StoryArt({
    required this.visual,
    required this.badge,
    required this.imageUrl,
    required this.actionIcon,
    required this.onDelete,
  });

  final StoryVisual visual;
  final String? badge;
  final String? imageUrl;
  final IconData actionIcon;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _FallbackStoryArt(visual: visual, showEmoji: imageUrl == null),
        if (imageUrl != null)
          JoyfishCachedImage(
            imageUrl: imageUrl!,
            fit: BoxFit.cover,
            placeholder: (_) => const SizedBox.shrink(),
            errorBuilder: (context, error, stackTrace) =>
                _FallbackStoryArt(visual: visual, showEmoji: true),
          ),
        Positioned(
          left: 16.w,
          top: 16.h,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              badge ?? visual.subtitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        Positioned(
          right: 14.w,
          bottom: 14.h,
          child: Container(
            width: 42.w,
            height: 42.w,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Icon(actionIcon, color: AppTheme.skyDeep, size: 22.sp),
          ),
        ),
        if (onDelete != null)
          Positioned(
            right: 12.w,
            top: 12.h,
            child: Material(
              color: Colors.white.withValues(alpha: 0.92),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onDelete,
                child: SizedBox(
                  width: 34.w,
                  height: 34.w,
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: const Color(0xFFE85D75),
                    size: 20.sp,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FallbackStoryArt extends StatelessWidget {
  const _FallbackStoryArt({required this.visual, required this.showEmoji});

  final StoryVisual visual;
  final bool showEmoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            visual.color.withValues(alpha: 0.95),
            _shadeColor(visual.color),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -18.w,
            top: -14.h,
            child: Container(
              width: 92.w,
              height: 92.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(28.r),
              ),
            ),
          ),
          Positioned(
            right: -12.w,
            bottom: -18.h,
            child: Container(
              width: 124.w,
              height: 124.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(40.r),
              ),
            ),
          ),
          if (showEmoji)
            Center(
              child: Text(
                visual.emoji,
                style: TextStyle(fontSize: 78.sp),
              ),
            ),
        ],
      ),
    );
  }
}

Color _shadeColor(Color color) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness((hsl.lightness * 0.52).clamp(0.0, 1.0))
      .withSaturation((hsl.saturation * 0.95).clamp(0.0, 1.0))
      .toColor();
}
