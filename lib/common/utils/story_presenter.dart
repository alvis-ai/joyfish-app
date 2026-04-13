import 'package:flutter/material.dart';

import '../../features/story/models/story_models.dart';
import '../themes/app_theme.dart';

class StoryVisual {
  const StoryVisual({
    required this.emoji,
    required this.color,
    required this.subtitle,
  });

  final String emoji;
  final Color color;
  final String subtitle;
}

StoryVisual storyVisualOf(StoryRecord story) {
  final text = '${story.title} ${story.summary ?? ''}'.toLowerCase();
  if (text.contains('兔') || text.contains('动物')) {
    return const StoryVisual(emoji: '🐰', color: Color(0xFFF76AA7), subtitle: '可爱动物');
  }
  if (text.contains('海')) {
    return const StoryVisual(emoji: '🌊', color: Color(0xFF19BCE1), subtitle: '海底世界');
  }
  if (text.contains('星') || text.contains('太空')) {
    return const StoryVisual(emoji: '🚀', color: Color(0xFFA075F5), subtitle: '太空探索');
  }
  if (text.contains('森林') || text.contains('树')) {
    return const StoryVisual(emoji: '🌳', color: Color(0xFF18D67C), subtitle: '魔法森林');
  }
  if (text.contains('友') || text.contains('分享')) {
    return const StoryVisual(emoji: '🤝', color: Color(0xFFFF6E68), subtitle: '友谊互助');
  }
  return StoryVisual(
    emoji: '🐟',
    color: AppTheme.purpleLight,
    subtitle: story.summary?.isNotEmpty == true ? story.summary! : '精彩故事',
  );
}

String storyDurationLabel(StoryRecord story) {
  final minutes = story.readingMinutes ?? 8;
  return '$minutes:00';
}

String storyDayLabel(DateTime? dateTime) {
  if (dateTime == null) return '今天';
  final now = DateTime.now();
  final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(date).inDays;
  if (diff <= 0) return '今天';
  if (diff == 1) return '昨天';
  return '$diff天前';
}
