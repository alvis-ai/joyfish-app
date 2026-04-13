class StoryRequestRecord {
  final int id;
  final int? childId;
  final String? titleHint;
  final String? scenario;
  final String? timeOfDay;
  final String? ageRange;
  final List<String> themeTags;
  final String language;
  final Map<String, dynamic>? optionsJson;
  final String status;
  final int attemptCount;
  final int maxAttempts;
  final String? lastError;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? nextRetryAt;
  final DateTime? finishedAt;

  const StoryRequestRecord({
    required this.id,
    required this.childId,
    required this.titleHint,
    required this.scenario,
    required this.timeOfDay,
    required this.ageRange,
    required this.themeTags,
    required this.language,
    required this.optionsJson,
    required this.status,
    required this.attemptCount,
    required this.maxAttempts,
    required this.lastError,
    required this.createdAt,
    required this.startedAt,
    required this.nextRetryAt,
    required this.finishedAt,
  });

  factory StoryRequestRecord.fromJson(Map<String, dynamic> json) {
    return StoryRequestRecord(
      id: json['id'] as int? ?? 0,
      childId: json['child_id'] as int?,
      titleHint: json['title_hint'] as String?,
      scenario: json['scenario'] as String?,
      timeOfDay: json['time_of_day'] as String?,
      ageRange: json['age_range'] as String?,
      themeTags: (json['theme_tags'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      language: json['language'] as String? ?? 'zh',
      optionsJson: json['options_json'] is Map
          ? Map<String, dynamic>.from(json['options_json'] as Map)
          : null,
      status: json['status'] as String? ?? 'pending',
      attemptCount: json['attempt_count'] as int? ?? 0,
      maxAttempts: json['max_attempts'] as int? ?? 0,
      lastError: json['last_error'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      startedAt: DateTime.tryParse(json['started_at'] as String? ?? ''),
      nextRetryAt: DateTime.tryParse(json['next_retry_at'] as String? ?? ''),
      finishedAt: DateTime.tryParse(json['finished_at'] as String? ?? ''),
    );
  }

  String? get voiceRole {
    final tts = optionsJson?['tts'];
    if (tts is Map) {
      return tts['voice_role'] as String?;
    }
    return null;
  }
}

class StoryRecord {
  final int id;
  final int requestId;
  final String title;
  final String? summary;
  final String language;
  final int? readingMinutes;
  final String? ageRange;
  final String bodyMd;
  final String? coverImageUrl;
  final String? audioUrl;
  final String visibility;
  final DateTime? createdAt;
  final DateTime? publishedAt;

  const StoryRecord({
    required this.id,
    required this.requestId,
    required this.title,
    required this.summary,
    required this.language,
    required this.readingMinutes,
    required this.ageRange,
    required this.bodyMd,
    required this.coverImageUrl,
    required this.audioUrl,
    required this.visibility,
    required this.createdAt,
    required this.publishedAt,
  });

  factory StoryRecord.fromJson(Map<String, dynamic> json) {
    return StoryRecord(
      id: json['id'] as int? ?? 0,
      requestId: json['request_id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String?,
      language: json['language'] as String? ?? 'zh',
      readingMinutes: json['reading_minutes'] as int?,
      ageRange: json['age_range'] as String?,
      bodyMd: json['body_md'] as String? ?? '',
      coverImageUrl: json['cover_image_url'] as String?,
      audioUrl: json['audio_url'] as String?,
      visibility: json['visibility'] as String? ?? 'private',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
    );
  }
}
