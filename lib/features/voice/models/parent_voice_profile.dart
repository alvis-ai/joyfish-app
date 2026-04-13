class ParentVoiceProfile {
  final int id;
  final int userId;
  final String role;
  final String? displayName;
  final String provider;
  final String modelName;
  final String voiceUri;
  final String referenceAudioUrl;
  final String transcript;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ParentVoiceProfile({
    required this.id,
    required this.userId,
    required this.role,
    required this.displayName,
    required this.provider,
    required this.modelName,
    required this.voiceUri,
    required this.referenceAudioUrl,
    required this.transcript,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ParentVoiceProfile.fromJson(Map<String, dynamic> json) {
    return ParentVoiceProfile(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      role: json['role'] as String? ?? '',
      displayName: json['display_name'] as String?,
      provider: json['provider'] as String? ?? '',
      modelName: json['model_name'] as String? ?? '',
      voiceUri: json['voice_uri'] as String? ?? '',
      referenceAudioUrl: json['reference_audio_url'] as String? ?? '',
      transcript: json['transcript'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }
}
