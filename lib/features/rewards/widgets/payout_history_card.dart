import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../shared/theme/app_status_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_status_pill.dart';
import '../controllers/payout_history_controller.dart';
import '../models/reward_models.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';

/// One payout request: request id + status pill, amount, method / account /
/// share details and the requested / paid dates. Shows a Cancel action when
/// the API marks the row `can_cancel`.
class PayoutHistoryCard extends StatelessWidget {
  const PayoutHistoryCard({
    super.key,
    required this.item,
    required this.onCancel,
  });

  final PayoutHistoryItem item;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = AppTheme.surfaceCard(scheme, radius: 16);
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: card.color,
        gradient: card.gradient,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _MethodIcon(type: item.methodType),
              Gap.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.requestId.isEmpty ? '#${item.id}' : item.requestId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _strong(scheme, 14.5),
                    ),
                    Gap.vXxs,
                    Text(
                      [
                        item.methodLabel,
                        item.methodType,
                      ].where((s) => s.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _muted(scheme, 12),
                    ),
                  ],
                ),
              ),
              Gap.hSm,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(item.amount, maxLines: 1, style: _strong(scheme, 16)),
                  Gap.vXs,
                  AppStatusPill(
                    label: AppStatusColors.label(item.status),
                    color: AppStatusColors.of(
                      item.status,
                      scheme,
                      info: const {'approved'},
                    ),
                  ),
                ],
              ),
            ],
          ),
          Gap.vMd,
          Divider(
            height: 1.h,
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
          10.verticalSpace,
          _DetailRow(
            label: 'rewards.payout_account'.tr,
            value: item.account.isEmpty ? '—' : item.account,
          ),
          if (item.share.isNotEmpty)
            _DetailRow(label: 'rewards.payout_share'.tr, value: item.share),
          _DetailRow(
            label: 'rewards.payout_requested_on'.tr,
            value: _formatDate(item.createdDate),
          ),
          if (item.paidDate != null)
            _DetailRow(
              label: 'rewards.payout_paid_on'.tr,
              value: _formatDate(item.paidDate),
            ),
          if (item.notes != null) ...[
            6.verticalSpace,
            Text(item.notes!, style: _muted(scheme, 12)),
          ],
          if (item.cancellable) ...[
            10.verticalSpace,
            _CancelButton(item: item, onCancel: onCancel),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime? date) =>
      date == null ? '—' : DateFormat('d MMM yyyy, HH:mm').format(date);
}

TextStyle _strong(ColorScheme scheme, double size) => AppText.base(
  fontSize: size.sp,
  fontWeight: FontWeight.w800,
  color: scheme.onSurface,
);

TextStyle _muted(ColorScheme scheme, double size) => AppText.base(
  fontSize: size.sp,
  fontWeight: FontWeight.w500,
  color: scheme.onSurfaceVariant,
);

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Text(label, style: _muted(scheme, 12)),
          Gap.hMd,
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: AppText.base(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodIcon extends StatelessWidget {
  const _MethodIcon({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final IconData icon = switch (type.toLowerCase()) {
      'bank' => Icons.account_balance_rounded,
      'usdt' || 'crypto' => Icons.currency_bitcoin_rounded,
      _ => Icons.account_balance_wallet_rounded,
    };
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.primary.withValues(alpha: 0.10),
      ),
      child: Icon(icon, size: 19.w, color: scheme.primary),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.item, required this.onCancel});
  final PayoutHistoryItem item;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<PayoutHistoryController>();
    return Obx(() {
      final busy = c.cancellingId.value == item.id;
      return OutlinedButton(
        onPressed: busy ? null : onCancel,
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.error,
          side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
          minimumSize: Size.fromHeight(38.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
        child: busy
            ? SizedBox(
                width: 16.w,
                height: 16.w,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                'rewards.history_cancel'.tr,
                style: AppText.base(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
      );
    });
  }
}
