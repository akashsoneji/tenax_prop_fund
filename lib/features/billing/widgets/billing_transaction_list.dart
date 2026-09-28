import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/billing_models.dart';

/// Billing history as a stack of cards: icon + title + reference on top,
/// amount on the right, and a footer with a coloured status pill and a
/// "View invoice" action that opens the invoice viewer.
class BillingTransactionList extends StatelessWidget {
  const BillingTransactionList({super.key, required this.transactions});

  final List<BillingTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (transactions.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 32.h),
        alignment: Alignment.center,
        decoration: AppTheme.surfaceCard(scheme, radius: 18.r),
        child: Text(
          'billing.no_transactions'.tr,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14.sp,
                color: scheme.onSurfaceVariant,
              ),
        ),
      );
    }
    return Column(
      children: [
        for (final transaction in transactions)
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: _TransactionCard(transaction: transaction),
          ),
      ],
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction});
  final BillingTransaction transaction;

  void _openInvoice() =>
      Get.toNamed(AppRoutes.invoiceViewer, arguments: transaction);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tint = transaction.isRefund ? AppColors.success : scheme.primary;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: transaction.hasInvoice ? _openInvoice : null,
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
          decoration: AppTheme.surfaceCard(scheme, radius: 16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(11.r),
                    ),
                    child: Icon(transaction.icon, size: 20.w, color: tint),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall?.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            color: scheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          transaction.reference,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            fontSize: 11.5.sp,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    transaction.amount,
                    maxLines: 1,
                    style: text.titleSmall?.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: transaction.isRefund
                          ? AppColors.success
                          : scheme.onSurface,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Divider(height: 1.h, color: scheme.outlineVariant),
              SizedBox(height: 10.h),
              Row(
                children: [
                  _StatusPill(status: transaction.status),
                  const Spacer(),
                  if (transaction.hasInvoice) _ViewInvoiceLink(color: tint),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final BillingStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (color, labelKey) = switch (status) {
      BillingStatus.paid => (AppColors.success, 'billing.status_paid'),
      BillingStatus.awaitingPayment => (
          AppColors.amber,
          'billing.status_awaiting'
        ),
      BillingStatus.refunded => (scheme.primary, 'billing.status_refunded'),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 6.w),
          Text(
            labelKey.tr,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _ViewInvoiceLink extends StatelessWidget {
  const _ViewInvoiceLink({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.description_outlined, size: 15.w, color: color),
        SizedBox(width: 4.w),
        Text(
          'billing.view_invoice'.tr,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
        Icon(Icons.chevron_right_rounded, size: 18.w, color: color),
      ],
    );
  }
}
