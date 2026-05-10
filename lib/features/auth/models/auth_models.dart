class AuthUser {
  final int id;
  final String? email;
  final String? phoneNumber;
  final String provider;
  final String? providerUid;
  final String locale;
  final String timezone;
  final String membershipTier;
  final DateTime? membershipExpiresAt;
  final DateTime? createdAt;

  const AuthUser({
    required this.id,
    required this.email,
    required this.phoneNumber,
    required this.provider,
    required this.providerUid,
    required this.locale,
    required this.timezone,
    this.membershipTier = 'free',
    this.membershipExpiresAt,
    required this.createdAt,
  });

  bool get canUseCustomStoryPrompt {
    final normalized = membershipTier.trim().toLowerCase();
    final activeTier = normalized == 'vip' ||
        normalized == 'monthly' ||
        normalized == 'annual' ||
        normalized == 'yearly' ||
        normalized == 'pro';
    if (!activeTier) {
      return false;
    }
    final expiresAt = membershipExpiresAt;
    return expiresAt == null || expiresAt.isAfter(DateTime.now());
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final explicitVip = json['is_vip'] == true;
    final tier = (json['membership_tier'] ??
            json['vip_tier'] ??
            json['subscription_tier'] ??
            (explicitVip ? 'vip' : 'free'))
        .toString();

    return AuthUser(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String?,
      provider: json['provider'] as String? ?? 'password',
      providerUid: json['provider_uid'] as String?,
      locale: json['locale'] as String? ?? 'zh-CN',
      timezone: json['timezone'] as String? ?? 'Asia/Shanghai',
      membershipTier: tier,
      membershipExpiresAt:
          DateTime.tryParse(json['membership_expires_at'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone_number': phoneNumber,
      'provider': provider,
      'provider_uid': providerUid,
      'locale': locale,
      'timezone': timezone,
      'membership_tier': membershipTier,
      'membership_expires_at': membershipExpiresAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class AuthSession {
  final String token;
  final AuthUser user;

  const AuthSession({
    required this.token,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String? ?? '',
      user: AuthUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
    );
  }
}

class SmsCodeResult {
  final String purpose;
  final String phoneNumber;
  final int expiresInSeconds;
  final int retryAfterSeconds;
  final String? debugCode;

  const SmsCodeResult({
    required this.purpose,
    required this.phoneNumber,
    required this.expiresInSeconds,
    required this.retryAfterSeconds,
    required this.debugCode,
  });

  factory SmsCodeResult.fromJson(Map<String, dynamic> json) {
    return SmsCodeResult(
      purpose: json['purpose'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      expiresInSeconds: json['expires_in_seconds'] as int? ?? 0,
      retryAfterSeconds: json['retry_after_seconds'] as int? ?? 0,
      debugCode: json['debug_code'] as String?,
    );
  }
}
