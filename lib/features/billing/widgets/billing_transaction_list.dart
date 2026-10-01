import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_status_pill.dart';
import '../models/billing_models.dart';
import '../../../shared/theme/app_spacing.dart';

/// Billing history as a stack of cards. Every field is rendered in full (no
/// ellipsis): a status-coloured accent rail, icon + wrapping title with the
/// amount and status pill on the right, a tinted detail panel listing invoice
/// number, date and payment method on their own rows, and a "View invoice"
/// action when the server returned an id.
class BillingTransactionList extends StatelessWidget {
  const BillingTransactionList({super.key, required this.transactions});

  final List<BillingTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (transactions.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 16.w),
        alignment: Alignment.center,
        decoration: AppTheme.surfaceCard(scheme, radius: 18.r),
        child: Text(
          'billing.no_transactions'.tr,
          textAlign: TextAlign.center,
          style: AppText.body(fontSize: 14.sp, color: scheme.onSurfaceVariant),
        ),
      );
    }
    return Column(
      children: [
        for (final transaction in transactions)
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _TransactionCard(transaction: transaction),
          ),
      ],
    );
  }
}

Color _statusColor(BillingStatus status, ColorScheme scheme) =>
    switch (status) {
      BillingStatus.paid => AppColors.success,
      BillingStatus.awaitingPayment => AppColors.amber,
      BillingStatus.refunded => scheme.primary,
    };

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction});
  final BillingTransaction transaction;

  void _openInvoice() =>
      Get.toNamed(AppRoutes.invoiceViewer, arguments: transaction);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = transaction.isRefund ? AppColors.success : scheme.primary;
    final statusColor = _statusColor(transaction.status, scheme);

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: transaction.hasInvoice ? _openInvoice : null,
        borderRadius: BorderRadius.circular(18.r),
        child: Ink(
          decoration: AppTheme.surfaceCard(scheme, radius: 18.r),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18.r),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4.w, color: statusColor),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Header(
                            transaction: transaction,
                            tint: tint,
                            statusColor: statusColor,
                          ),
                          Gap.vMd,
                          _DetailPanel(transaction: transaction),
                          if (transaction.hasInvoice) ...[
                            10.verticalSpace,
                            _ViewInvoiceLink(color: tint),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.transaction,
    required this.tint,
    required this.statusColor,
  });

  final BillingTransaction transaction;
  final Color tint;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(transaction.icon, size: 20.w, color: tint),
        ),
        Gap.hMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.title,
                softWrap: true,
                style: AppText.subtitle(
                  fontSize: 14.sp,
                  color: scheme.onSurface,
                ).copyWith(fontWeight: FontWeight.w700, height: 1.35),
              ),
              6.verticalSpace,
              _StatusPill(status: transaction.status, color: statusColor),
            ],
          ),
        ),
        10.horizontalSpace,
        Text(
          transaction.amount,
          style: AppText.value(
            fontSize: 15.sp,
            color: transaction.isRefund ? AppColors.success : scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Invoice / date / method as label–value rows. Values wrap onto extra lines
/// instead of being cut, and rows with no data are skipped entirely.
class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.transaction});
  final BillingTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = <(IconData, String, String)>[
      if (transaction.invoiceNumber.isNotEmpty)
        (
          Icons.receipt_long_outlined,
          'billing.field_invoice'.tr,
          transaction.invoiceNumber,
        ),
      if (transaction.date.isNotEmpty)
        (Icons.event_outlined, 'billing.field_date'.tr, transaction.date),
      if (transaction.method.isNotEmpty)
        (
          Icons.account_balance_wallet_outlined,
          'billing.field_method'.tr,
          transaction.method,
        ),
    ];

    if (rows.isEmpty) {
      if (transaction.reference.isEmpty) return const SizedBox.shrink();
      return Text(
        transaction.reference,
        softWrap: true,
        style: AppText.body(fontSize: 12.sp, color: scheme.onSurfaceVariant),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Gap.vSm,
            _DetailRow(icon: rows[i].$1, label: rows[i].$2, value: rows[i].$3),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15.w, color: muted),
        Gap.hSm,
        Text(
          label,
          style: AppText.label(fontSize: 12.sp, color: muted),
        ),
        Gap.hMd,
        Expanded(
          child: Text(
            value,
            softWrap: true,
            textAlign: TextAlign.end,
            style: AppText.label(
              fontSize: 12.sp,
              color: scheme.onSurface,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.color});
  final BillingStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final labelKey = switch (status) {
      BillingStatus.paid => 'billing.status_paid',
      BillingStatus.awaitingPayment => 'billing.status_awaiting',
      BillingStatus.refunded => 'billing.status_refunded',
    };
    return AppStatusPill(label: labelKey.tr, color: color);
  }
}

class _ViewInvoiceLink extends StatelessWidget {
  const _ViewInvoiceLink({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(Icons.description_outlined, size: 15.w, color: color),
        Gap.hXs,
        Flexible(
          child: Text(
            'billing.view_invoice'.tr,
            style: AppText.label(
              fontSize: 12.sp,
              color: color,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Icon(Icons.chevron_right_rounded, size: 18.w, color: color),
      ],
    );
  }
}
