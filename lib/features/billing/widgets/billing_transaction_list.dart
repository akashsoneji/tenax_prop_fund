import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/routes/app_routes.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/billing_models.dart';

/// The billing transaction list card: a leading icon (card for a payment, a
/// dollar circle for a refund), title + reference, and a trailing amount with
/// its Paid/Refunded status. Refund amounts render green.
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
        decoration: AppTheme.surfaceCard(scheme, radius: 18),
        child: Text(
          'billing.no_transactions'.tr,
          style: GoogleFonts.beVietnamPro(
            fontSize: 14.sp,
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      );
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: AppTheme.surfaceCard(scheme, radius: 18),
      child: Column(
        children: [
          for (var i = 0; i < transactions.length; i++) ...[
            _TransactionRow(transaction: transactions[i]),
            if (i < transactions.length - 1)
              Divider(
                height: 1.h,
                thickness: 1,
                color: scheme.onSurface.withValues(alpha: 0.06),
              ),
          ],
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});
  final BillingTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final refund = transaction.isRefund;
    final tint = refund ? AppColors.success : scheme.primary;
    return InkWell(
      onTap: transaction.hasInvoice
          ? () => Get.toNamed(AppRoutes.invoiceViewer, arguments: transaction)
          : null,
      child: Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11.r),
            ),
            alignment: Alignment.center,
            child: Icon(transaction.icon, size: 20.w, color: tint),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  transaction.reference,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12.sp,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.amount,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: refund ? AppColors.success : scheme.onSurface,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                transaction.status.label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: refund
                      ? AppColors.success
                      : scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
