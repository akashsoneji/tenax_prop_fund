import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/positions_models.dart';

enum CloseGroup { all, profitable, losing, long, short }

List<TradePosition> positionsForGroup(
  CloseGroup group,
  List<TradePosition> positions,
) {
  return switch (group) {
    CloseGroup.all => positions,
    CloseGroup.profitable =>
      positions.where((position) => position.profitLoss > 0).toList(),
    CloseGroup.losing =>
      positions.where((position) => position.profitLoss < 0).toList(),
    CloseGroup.long => positions.where((position) => position.isBuy).toList(),
    CloseGroup.short => positions.where((position) => !position.isBuy).toList(),
  };
}

/// [positions] is read inside an [Obx], so pass a getter over the live
/// socket-backed list — the P/L totals then update tick by tick.
Future<CloseGroup?> showCloseAllSheet(
  BuildContext context, {
  required List<TradePosition> Function() positions,
}) {
  return showModalBottomSheet<CloseGroup>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CloseAllSheet(positions: positions),
  );
}

class _CloseAllSheet extends StatefulWidget {
  const _CloseAllSheet({required this.positions});

  final List<TradePosition> Function() positions;

  @override
  State<_CloseAllSheet> createState() => _CloseAllSheetState();
}

class _CloseAllSheetState extends State<_CloseAllSheet> {
  CloseGroup _selected = CloseGroup.all;

  double _totalFor(List<TradePosition> positions) => positions.fold(
        0,
        (total, position) => total + position.profitLoss,
      );

  String _labelFor(CloseGroup group) => switch (group) {
        CloseGroup.all => 'positions.all_currently_open'.tr,
        CloseGroup.profitable => 'positions.all_profitable'.tr,
        CloseGroup.losing => 'positions.all_losing'.tr,
        CloseGroup.long => 'positions.all_long'.tr,
        CloseGroup.short => 'positions.all_short'.tr,
      };

  @override
  Widget build(BuildContext context) {
    return Obx(() => _buildSheet(context, widget.positions()));
  }

  Widget _buildSheet(BuildContext context, List<TradePosition> positions) {
    final scheme = Theme.of(context).colorScheme;
    final selectedPositions = positionsForGroup(_selected, positions);
    final selectedTotal = _totalFor(selectedPositions);

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'positions.choose_close_group'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: CloseGroup.values
                      .map((group) {
                        final groupPositions =
                            positionsForGroup(group, positions);
                        return _CloseOption(
                          label: _labelFor(group),
                          total: _totalFor(groupPositions),
                          count: groupPositions.length,
                          selected: _selected == group,
                          onTap: () => setState(() => _selected = group),
                        );
                      })
                      .toList(),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size.fromHeight(48.h),
                        side: BorderSide(color: scheme.outlineVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        'positions.cancel'.tr,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: selectedPositions.isEmpty
                          ? null
                          : () => Navigator.of(context).pop(_selected),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size.fromHeight(48.h),
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        '${'positions.confirm'.tr} (${_money(selectedTotal)})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseOption extends StatelessWidget {
  const _CloseOption({
    required this.label,
    required this.total,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final double total;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profitColor = total >= 0 ? AppColors.success : AppColors.danger;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: count == 0 ? null : onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: selected
              ? AppTheme.surfaceCard(scheme, radius: 14.r).copyWith(
                  color: AppColors.danger.withValues(alpha: 0.06),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.35),
                  ),
                )
              : BoxDecoration(borderRadius: BorderRadius.circular(14.r)),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$label ($count)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: count == 0
                            ? scheme.onSurfaceVariant.withValues(alpha: 0.45)
                            : scheme.onSurface,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w400,
                      ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                _money(total),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: count == 0
                          ? scheme.onSurfaceVariant.withValues(alpha: 0.45)
                          : profitColor,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              SizedBox(width: 12.w),
              Container(
                width: 24.w,
                height: 24.w,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? AppColors.danger
                        : scheme.outlineVariant,
                    width: 2.w,
                  ),
                ),
                child: selected
                    ? const DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.danger,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _money(double value) {
  final sign = value < 0 ? '-' : '';
  return '$sign\$${value.abs().toStringAsFixed(2)}';
}
