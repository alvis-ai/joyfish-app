import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../themes/app_theme.dart';
import '../utils/story_presenter.dart';
import 'candy_widgets.dart';
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
              border: AppTheme.stickerBorder(),
              shadow: AppTheme.stickerShadow(),
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
              color: AppTheme.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.navyMuted,
              fontWeight: FontWeight.w600,
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
          border: AppTheme.stickerBorder(),
          shadow: AppTheme.stickerShadow(),
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
                      colors: [Colors.transparent, Color(0xCC1B2A4A)],
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
                    style: Theme.of(
                      context,
                    ).textTheme.headlineLarge?.copyWith(color: Colors.white),
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
          left: 12.w,
          top: 12.h,
          right: 12.w,
          child: Align(
            alignment: Alignment.centerLeft,
            child: CandyChip(text: badge ?? visual.subtitle),
          ),
        ),
        Positioned(
          right: 12.w,
          bottom: 12.h,
          child: Container(
            width: 42.r,
            height: 42.r,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: AppTheme.stickerBorder(),
              boxShadow: AppTheme.stickerShadow(offset: 3),
            ),
            child: Icon(actionIcon, color: AppTheme.candyPink, size: 22.sp),
          ),
        ),
        if (onDelete != null)
          // Bottom-left keeps the top row free for the category chip.
          Positioned(
            left: 10.w,
            bottom: 10.h,
            child: CandyIconButton(
              icon: Icons.delete_outline_rounded,
              tooltip: '删除',
              onTap: onDelete!,
              iconColor: const Color(0xFFE5484D),
              size: 38.r,
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
          colors: [AppTheme.lemonSoft, visual.color.withValues(alpha: 0.7)],
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
                color: Colors.white.withValues(alpha: 0.35),
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
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(40.r),
              ),
            ),
          ),
          if (showEmoji)
            Center(
              child: Text(visual.emoji, style: TextStyle(fontSize: 78.sp)),
            ),
        ],
      ),
    );
  }
}
