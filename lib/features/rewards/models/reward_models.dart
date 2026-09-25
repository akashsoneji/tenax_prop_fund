import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

/// The full payload
/// holds a single `DataState<RewardsData>` instead of several loosely-related
/// Rx fields.
class RewardsData {
  const RewardsData({
    required this.withdrawable,
    required this.pending,
    required this.paidOut,
    required this.yourShare,
    required this.requirements,
    required this.accounts,
    required this.payoutMethods,
    required this.canRequestPayout,
    required this.availableMinor,
    required this.minPayoutMinor,
    required this.minPayout,
  });

  final MoneySnapshot withdrawable;
  final MoneySnapshot pending;
  final MoneySnapshot paidOut;
  final ShareSnapshot yourShare;
  final List<PayoutRequirement> requirements;
  final List<RewardAccount> accounts;
  final List<RewardPayoutMethod> payoutMethods;

  /// Raw API `stats.can_request` (KYC + method + minimum all satisfied).
  final bool canRequestPayout;

  /// `stats.available_minor` — withdrawable balance in cents.
  final int availableMinor;

  /// `stats.min_payout_minor` — minimum payout in cents.
  final int minPayoutMinor;

  /// `stats.min_payout` — formatted display string (e.g. "USD 1.00").
  final String minPayout;

  /// Available balance has reached the minimum payout (compared in minor
  /// units, never on the formatted strings).
  bool get meetsMinimumPayout =>
      minPayoutMinor > 0 && availableMinor >= minPayoutMinor;

  bool get isEmpty => requirements.isEmpty && accounts.isEmpty;

  /// Maps `GET /finance/rewards` — `data` holds `stats`, `methods`, `accounts`
  /// and `eligibility`. Money values use the preformatted display strings
  /// (`available`, `pending`, `paid`); comparisons use the `_minor` integers.
  factory RewardsData.fromJson(dynamic data) {
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final stats =
        map['stats'] is Map<String, dynamic> ? map['stats'] as Map<String, dynamic> : const {};

    String money(String key, String fallback) =>
        (stats[key] as String?)?.trim().isNotEmpty == true
            ? stats[key] as String
            : fallback;

    final methods = (map['methods'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(RewardPayoutMethod.fromJson)
            .toList() ??
        <RewardPayoutMethod>[];

    final accounts = (map['accounts'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((a) => RewardAccount.fromJson(a))
            .toList() ??
        <RewardAccount>[];

    final availableMinor = (stats['available_minor'] as num?)?.toInt() ?? 0;
    final minPayoutMinor = (stats['min_payout_minor'] as num?)?.toInt() ?? 0;

    return RewardsData(
      withdrawable: MoneySnapshot(
          amountUsd: money('available', '\$0'), tone: StatTone.green),
      pending:
          MoneySnapshot(amountUsd: money('pending', '\$0'), tone: StatTone.amber),
      paidOut:
          MoneySnapshot(amountUsd: money('paid', '\$0'), tone: StatTone.purple),
      yourShare:
          ShareSnapshot(percent: (stats['share_percent'] as num?)?.toInt() ?? 0),
      requirements: _requirementsFrom(
        stats,
        hasMethod: methods.isNotEmpty,
        meetsMinimum: minPayoutMinor > 0 && availableMinor >= minPayoutMinor,
      ),
      accounts: accounts,
      payoutMethods: methods,
      canRequestPayout: stats['can_request'] as bool? ?? false,
      availableMinor: availableMinor,
      minPayoutMinor: minPayoutMinor,
      minPayout: money('min_payout', '—'),
    );
  }

  static List<PayoutRequirement> _requirementsFrom(
    Map stats, {
    required bool hasMethod,
    required bool meetsMinimum,
  }) {
    final kycApproved = stats['kyc_approved'] as bool? ?? false;
    return [
      PayoutRequirement(
        label: 'rewards.req_kyc_verified',
        value: kycApproved ? 'rewards.req_verified' : 'rewards.req_not_yet',
        status: kycApproved ? RequirementStatus.pass : RequirementStatus.fail,
      ),
      PayoutRequirement(
        label: 'rewards.req_payout_method',
        value: hasMethod ? 'rewards.req_saved' : 'rewards.req_not_yet',
        status: hasMethod ? RequirementStatus.pass : RequirementStatus.fail,
      ),
      PayoutRequirement(
        label: 'rewards.req_minimum_payout',
        value: (stats['min_payout'] as String?) ?? '—',
        status: meetsMinimum ? RequirementStatus.pass : RequirementStatus.partial,
      ),
    ];
  }
}

enum StatTone { green, amber, purple, blue }

class MoneySnapshot {
  const MoneySnapshot({required this.amountUsd, required this.tone});
  final String amountUsd;
  final StatTone tone;
}

class ShareSnapshot {
  const ShareSnapshot({required this.percent});
  final int percent;
}

class RewardPayoutMethod {
  const RewardPayoutMethod({required this.id, required this.label});

  final String id;
  final String label;

  factory RewardPayoutMethod.fromJson(Map<String, dynamic> json) {
    return RewardPayoutMethod(
      id: json['id']?.toString() ?? '',
      label: (json['label'] ?? json['name'] ?? json['type'] ?? 'Payout method').toString(),
    );
  }
}

/// A single payout-requirement row in the "What stands between you and a
/// payout" card.
class PayoutRequirement {
  const PayoutRequirement({
    required this.label,
    required this.value,
    required this.status,
  });

  final String label;
  final String value;

  /// Drives the trailing pill colour (green = pass, red = fail, amber = partial).
  final RequirementStatus status;
}

enum RequirementStatus { pass, fail, partial }

/// One field definition inside a method type (bank / usdt / upi).
class MethodFieldDef {
  const MethodFieldDef({
    required this.key,
    required this.label,
    required this.type,
    required this.isRequired,
    this.placeholder,
  });
  final String key;
  final String label;
  final String type;
  final bool isRequired;
  final String? placeholder;

  factory MethodFieldDef.fromJson(Map<String, dynamic> json) =>
      MethodFieldDef(
        key: json['key'] as String? ?? '',
        label: json['label'] as String? ?? '',
        type: json['type'] as String? ?? 'text',
        isRequired: json['required'] as bool? ?? false,
        placeholder: json['placeholder'] as String?,
      );
}

/// One payout-method type entry returned by GET /finance/method-types.
class PayoutMethodType {
  const PayoutMethodType({
    required this.value,
    required this.label,
    required this.fields,
  });
  final String value;
  final String label;
  final List<MethodFieldDef> fields;

  factory PayoutMethodType.fromJson(Map<String, dynamic> json) =>
      PayoutMethodType(
        value: json['value']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        fields: (json['fields'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(MethodFieldDef.fromJson)
                .toList() ??
            <MethodFieldDef>[],
      );
}

/// Full method-types response.
class MethodTypesResponse {
  const MethodTypesResponse({required this.methodTypes});
  final List<PayoutMethodType> methodTypes;

  factory MethodTypesResponse.fromJson(Map<String, dynamic> json) =>
      MethodTypesResponse(
        methodTypes: (json['method_types'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(PayoutMethodType.fromJson)
                .toList() ??
            <PayoutMethodType>[],
      );
}

/// One row of `GET /finance/payouts`. `amount` / `share` arrive pre-formatted
/// by the server (e.g. "USD 1.00"), so they are shown as-is.
class PayoutHistoryItem {
  const PayoutHistoryItem({
    required this.id,
    required this.status,
    required this.amount,
    required this.currency,
    required this.methodLabel,
    required this.createdAt,
    this.requestId = '',
    this.account = '',
    this.share = '',
    this.methodType = '',
    this.paidAt,
    this.updatedAt,
    this.notes,
    this.cancellable = false,
  });
  final int id;
  final String status;
  final String amount;
  final String currency;
  final String methodLabel;
  final String createdAt;
  final String requestId;
  final String account;
  final String share;
  final String methodType;
  final String? paidAt;
  final String? updatedAt;
  final String? notes;
  final bool cancellable;

  DateTime? get createdDate => DateTime.tryParse(createdAt)?.toLocal();
  DateTime? get paidDate =>
      paidAt == null ? null : DateTime.tryParse(paidAt!)?.toLocal();

  factory PayoutHistoryItem.fromJson(Map<String, dynamic> json) {
    final notes = json['notes']?.toString();
    return PayoutHistoryItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'USD',
      methodLabel: json['method']?.toString() ??
          json['method_label']?.toString() ??
          json['payout_method']?['label']?.toString() ??
          '',
      createdAt: json['created_at']?.toString() ?? '',
      requestId: json['request_id']?.toString() ?? '',
      account: json['account']?.toString() ?? '',
      share: json['share']?.toString() ?? '',
      methodType: json['type']?.toString() ?? '',
      paidAt: json['paid_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      notes: (notes == null || notes.trim().isEmpty) ? null : notes,
      cancellable:
          json['can_cancel'] as bool? ?? json['cancellable'] as bool? ?? false,
    );
  }
}

/// Paginated payouts list.
class PayoutsPage {
  const PayoutsPage({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
  });
  final List<PayoutHistoryItem> items;
  final int currentPage;
  final int totalPages;
  final bool hasNext;

  factory PayoutsPage.fromJson(Map<String, dynamic> json) => PayoutsPage(
        items: (json['payouts'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(PayoutHistoryItem.fromJson)
                .toList() ??
            <PayoutHistoryItem>[],
        currentPage: json['meta']?['current_page'] as int? ?? 1,
        totalPages: json['meta']?['total_pages'] as int? ?? 1,
        hasNext: json['meta']?['has_next'] as bool? ?? false,
      );
}

/// Account entry shown in the Request-a-payout sheet's account picker.
class RewardAccount {
  const RewardAccount({
    required this.id,
    required this.label,
    required this.status,
  });

  final String id;
  final String label;
  final AccountStatus status;

  /// Maps one entry of `data.accounts`, e.g.
  /// `{"id":1,"label":"#2000000 · challenge"}`. The API carries no status flag
  /// on the account, so the label text is inspected for a hint and otherwise
  /// defaults to evaluation.
  factory RewardAccount.fromJson(Map<String, dynamic> json) {
    final label = (json['label'] as String?) ?? '';
    final lower = label.toLowerCase();
    final status = lower.contains('funded')
        ? AccountStatus.funded
        : lower.contains('breach')
            ? AccountStatus.breached
            : AccountStatus.evaluation;
    return RewardAccount(
      id: json['id']?.toString() ?? '',
      label: label,
      status: status,
    );
  }
}

enum AccountStatus { funded, evaluation, breached }

enum PayoutHistoryFilter {
  all('rewards.history_filter_all'),
  pending('rewards.history_filter_pending'),
  approved('rewards.history_filter_approved'),
  disbursed('rewards.history_filter_disbursed');

  const PayoutHistoryFilter(this.labelKey);
  final String labelKey;
}

class PayoutHistoryRow {
  const PayoutHistoryRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
    required this.canCancel,
    required this.payoutId,
  });
  final String title;
  final String subtitle;
  final String amount;
  final PayoutHistoryFilterStatus status;
  final bool canCancel;
  final int payoutId;
}

enum PayoutHistoryFilterStatus { pending, approved, disbursed, cancelled }

extension PayoutHistoryFilterStatusLabel on PayoutHistoryFilterStatus {
  String get labelKey {
    switch (this) {
      case PayoutHistoryFilterStatus.pending:
        return 'rewards.history_status_pending';
      case PayoutHistoryFilterStatus.approved:
        return 'rewards.history_status_approved';
      case PayoutHistoryFilterStatus.disbursed:
        return 'rewards.history_status_disbursed';
      case PayoutHistoryFilterStatus.cancelled:
        return 'rewards.history_status_cancelled';
    }
  }
  Color get color {
    switch (this) {
      case PayoutHistoryFilterStatus.pending:
        return AppColors.amber;
      case PayoutHistoryFilterStatus.approved:
        return AppColors.info;
      case PayoutHistoryFilterStatus.disbursed:
        return AppColors.success;
      case PayoutHistoryFilterStatus.cancelled:
        return AppColors.danger;
    }
  }
}

extension AccountStatusLabel on AccountStatus {
  String get label {
    switch (this) {
      case AccountStatus.funded:
        return 'Funded';
      case AccountStatus.evaluation:
        return 'Evaluation';
      case AccountStatus.breached:
        return 'Breached';
    }
  }
}

extension RequirementStatusColor on RequirementStatus {
  Color get color {
    switch (this) {
      case RequirementStatus.pass:
        return AppColors.success; // green
      case RequirementStatus.fail:
        return AppColors.danger; // red
      case RequirementStatus.partial:
        return AppColors.amber; // amber
    }
  }
}
