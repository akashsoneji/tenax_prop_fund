// Models for the Settings → Security module (`/settings/security`).
// Parsing only — every rule about what a value means lives in the controller.

/// The three server-side security toggles.
class SecurityPrefs {
  const SecurityPrefs({
    required this.loginAlerts,
    required this.withdrawalConfirmation,
    required this.platformLock,
  });

  final bool loginAlerts;
  final bool withdrawalConfirmation;
  final bool platformLock;

  static const empty = SecurityPrefs(
    loginAlerts: false,
    withdrawalConfirmation: false,
    platformLock: false,
  );

  factory SecurityPrefs.fromJson(Map<String, dynamic> json) => SecurityPrefs(
        loginAlerts: json['login_alerts'] as bool? ?? false,
        withdrawalConfirmation: json['withdrawal_confirmation'] as bool? ?? false,
        platformLock: json['platform_lock'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'login_alerts': loginAlerts,
        'withdrawal_confirmation': withdrawalConfirmation,
        'platform_lock': platformLock,
      };

  SecurityPrefs copyWith({
    bool? loginAlerts,
    bool? withdrawalConfirmation,
    bool? platformLock,
  }) =>
      SecurityPrefs(
        loginAlerts: loginAlerts ?? this.loginAlerts,
        withdrawalConfirmation:
            withdrawalConfirmation ?? this.withdrawalConfirmation,
        platformLock: platformLock ?? this.platformLock,
      );
}

/// One signed-in device/browser session.
class SecuritySession {
  const SecuritySession({
    required this.id,
    required this.device,
    required this.ipAddress,
    required this.lastActiveAt,
    required this.isCurrent,
  });

  final int id;
  final String device;
  final String ipAddress;
  final DateTime? lastActiveAt;
  final bool isCurrent;

  factory SecuritySession.fromJson(Map<String, dynamic> json) =>
      SecuritySession(
        id: (json['id'] as num?)?.toInt() ?? 0,
        device: json['device']?.toString() ?? '',
        ipAddress: json['ip_address']?.toString() ?? '',
        lastActiveAt: DateTime.tryParse(json['last_active_at']?.toString() ?? ''),
        isCurrent: json['is_current'] as bool? ?? false,
      );
}

/// Full security snapshot backing the Security section.
class SecuritySettings {
  const SecuritySettings({
    required this.twoFactorEnabled,
    required this.twoFactorRequired,
    required this.recoveryCodesRemaining,
    required this.prefs,
    required this.sessions,
  });

  final bool twoFactorEnabled;
  final bool twoFactorRequired;
  final int recoveryCodesRemaining;
  final SecurityPrefs prefs;
  final List<SecuritySession> sessions;

  factory SecuritySettings.fromJson(Map<String, dynamic> json) {
    final prefs = json['prefs'];
    final sessions = json['sessions'];
    return SecuritySettings(
      twoFactorEnabled: json['two_factor_enabled'] as bool? ?? false,
      twoFactorRequired: json['two_factor_required'] as bool? ?? false,
      recoveryCodesRemaining:
          (json['recovery_codes_remaining'] as num?)?.toInt() ?? 0,
      prefs: prefs is Map<String, dynamic>
          ? SecurityPrefs.fromJson(prefs)
          : SecurityPrefs.empty,
      sessions: sessions is List
          ? sessions
              .whereType<Map<String, dynamic>>()
              .map(SecuritySession.fromJson)
              .toList()
          : const <SecuritySession>[],
    );
  }

  SecuritySettings copyWith({
    bool? twoFactorEnabled,
    int? recoveryCodesRemaining,
    SecurityPrefs? prefs,
  }) =>
      SecuritySettings(
        twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
        twoFactorRequired: twoFactorRequired,
        recoveryCodesRemaining:
            recoveryCodesRemaining ?? this.recoveryCodesRemaining,
        prefs: prefs ?? this.prefs,
        sessions: sessions,
      );
}

/// Response of `POST /settings/two-factor/enrol`.
class TwoFactorEnrolment {
  const TwoFactorEnrolment({required this.secret, required this.qrUrl});

  final String secret;
  final String qrUrl;

  factory TwoFactorEnrolment.fromJson(Map<String, dynamic> json) =>
      TwoFactorEnrolment(
        secret: json['secret']?.toString() ?? '',
        qrUrl: json['qr_url']?.toString() ?? '',
      );

  /// The URI actually encoded into the QR.
  ///
  /// The server sends `qr_url` HTML-escaped (`&amp;` between params), which
  /// makes an authenticator read the second parameter as `amp;issuer` and
  /// abandon the scan. Unescaping is therefore required, and the TOTP
  /// parameters are pinned to the values this backend signs with (SHA1, 6
  /// digits, 30s) so a URI missing them still resolves.
  String get otpauthUri {
    final raw = qrUrl
        .replaceAll('&amp;', '&')
        .replaceAll('&#38;', '&')
        .trim();
    if (!raw.startsWith('otpauth://')) return raw;

    final separator = raw.contains('?') ? '&' : '?';
    final params = <String>[
      if (!raw.contains('algorithm=')) 'algorithm=SHA1',
      if (!raw.contains('digits=')) 'digits=6',
      if (!raw.contains('period=')) 'period=30',
    ];
    if (params.isEmpty) return raw;
    return '$raw$separator${params.join('&')}';
  }
}
