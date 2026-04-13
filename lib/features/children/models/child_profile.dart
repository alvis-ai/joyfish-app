class ChildProfile {
  final int id;
  final int userId;
  final String nickname;
  final String? birthdate;
  final String? gender;
  final Map<String, dynamic>? preferences;
  final DateTime? createdAt;

  const ChildProfile({
    required this.id,
    required this.userId,
    required this.nickname,
    required this.birthdate,
    required this.gender,
    required this.preferences,
    required this.createdAt,
  });

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      nickname: json['nickname'] as String? ?? '',
      birthdate: json['birthdate'] as String?,
      gender: json['gender'] as String?,
      preferences: json['preferences'] is Map
          ? Map<String, dynamic>.from(json['preferences'] as Map)
          : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nickname': nickname,
      'birthdate': birthdate,
      'gender': gender,
      'preferences': preferences,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
