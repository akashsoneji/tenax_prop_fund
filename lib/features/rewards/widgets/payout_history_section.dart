import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_pill.dart';
import '../controllers/rewards_controller.dart';
import '../models/reward_models.dart';

/// The payout-history section of the Rewards screen: status filter tabs
/// (all / pending / approved / disbursed), the paginated row list, and a Cancel
/// action on rows the API marks `cancellable`.
class PayoutHistorySection extends StatelessWidget {
  const PayoutHistorySection({super.key, required this.controller});

  final dynamic controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isExtended = controller is ExtendedRewardsController;
    final ext = controller is ExtendedRewardsController ? controller as ExtendedRewardsController : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'rewards.history_tab'.tr,
          style: GoogleFonts.beVietnamPro(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        SizedBox(height: 12.h),
        Obx(() {
          final state = isExtended ? ext!.history.value : null;
          final filter = state?.filter ?? 'all';
          return _HistoryTabs(
            selected: _filterFromString(filter),
            onChanged: _onFilterChanged,
          );
        }),
        SizedBox(height: 12.h),
        Obx(() {
          final state = isExtended ? ext!.history.value : null;
          if (state == null || state.items.isEmpty) return const _EmptyHistory();
          return Column(
            children: [
              for (final row in state.items)
                _HistoryRow(
                  item: row,
                  onCancel: () => _confirmCancel(context, row),
                ),
              if (state.hasNext && state.page < state.totalPages && isExtended)
                _LoadMoreButton(
                  loading: false,
                  onPressed: ext!.loadNextHistoryPage,
                ),
            ],
          );
        }),
      ],
    );
  }

  void _onFilterChanged(PayoutHistoryFilterStatus filter) {
    final statusStr = switch (filter) {
      PayoutHistoryFilterStatus.pending => 'pending',
      PayoutHistoryFilterStatus.approved => 'approved',
      PayoutHistoryFilterStatus.disbursed => 'disbursed',
      PayoutHistoryFilterStatus.cancelled => 'cancelled',
    };
    if (controller is ExtendedRewardsController) {
      (controller as ExtendedRewardsController).setHistoryFilter(statusStr);
    }
  }

  Future<void> _confirmCancel(
    BuildContext context,
    PayoutHistoryItem row,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('rewards.history_cancel_confirm'.tr),
        content: Text('${row.methodLabel} — ${row.amount}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('rewards.cancel_no'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'rewards.history_cancel'.tr,
              style: GoogleFonts.beVietnamPro(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await controller.cancelPayout(row.id);
    Get.snackbar(
      result.success ? 'rewards.history_cancel_success'.tr : 'rewards.cancel_failed'.tr,
      result.message ?? '',
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.all(16.w),
      borderRadius: 14.r,
    );
    if (result.success) {
      final filter = (controller as ExtendedRewardsController).history.value?.filter ?? 'all';
      (controller as ExtendedRewardsController).loadHistory(status: filter, page: 1);
    }
  }

  PayoutHistoryFilterStatus _filterFromString(String value) {
    switch (value) {
      case 'pending':
        return PayoutHistoryFilterStatus.pending;
      case 'approved':
        return PayoutHistoryFilterStatus.approved;
      case 'disbursed':
        return PayoutHistoryFilterStatus.disbursed;
      case 'cancelled':
        return PayoutHistoryFilterStatus.cancelled;
      default:
        return PayoutHistoryFilterStatus.pending;
    }
  }
}

class _HistoryTabs extends StatelessWidget {
  const _HistoryTabs({required this.selected, required this.onChanged});

  final PayoutHistoryFilterStatus selected;
  final ValueChanged<PayoutHistoryFilterStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tabs = <PayoutHistoryFilterStatus>[
      PayoutHistoryFilterStatus.pending,
      PayoutHistoryFilterStatus.approved,
      PayoutHistoryFilterStatus.disbursed,
      PayoutHistoryFilterStatus.cancelled,
    ];
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          for (final f in tabs)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.symmetric(vertical: 9.h),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: f == selected
                        ? scheme.primary
                        : AppColors.transparent,
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                  child: Text(
                    f.labelKey,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: f == selected
                          ? AppColors.white
                          : scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item, required this.onCancel});

  final PayoutHistoryItem item;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.methodLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  item.createdAt,
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
                '${item.currency} ${item.amount}',
                maxLines: 1,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              SizedBox(height: 6.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppPill(
                    label: _statusLabel(item.status).tr,
                    color: _statusColor(item.status),
                    bgAlpha: 10,
                    fontSize: 11.5,
                  ),
                  if (item.cancellable) ...[
                    SizedBox(width: 6.w),
                    GestureDetector(
                      onTap: onCancel,
                      child: Text(
                        'rewards.history_cancel'.tr,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'rewards.history_status_pending';
      case 'approved':
        return 'rewards.history_status_approved';
      case 'disbursed':
        return 'rewards.history_status_disbursed';
      case 'cancelled':
        return 'rewards.history_status_cancelled';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.amber;
      case 'approved':
        return AppColors.info;
      case 'disbursed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.info;
    }
  }
}

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: loading ? null : onPressed,
      child: Text(
        loading ? 'rewards.loading_more'.tr : 'rewards.load_more'.tr,
        style: GoogleFonts.beVietnamPro(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: scheme.primary,
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 26.h),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 36.w, color: scheme.onSurfaceVariant),
          SizedBox(height: 10.h),
          Text(
            'rewards.history_empty'.tr,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'rewards.history_empty_body'.tr,
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12.sp,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
