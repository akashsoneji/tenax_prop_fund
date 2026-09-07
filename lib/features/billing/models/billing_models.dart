import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

/// The full payload the Billing history screen needs
/// controller holds a single `DataState<BillingData>` instead of several
/// loosely-related Rx lists.
class BillingData {
  const BillingData({
    required this.stats,
    required this.transactions,
  });

  final List<BillingStat> stats;
  final List<BillingTransaction> transactions;

  bool get isEmpty => stats.isEmpty && transactions.isEmpty;

  /// Maps `GET /finance/transactions` — `data` is the JSON array of rows; the
  /// hero stat grid is derived client-side from `total_minor` (the API has no
  /// summary block).
  factory BillingData.fromJson(dynamic data) {
    final rows = data is List
        ? data.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];
    final txns = rows.map((r) => BillingTransaction.fromJson(r)).toList();
    var paid = 0;
    var refunded = 0;
    for (var i = 0; i < rows.length; i++) {
      final minor = (rows[i]['total_minor'] as num?)?.toInt() ?? 0;
      if (txns[i].status == BillingStatus.refunded) {
        refunded += minor;
      } else {
        paid += minor;
      }
    }
    return BillingData(
      stats: [
        BillingStat(label: 'Paid', value: _money(paid)),
        BillingStat(label: 'Refunded', value: _money(refunded)),
        BillingStat(label: 'Net', value: _money(paid - refunded)),
        BillingStat(label: 'Invoices', value: '${rows.length}'),
      ],
      transactions: txns,
    );
  }

  static String _money(int cents) {
    final v = cents / 100;
    return '\$${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)}';
  }
}

/// A summary metric shown in the 2x2 grid on the Billing history hero.
class BillingStat {
  const BillingStat({required this.label, required this.value});
  final String label;
  final String value;
}

/// The filter tabs above the transaction list.
enum BillingFilter { all, challenge, addOn, refund }

extension BillingFilterX on BillingFilter {
  String get label {
    switch (this) {
      case BillingFilter.all:
        return 'All';
      case BillingFilter.challenge:
        return 'Challenge';
      case BillingFilter.addOn:
        return 'Add-on';
      case BillingFilter.refund:
        return 'Refund';
    }
  }
}

/// One row in the billing transaction list.
class BillingTransaction {
  const BillingTransaction({
    required this.title,
    required this.reference,
    required this.amount,
    required this.status,
    required this.category,
  });

  final String title;

  /// e.g. "INV-100482 · Aug 2 · Visa ··4821".
  final String reference;

  /// e.g. "$335" or "-$69".
  final String amount;

  final BillingStatus status;
  final BillingFilter category;

  /// Maps one row of the `/finance/transactions` array.
  factory BillingTransaction.fromJson(Map<String, dynamic> json) {
    final status = _statusFrom(json['status'] as String?);
    return BillingTransaction(
      title: (json['description'] as String?)?.trim().isNotEmpty == true
          ? json['description'] as String
          : (json['number'] as String? ?? '—'),
      reference: _reference(json),
      amount: (json['total'] as String?)?.trim().isNotEmpty == true
          ? json['total'] as String
          : (json['total_minor'] as num?)?.toString() ?? '—',
      status: status,
      category: _categoryFrom(json['item_type'] as String?, status),
    );
  }

  static String _reference(Map<String, dynamic> json) {
    final parts = <String>[
      if ((json['invoice'] as String?)?.isNotEmpty == true)
        json['invoice'] as String,
      if ((json['created_at'] as String?)?.isNotEmpty == true)
        (json['created_at'] as String).split('T').first,
      if ((json['method'] as String?)?.isNotEmpty == true)
        json['method'] as String,
    ];
    return parts.join(' · ');
  }

  static BillingStatus _statusFrom(String? raw) {
    switch (raw) {
      case 'refunded':
        return BillingStatus.refunded;
      default:
        return BillingStatus.paid;
    }
  }

  static BillingFilter _categoryFrom(String? itemType, BillingStatus status) {
    if (status == BillingStatus.refunded) return BillingFilter.refund;
    switch (itemType) {
      case 'addon':
      case 'add_on':
        return BillingFilter.addOn;
      case 'plan_version':
      case 'plan':
      case 'challenge':
        return BillingFilter.challenge;
      default:
        return BillingFilter.challenge;
    }
  }

  bool get isRefund => status == BillingStatus.refunded;

  IconData get icon => isRefund
      ? Icons.monetization_on_outlined
      : Icons.credit_card_rounded;
}

enum BillingStatus { paid, refunded }

extension BillingStatusX on BillingStatus {
  String get label {
    switch (this) {
      case BillingStatus.paid:
        return 'Paid';
      case BillingStatus.refunded:
        return 'Refunded';
    }
  }

  Color get color {
    switch (this) {
      case BillingStatus.paid:
        return AppColors.inkMutedLight;
      case BillingStatus.refunded:
        return AppColors.success;
    }
  }
}
