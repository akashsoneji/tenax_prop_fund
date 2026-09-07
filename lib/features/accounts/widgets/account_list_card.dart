import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../models/accounts_models.dart';

/// One account card. Shows the plan eyebrow, login + account size headline, a
/// wrap of labelled metrics (Phase / Balance / Equity / Total P&L / Trading
/// days / Leverage / Started) and an action row (Trade · status pill ·
/// Dashboard). Adapts to light/dark via the color scheme.
class AccountListCard extends StatelessWidget {
  const AccountListCard({
    super.key,
    required this.account,
    required this.onTrade,
    required this.onDashboard,
  });

  final AccountRow account;
  final VoidCallback onTrade;
  final VoidCallback onDashboard;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.10)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            account.planName.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          _Headline(login: account.login, size: account.accountSize),
          const SizedBox(height: 16),
          Wrap(
            spacing: 22,
            runSpacing: 14,
            children: [
              _Metric(label: 'accounts.phase'.tr, value: account.phaseLabel),
              _Metric(label: 'accounts.balance'.tr, value: account.balance),
              _Metric(label: 'accounts.equity'.tr, value: account.equity),
              _Metric(
                label: 'accounts.total_pl'.tr,
                value: account.pnl,
                valueColor:
                    account.pnlNegative ? AppColors.danger : AppColors.success,
                sub: account.floatingNote,
              ),
              _Metric(
                label: 'accounts.trading_days'.tr,
                value: account.tradingDays,
              ),
              _Metric(label: 'accounts.leverage'.tr, value: account.leverage),
              _Metric(label: 'accounts.started'.tr, value: account.started),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _TradeButton(onTap: onTrade),
              const SizedBox(width: 10),
              _StatusPill(label: account.statusLabel, tone: account.tone),
              const Spacer(),
              _DashboardButton(onTap: onDashboard),
            ],
          ),
        ],
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.login, required this.size});
  final String login;
  final String size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
        children: [
          TextSpan(text: '${'accounts.login'.tr} '),
          TextSpan(
            text: login,
            style: TextStyle(color: scheme.primary),
          ),
          TextSpan(
            text: '  ·  $size',
            style: TextStyle(color: scheme.onSurface),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.valueColor,
    this.sub,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '—' : value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: valueColor ?? scheme.onSurface,
          ),
        ),
        if (sub != null && sub!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            sub!,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _TradeButton extends StatelessWidget {
  const _TradeButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.trending_up_rounded,
                  size: 17, color: AppColors.black),
              const SizedBox(width: 6),
              Text(
                'accounts.trade'.tr,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardButton extends StatelessWidget {
  const _DashboardButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(
            'accounts.dashboard'.tr,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.tone});
  final String label;
  final AccountTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (tone) {
      AccountTone.up => AppColors.success,
      AccountTone.down => AppColors.danger,
      AccountTone.neutral => scheme.onSurfaceVariant,
    };
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
