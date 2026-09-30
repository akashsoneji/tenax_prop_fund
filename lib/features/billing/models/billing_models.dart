import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';

/// The full payload
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
      } else if (txns[i].status == BillingStatus.paid) {
        paid += minor;
      }
    }
    return BillingData(
      stats: [
        BillingStat(label: 'billing.stat_paid', value: _money(paid)),
        BillingStat(label: 'billing.stat_refunded', value: _money(refunded)),
        BillingStat(label: 'billing.stat_net', value: _money(paid - refunded)),
        BillingStat(label: 'billing.stat_invoices', value: '${rows.length}'),
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
  String get label =>
      this == BillingFilter.all ? 'billing.filter_all'.tr : labelKey.tr;

  /// Localization key for the type dropdown label.
  String get labelKey {
    switch (this) {
      case BillingFilter.all:
        return 'billing.type_all';
      case BillingFilter.challenge:
        return 'billing.type_challenge';
      case BillingFilter.addOn:
        return 'billing.type_addon';
      case BillingFilter.refund:
        return 'billing.type_refund';
    }
  }
}

/// Optional server-side status filter for `GET /finance/transactions?status=`.
enum BillingStatusFilter { all, paid, pending, refunded, failed }

extension BillingStatusFilterX on BillingStatusFilter {
  /// The value sent to the API (`status` query param).
  String get apiValue => name;

  /// Localization key for the dropdown label.
  String get labelKey {
    switch (this) {
      case BillingStatusFilter.all:
        return 'billing.status_all';
      case BillingStatusFilter.paid:
        return 'billing.status_paid';
      case BillingStatusFilter.pending:
        return 'billing.status_pending';
      case BillingStatusFilter.refunded:
        return 'billing.status_refunded';
      case BillingStatusFilter.failed:
        return 'billing.status_failed';
    }
  }
}

/// One row in the billing transaction list.
class BillingTransaction {
  const BillingTransaction({
    required this.id,
    required this.invoiceNumber,
    required this.title,
    required this.reference,
    required this.amount,
    required this.status,
    required this.category,
    this.date = '',
    this.method = '',
  });

  /// Transaction id used by `GET /finance/transactions/{id}/invoice`.
  final String id;

  /// e.g. "INV-4SNZ5BF" — shown as the invoice viewer's title.
  final String invoiceNumber;

  final String title;

  /// e.g. "INV-100482 · Aug 2 · Visa ··4821".
  final String reference;

  /// e.g. "$335" or "-$69".
  final String amount;

  final BillingStatus status;
  final BillingFilter category;

  /// Creation date as `YYYY-MM-DD`; empty when the API omits it.
  final String date;

  /// Payment method label, e.g. "Visa ··4821"; empty when unknown.
  final String method;

  /// Maps one row of the `/finance/transactions` array.
  factory BillingTransaction.fromJson(Map<String, dynamic> json) {
    final status = _statusFrom(json['status'] as String?);
    return BillingTransaction(
      id: json['id']?.toString() ?? '',
      invoiceNumber: (json['invoice'] as String?)?.trim() ?? '',
      title: (json['description'] as String?)?.trim().isNotEmpty == true
          ? json['description'] as String
          : (json['number'] as String? ?? '—'),
      reference: _reference(json),
      amount: (json['total'] as String?)?.trim().isNotEmpty == true
          ? json['total'] as String
          : (json['total_minor'] as num?)?.toString() ?? '—',
      status: status,
      category: _categoryFrom(json['item_type'] as String?, status),
      date: (json['created_at'] as String?)?.split('T').first.trim() ?? '',
      method: (json['method'] as String?)?.trim() ?? '',
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
      case 'awaiting_payment':
      case 'awaiting_proof':
      case 'pending':
        return BillingStatus.awaitingPayment;
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

  /// Rows without a server id can't fetch an invoice.
  bool get hasInvoice => id.isNotEmpty;

  IconData get icon => isRefund
      ? Icons.monetization_on_outlined
      : Icons.credit_card_rounded;
}

/// Rendered invoice from `GET /finance/transactions/{id}/invoice`:
/// `{ invoice_number, format: "html", html }`. The viewer loads [html]
/// straight into a WebView.
class InvoiceDocument {
  const InvoiceDocument({
    required this.invoiceNumber,
    required this.format,
    required this.html,
  });

  final String invoiceNumber;
  final String format;
  final String html;

  factory InvoiceDocument.fromJson(dynamic data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    return InvoiceDocument(
      invoiceNumber: map['invoice_number']?.toString() ?? '',
      format: map['format']?.toString() ?? 'html',
      html: map['html']?.toString() ?? '',
    );
  }
}

enum BillingStatus { paid, awaitingPayment, refunded }

extension BillingStatusX on BillingStatus {
  String get label {
    switch (this) {
      case BillingStatus.paid:
        return 'billing.status_paid'.tr;
      case BillingStatus.awaitingPayment:
        return 'billing.status_awaiting'.tr;
      case BillingStatus.refunded:
        return 'billing.status_refunded'.tr;
    }
  }

  Color get color {
    switch (this) {
      case BillingStatus.paid:
        return AppColors.inkMutedLight;
      case BillingStatus.awaitingPayment:
        return AppColors.amber;
      case BillingStatus.refunded:
        return AppColors.success;
    }
  }
}
