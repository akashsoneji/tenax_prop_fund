import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/account_models.dart';

/// Status pill used across the account tabs.
class AccountStatusPill extends StatelessWidget {
  const AccountStatusPill({super.key, required this.label, required this.tone});
  final String label;
  final AccountTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (label.isEmpty) return const SizedBox.shrink();
    final color = switch (tone) {
      AccountTone.up => AppColors.success,
      AccountTone.down => AppColors.danger,
      AccountTone.neutral => scheme.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

/// "Hello test" facts checklist + Account details (credentials) + Cycle details.
class AccountHeaderCard extends StatelessWidget {
  const AccountHeaderCard({
    super.key,
    required this.header,
    required this.credentials,
    required this.cycle,
    required this.revealed,
    required this.onReveal,
    required this.onCopyLogin,
  });

  final AccountHeader header;
  final AccountCredentials credentials;
  final AccountCycle cycle;
  final bool revealed;
  final VoidCallback onReveal;
  final VoidCallback onCopyLogin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.surfaceCard(scheme, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHead(icon: Icons.person_outline_rounded, text: 'account.plan_facts'.tr),
          const SizedBox(height: 12),
          _Fact(text: '${'account.initial_balance'.tr}: ${header.initialBalance}'),
          _Fact(text: '${'account.leverage'.tr}: ${header.leverageLabel}'),
          _Fact(text: '${'account.plan'.tr}: ${header.planLabel}'),
          if (header.drawdownType.isNotEmpty)
            _Fact(text: '${header.phaseLabel} · ${header.drawdownType}'),
          if (header.accountType.isNotEmpty)
            _Fact(text: '${'account.account_type'.tr}: ${header.accountType}'),
          const Divider(height: 28),
          _SectionHead(icon: Icons.shield_outlined, text: 'account.account_details'.tr),
          const SizedBox(height: 12),
          _CredRow(
            label: 'account.login'.tr,
            value: credentials.login,
            trailingLabel: 'account.copy'.tr,
            onTrailing: onCopyLogin,
          ),
          const SizedBox(height: 10),
          _CredRow(
            label: 'account.master_password'.tr,
            value: revealed ? credentials.password : '••••••••••',
            trailingLabel: revealed ? 'account.hide'.tr : 'account.reveal'.tr,
            onTrailing: onReveal,
          ),
          const SizedBox(height: 10),
          _CredRow(
            label: 'account.investor_password'.tr,
            value: revealed ? credentials.investorPassword : '••••••••••',
            trailingLabel: revealed ? 'account.hide'.tr : 'account.reveal'.tr,
            onTrailing: onReveal,
          ),
          const SizedBox(height: 10),
          _CredRow(label: 'account.server'.tr, value: credentials.server),
          const Divider(height: 28),
          _SectionHead(icon: Icons.schedule_rounded, text: 'account.cycle_details'.tr),
          const SizedBox(height: 12),
          _Kv(k: 'account.phase_started'.tr, v: cycle.phaseStarted),
          _Kv(k: 'account.days_elapsed'.tr, v: '${cycle.daysElapsed}'),
          _Kv(k: 'account.time_limit'.tr, v: cycle.timeLimit),
          _Kv(k: 'account.next_reward'.tr, v: cycle.nextReward),
        ],
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 17, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _CredRow extends StatelessWidget {
  const _CredRow({
    required this.label,
    required this.value,
    this.trailingLabel,
    this.onTrailing,
  });

  final String label;
  final String value;
  final String? trailingLabel;
  final VoidCallback? onTrailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant)),
                const SizedBox(height: 3),
                Text(value,
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface)),
              ],
            ),
          ),
          if (trailingLabel != null)
            GestureDetector(
              onTap: onTrailing,
              behavior: HitTestBehavior.opaque,
              child: Text(
                trailingLabel!,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary),
              ),
            ),
        ],
      ),
    );
  }
}

class _Kv extends StatelessWidget {
  const _Kv({required this.k, required this.v});
  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(k,
                style: TextStyle(
                    fontSize: 13, color: scheme.onSurfaceVariant)),
          ),
          Text(v,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface)),
        ],
      ),
    );
  }
}

/// 2×2 grid of KPI stat cards.
class AccountStatGrid extends StatelessWidget {
  const AccountStatGrid({super.key, required this.stats});
  final List<AccountStat> stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [for (final s in stats) _StatCard(stat: s)],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});
  final AccountStat stat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final valueColor = switch (stat.tone) {
      AccountTone.up => AppColors.success,
      AccountTone.down => AppColors.danger,
      AccountTone.neutral => scheme.onSurface,
    };
    final icon = switch (stat.icon) {
      AccountStatIcon.dollar => Icons.attach_money_rounded,
      AccountStatIcon.chart => Icons.show_chart_rounded,
      AccountStatIcon.activity => Icons.multiline_chart_rounded,
      AccountStatIcon.calendar => Icons.calendar_today_rounded,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: valueColor),
          ),
          Text(
            stat.label.tr,
            style: TextStyle(
                fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// One objective card (label + status + detail lines).
class AccountObjectiveCard extends StatelessWidget {
  const AccountObjectiveCard({super.key, required this.objective});
  final AccountObjective objective;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final passed = objective.passed;
    final statusColor = passed ? AppColors.success : AppColors.amber;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                passed
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_checked_rounded,
                size: 18,
                color: passed ? AppColors.success : scheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  objective.label,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  objective.status,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final line in objective.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: TextStyle(
                    fontSize: 12.5, color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

/// The dark "Account health" card (Consistency / Quick strike / Hyperactivity).
class AccountHealthCard extends StatelessWidget {
  const AccountHealthCard({super.key, required this.health});
  final List<AccountHealth> health;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.heroInkDeep,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('account.account_health'.tr,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white)),
          const SizedBox(height: 4),
          Text('account.account_health_sub'.tr,
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.white.withValues(alpha: 0.6))),
          const SizedBox(height: 14),
          for (final h in health) ...[
            _HealthRow(health: h),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({required this.health});
  final AccountHealth health;

  @override
  Widget build(BuildContext context) {
    final color = health.watch ? AppColors.amber : AppColors.success;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(health.name,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white)),
              ),
              Text(health.status,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Text(health.note,
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.white.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}
