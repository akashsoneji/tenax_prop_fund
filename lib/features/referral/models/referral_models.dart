// Domain models for the "Refer & earn" screen. Shapes mirror the web portal's
// Inertia payload (`component: Client/Growth/Refer`), read from `props`:
// `referral`, `stats`, `referral_settings` and the paginated `commissions`.
// Everything is display-oriented so the view binds directly and the controller
// holds a single `DataState<ReferralData>`.

/// The full payload the "Refer & earn" screen needs in one fetch.
class ReferralData {
  const ReferralData({
    required this.referralCode,
    required this.shareUrl,
    required this.signedUp,
    required this.purchased,
    required this.earned,
    required this.rate,
    required this.referrals,
  });

  final String referralCode;
  final String shareUrl;
  final int signedUp;
  final int purchased;
  final int earned; // whole USD
  final int rate; // percent
  final List<Referral> referrals;

  String get earnedLabel => '\$$earned';
  String get rateLabel => '$rate%';

  bool get isEmpty => referralCode.isEmpty;

  /// Parses the Inertia `props` block into the screen payload.
  factory ReferralData.fromProps(Map<String, dynamic> props) {
    final referral = props['referral'] as Map<String, dynamic>? ?? const {};
    final stats = props['stats'] as Map<String, dynamic>? ?? const {};
    final settings =
        props['referral_settings'] as Map<String, dynamic>? ?? const {};
    // `commissions` is either a plain list (REST `/growth/referrals`) or a
    // Laravel paginator object whose rows are under `data` (Inertia).
    final commissionsRaw = props['commissions'];
    final rows = commissionsRaw is List
        ? commissionsRaw
        : (commissionsRaw is Map
            ? (commissionsRaw['data'] as List<dynamic>? ?? const [])
            : const []);
    return ReferralData(
      referralCode: referral['code'] as String? ?? '',
      shareUrl: referral['share_url'] as String? ?? '',
      signedUp: (stats['referrals'] as num?)?.toInt() ?? 0,
      purchased: (referral['times_used'] as num?)?.toInt() ?? 0,
      earned: _parseMoney(stats['to_be_paid']),
      rate: _parsePercent(settings['commission_percent']),
      referrals: rows
          .whereType<Map<String, dynamic>>()
          .map(Referral.fromJson)
          .toList(),
    );
  }

  /// Parses a display money string like `"$1,234.56"` to whole USD.
  static int _parseMoney(dynamic value) {
    if (value == null) return 0;
    final cleaned = value.toString().replaceAll(RegExp(r'[^0-9.\-]'), '');
    return (double.tryParse(cleaned) ?? 0).round();
  }

  /// Parses a display percent string like `"10%"` to an int.
  static int _parsePercent(dynamic value) {
    if (value == null) return 0;
    final cleaned = value.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }
}

/// A single commission / referral row.
class Referral {
  const Referral({
    required this.name,
    required this.status,
    required this.earned,
  });

  final String name;
  final String status;
  final String earned;

  factory Referral.fromJson(Map<String, dynamic> json) => Referral(
        name: json['name'] as String? ?? json['email'] as String? ?? '',
        status: json['status'] as String? ?? '',
        earned: json['amount'] as String? ?? json['earned'] as String? ?? '',
      );
}
