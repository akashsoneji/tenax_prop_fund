import 'package:flutter/foundation.dart';

/// Models for the manual "Complete payment" flow — `GET /orders/{id}` and the
/// proof upload response. All money is kept as both a preformatted label
/// (`"USD 49.00"`) and its minor-unit integer so the UI can show the label and
/// the logic can compare numbers.

@immutable
class OrderDetails {
  const OrderDetails({
    required this.order,
    required this.instructions,
  });

  final Order order;
  final PaymentInstructions? instructions;

  factory OrderDetails.fromJson(Map<String, dynamic> json) => OrderDetails(
        order: Order.fromJson(_map(json['order'])),
        instructions: json['payment_instructions'] is Map<String, dynamic>
            ? PaymentInstructions.fromJson(
                json['payment_instructions'] as Map<String, dynamic>)
            : null,
      );
}

@immutable
class Order {
  const Order({
    required this.id,
    required this.number,
    required this.status,
    required this.currency,
    required this.total,
    required this.totalMinor,
    required this.subtotal,
    required this.discount,
    required this.discountMinor,
    required this.items,
    required this.payments,
  });

  final int id;
  final String number;
  final String status;
  final String currency;
  final String total;
  final int totalMinor;
  final String subtotal;
  final String discount;
  final int discountMinor;
  final List<OrderItem> items;
  final List<OrderPayment> payments;

  /// Human title for the header ("Pipze 5K — $5K") from the first line item.
  String get title => items.isNotEmpty ? items.first.description : '';

  bool get isUnderReview => status == 'under_review';
  bool get isAwaitingPayment => status == 'awaiting_payment';

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: (json['id'] as num?)?.toInt() ?? 0,
        number: json['number'] as String? ?? '',
        status: json['status'] as String? ?? '',
        currency: json['currency'] as String? ?? 'USD',
        total: json['total'] as String? ?? '',
        totalMinor: (json['total_minor'] as num?)?.toInt() ?? 0,
        subtotal: json['subtotal'] as String? ?? '',
        discount: json['discount'] as String? ?? '',
        discountMinor: (json['discount_minor'] as num?)?.toInt() ?? 0,
        items: _maps(json['items'])
            .map(OrderItem.fromJson)
            .toList(growable: false),
        payments: _maps(json['payments'])
            .map(OrderPayment.fromJson)
            .toList(growable: false),
      );
}

@immutable
class OrderItem {
  const OrderItem({
    required this.description,
    required this.quantity,
    required this.total,
  });

  final String description;
  final int quantity;
  final String total;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        description: json['description'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        total: json['total'] as String? ?? '',
      );
}

@immutable
class OrderPayment {
  const OrderPayment({
    required this.id,
    required this.status,
    required this.provider,
    required this.amount,
  });

  final int id;
  final String status;
  final String provider;
  final String amount;

  factory OrderPayment.fromJson(Map<String, dynamic> json) => OrderPayment(
        id: (json['id'] as num?)?.toInt() ?? 0,
        status: json['status'] as String? ?? '',
        provider: json['provider'] as String? ?? '',
        amount: json['amount'] as String? ?? '',
      );
}

/// Manual payment instructions (crypto address / bank details) rendered as a
/// key-value grid. [details] is a free-form map so any provider's fields show.
@immutable
class PaymentInstructions {
  const PaymentInstructions({
    required this.methodId,
    required this.name,
    required this.type,
    required this.details,
    required this.qrUrl,
  });

  final int methodId;
  final String name;
  final String type;
  final Map<String, String> details;
  final String? qrUrl;

  /// The free-text step, pulled out of [details] so it can render full-width.
  String get instructionsText => details['instructions'] ?? '';

  /// Address-style rows (everything except the long instructions line).
  Map<String, String> get fields =>
      Map.fromEntries(details.entries.where((e) => e.key != 'instructions'));

  factory PaymentInstructions.fromJson(Map<String, dynamic> json) {
    final rawDetails = _map(json['details']);
    return PaymentInstructions(
      methodId: (json['method_id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      details: rawDetails.map((key, value) => MapEntry(key, '${value ?? ''}')),
      qrUrl: json['qr_url'] as String?,
    );
  }
}

List<Map<String, dynamic>> _maps(dynamic value) => value is List
    ? value.whereType<Map<String, dynamic>>().toList()
    : const [];
Map<String, dynamic> _map(dynamic value) =>
    value is Map<String, dynamic> ? value : const {};
