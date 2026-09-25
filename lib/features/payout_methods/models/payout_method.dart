/// One saved payout destination returned by `GET /finance/methods`.
class PayoutMethod {
  const PayoutMethod({
    required this.id,
    required this.type,
    required this.name,
    required this.meta,
    required this.description,
    this.currency = 'USD',
    this.details = const <String, dynamic>{},
    this.isSetUp = false,
  });

  /// Server id — used for `PUT` / `DELETE /finance/methods/{id}`.
  final String id;

  /// Rail value (`bank`, `usdt`, `upi`…) matching a [MethodType.value].
  final String type;
  final String name;
  final String meta;
  final String description;
  final String currency;

  /// The rail-specific fields saved with the method (account number, address…).
  final Map<String, dynamic> details;
  final bool isSetUp;

  factory PayoutMethod.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['details'];
    final details = rawDetails is Map<String, dynamic>
        ? rawDetails
        : const <String, dynamic>{};
    return PayoutMethod(
      id: json['id']?.toString() ?? '',
      type: (json['type'] ?? '').toString(),
      name: (json['label'] ?? json['name'] ?? json['type'] ?? '—').toString(),
      meta: (json['meta'] ?? json['masked'] ?? json['summary'] ?? json['type'] ?? '')
          .toString(),
      description: (json['description'] ?? json['note'] ?? '').toString(),
      currency: (json['currency'] as String?)?.trim().isNotEmpty == true
          ? json['currency'] as String
          : 'USD',
      details: details,
      isSetUp: json['is_set_up'] as bool? ?? json['id'] != null,
    );
  }
}
