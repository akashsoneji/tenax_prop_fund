/// A single promotional offer / voucher returned by `GET /growth/offers`.
///
/// An offer the user has already redeemed has [used] `true` — its rail is
/// faded and the CTA is disabled.
class Offer {
  const Offer({
    required this.id,
    required this.code,
    required this.label,
    required this.description,
    required this.kind,
    required this.flag,
    required this.exp,
    required this.checks,
    required this.valueLabel,
    required this.used,
  });

  /// Backend id of the offer.
  final int id;

  /// Voucher code shown vertically on the gradient rail (e.g. 'TEST123').
  final String code;

  /// Human label for the offer, usually the same as [code].
  final String label;

  /// Optional one-line explanation. Null/blank on most offers.
  final String? description;

  /// Offer kind sent by the API, e.g. 'disc'.
  final String kind;

  /// Optional highlight pill text, e.g. 'Popular'.
  final String? flag;

  /// Expiry copy, e.g. 'Always available' / 'Expires in 12 days'.
  final String exp;

  /// Bullet points describing what the offer covers.
  final List<String> checks;

  /// Big headline value, e.g. '100.00% off'.
  final String valueLabel;

  /// Whether the user has already redeemed this offer.
  final bool used;

  factory Offer.fromJson(Map<String, dynamic> json) {
    final rawChecks = (json['checks'] as List<dynamic>?) ?? const [];
    final description = (json['description'] as String?)?.trim();
    return Offer(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: json['code'] as String? ?? '',
      label: json['label'] as String? ?? json['code'] as String? ?? '',
      description: (description == null || description.isEmpty)
          ? null
          : description,
      kind: json['kind'] as String? ?? '',
      flag: json['flag'] as String?,
      exp: json['exp'] as String? ?? '',
      checks: rawChecks
          .map((c) => c?.toString() ?? '')
          .where((c) => c.isNotEmpty)
          .toList(),
      valueLabel: json['value_label'] as String? ?? '',
      used: json['used'] as bool? ?? false,
    );
  }
}

/// Payload for the "My offers" screen: every offer plus the backend's count of
/// the ones still redeemable.
class OffersData {
  const OffersData({required this.offers, required this.availableCount});

  final List<Offer> offers;

  /// `available_count` from the API — offers the user can still redeem.
  final int availableCount;

  /// Offers the user can apply right now.
  List<Offer> get available =>
      offers.where((o) => !o.used).toList(growable: false);

  /// Offers already redeemed.
  List<Offer> get used => offers.where((o) => o.used).toList(growable: false);

  bool get isEmpty => offers.isEmpty;

  factory OffersData.fromJson(Map<String, dynamic> json) {
    final raw = (json['offers'] as List<dynamic>?) ?? const [];
    return OffersData(
      offers: raw
          .whereType<Map<String, dynamic>>()
          .map(Offer.fromJson)
          .toList(growable: false),
      availableCount: (json['available_count'] as num?)?.toInt() ?? 0,
    );
  }
}
