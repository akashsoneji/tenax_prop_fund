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
    required this.earnedLabel,
    required this.rateLabel,
    required this.clicks,
    required this.conversionRate,
    required this.totalPaidLabel,
    required this.withdrawableLabel,
    required this.minWithdrawLabel,
    required this.referrals,
  });

  final String referralCode;
  final String shareUrl;
  final int signedUp;
  final int purchased;

  /// Server-formatted money / percent strings — rendered as-is so the app never
  /// disagrees with the portal on rounding or currency symbol.
  final String earnedLabel;
  final String rateLabel;
  final int clicks;
  final String conversionRate;
  final String totalPaidLabel;
  final String withdrawableLabel;
  final String minWithdrawLabel;

  final List<Referral> referrals;

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
      earnedLabel: stats['to_be_paid'] as String? ?? '\$0.00',
      rateLabel: settings['commission_percent'] as String? ?? '0%',
      clicks: (stats['clicks'] as num?)?.toInt() ?? 0,
      conversionRate: stats['conversion_rate'] as String? ?? '0%',
      totalPaidLabel: stats['total_paid'] as String? ?? '\$0.00',
      withdrawableLabel: settings['withdrawable'] as String? ?? '\$0.00',
      minWithdrawLabel: settings['min_withdraw'] as String? ?? '\$0.00',
      referrals: rows
          .whereType<Map<String, dynamic>>()
          .map(Referral.fromJson)
          .toList(),
    );
  }
}

/// A single commission / referral row.
class Referral {
  const Referral({
    required this.name,
    required this.plan,
    required this.price,
    required this.rate,
    required this.status,
    required this.earned,
    required this.createdAt,
  });

  final String name;
  final String plan;
  final String price;
  final String rate;
  final String status;
  final String earned;
  final DateTime? createdAt;

  factory Referral.fromJson(Map<String, dynamic> json) => Referral(
    name:
        json['referred'] as String? ??
        json['name'] as String? ??
        json['email'] as String? ??
        '',
    plan: json['plan'] as String? ?? '',
    price: json['price'] as String? ?? '',
    rate: json['rate'] as String? ?? '',
    status: json['status'] as String? ?? '',
    earned: json['amount'] as String? ?? json['earned'] as String? ?? '',
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );
}
