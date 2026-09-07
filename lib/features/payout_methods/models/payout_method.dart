/// One selectable payout destination shown on the Payout methods screen.
///
/// All demo data lives in the controller; a real impl swaps [isSetUp] for the
/// saved-state coming back from the payout API.
class PayoutMethod {
  const PayoutMethod({
    required this.name,
    required this.meta,
    required this.description,
    this.isSetUp = false,
  });

  final String name;
  final String meta;
  final String description;
  final bool isSetUp;

  /// Maps one entry of `GET /finance/methods` -> `data.methods`. The live API
  /// currently returns an empty array and no sample row, so field names are
  /// best-effort with defensive fallbacks across the likely keys.
  factory PayoutMethod.fromJson(Map<String, dynamic> json) {
    return PayoutMethod(
      name: (json['name'] ?? json['label'] ?? json['type'] ?? '—').toString(),
      meta: (json['meta'] ?? json['subtitle'] ?? json['summary'] ?? '')
          .toString(),
      description:
          (json['description'] ?? json['details'] ?? json['note'] ?? '')
              .toString(),
      isSetUp: json['is_set_up'] as bool? ??
          json['isSetUp'] as bool? ??
          json['configured'] as bool? ??
          false,
    );
  }
}
