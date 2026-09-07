/// A single promotional offer / voucher shown on the "My offers" screen.
///
/// [locked] offers are earned by future actions (a breach, a passed trial),
/// so their gradient rail is faded and the CTA is disabled.
class Offer {
  const Offer({
    required this.code,
    required this.percentLabel,
    required this.subLabel,
    required this.description,
    required this.badge,
    this.locked = false,
  });

  /// Voucher code shown vertically on the gradient rail (e.g. 'PIPZE30').
  final String code;

  /// Big headline percentage, e.g. '30% off'.
  final String percentLabel;

  /// Muted inline suffix after the headline, e.g. 'every plan'.
  final String subLabel;

  /// One-line explanation of the offer.
  final String description;

  /// Yellow pill text, e.g. '482 of 500 left' / 'Expires in 12 days'.
  final String badge;

  /// Locked offers cannot be applied yet.
  final bool locked;

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
        code: json['code'] as String? ?? '',
        percentLabel: json['percent_label'] as String? ??
            json['discount'] as String? ??
            '',
        subLabel: json['sub_label'] as String? ?? '',
        description: json['description'] as String? ?? '',
        badge: json['badge'] as String? ?? '',
        locked: json['locked'] as bool? ?? false,
      );
}

/// Bundle for the "My offers" screen: offers the user can apply now and rewards
/// still locked behind an action. Loaded as one [DataState] payload.
class OffersData {
  const OffersData({required this.available, required this.locked});

  /// Offers the user can apply right now.
  final List<Offer> available;

  /// Rewards still locked behind a future action (breach, passed trial).
  final List<Offer> locked;

  bool get isEmpty => available.isEmpty && locked.isEmpty;

  factory OffersData.fromJson(Map<String, dynamic> json) {
    final offers = (json['offers'] as List<dynamic>?) ?? const [];
    final parsed = offers
        .whereType<Map<String, dynamic>>()
        .map(Offer.fromJson)
        .toList();
    return OffersData(
      available: parsed.where((o) => !o.locked).toList(),
      locked: parsed.where((o) => o.locked).toList(),
    );
  }
}
