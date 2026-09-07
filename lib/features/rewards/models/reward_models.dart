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
  });

  final MoneySnapshot withdrawable;
  final MoneySnapshot pending;
  final MoneySnapshot paidOut;
  final ShareSnapshot yourShare;
  final List<PayoutRequirement> requirements;
  final List<RewardAccount> accounts;
  final List<String> payoutMethods;

  bool get isEmpty => requirements.isEmpty && accounts.isEmpty;

  /// Maps `GET /finance/rewards` — `data` holds `stats`, `methods`, `accounts`
  /// and `eligibility`. Money values use the preformatted display strings
  /// (`available`, `pending`, `paid`); requirements are derived from the KYC /
  /// eligibility flags in `stats`.
  factory RewardsData.fromJson(dynamic data) {
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final stats =
        map['stats'] is Map<String, dynamic> ? map['stats'] as Map<String, dynamic> : const {};

    String money(String key, String fallback) =>
        (stats[key] as String?)?.trim().isNotEmpty == true
            ? stats[key] as String
            : fallback;

    final methods = (map['methods'] as List?)
            ?.map((m) => m is Map<String, dynamic>
                ? (m['label'] ?? m['name'] ?? m['type'])?.toString()
                : m?.toString())
            .whereType<String>()
            .toList() ??
        <String>[];

    final accounts = (map['accounts'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((a) => RewardAccount.fromJson(a))
            .toList() ??
        <RewardAccount>[];

    return RewardsData(
      withdrawable: MoneySnapshot(
          amountUsd: money('available', '\$0'), tone: StatTone.green),
      pending:
          MoneySnapshot(amountUsd: money('pending', '\$0'), tone: StatTone.amber),
      paidOut:
          MoneySnapshot(amountUsd: money('paid', '\$0'), tone: StatTone.purple),
      yourShare:
          ShareSnapshot(percent: (stats['share_percent'] as num?)?.toInt() ?? 0),
      requirements: _requirementsFrom(stats, methods.isNotEmpty),
      accounts: accounts,
      payoutMethods: methods,
    );
  }

  static List<PayoutRequirement> _requirementsFrom(
    Map stats,
    bool hasMethod,
  ) {
    final kycApproved = stats['kyc_approved'] as bool? ?? false;
    final canRequest = stats['can_request'] as bool? ?? false;
    return [
      PayoutRequirement(
        label: 'KYC verified',
        value: kycApproved ? 'Verified' : 'Not Yet',
        status: kycApproved ? RequirementStatus.pass : RequirementStatus.fail,
      ),
      PayoutRequirement(
        label: 'Payout method saved',
        value: hasMethod ? 'Saved' : 'Not Yet',
        status: hasMethod ? RequirementStatus.pass : RequirementStatus.fail,
      ),
      PayoutRequirement(
        label: 'Minimum payout',
        value: (stats['min_payout'] as String?) ?? '—',
        status: canRequest ? RequirementStatus.pass : RequirementStatus.partial,
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
