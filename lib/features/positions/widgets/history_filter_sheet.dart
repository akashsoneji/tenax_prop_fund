import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../../../shared/widgets/app_choice_chip.dart';
import '../controllers/positions_controller.dart';
import '../../../shared/theme/app_spacing.dart';

class HistoryFilterResult {
  const HistoryFilterResult({
    required this.range,
    required this.symbol,
    required this.direction,
    required this.profitFilter,
    this.from,
    this.to,
  });
  final HistoryRange range;
  final DateTime? from;
  final DateTime? to;
  final String symbol;
  final HistoryDirection direction;
  final HistoryProfitFilter profitFilter;
}

Future<HistoryFilterResult?> showHistoryFilterSheet(
  BuildContext context, {
  required HistoryRange selected,
  DateTime? from,
  DateTime? to,
  String symbol = '',
  HistoryDirection direction = HistoryDirection.all,
  HistoryProfitFilter profitFilter = HistoryProfitFilter.all,
}) => showModalBottomSheet<HistoryFilterResult>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => _HistoryFilterSheet(
    selected: selected,
    from: from,
    to: to,
    symbol: symbol,
    direction: direction,
    profitFilter: profitFilter,
  ),
);

class _HistoryFilterSheet extends StatefulWidget {
  const _HistoryFilterSheet({
    required this.selected,
    this.from,
    this.to,
    this.symbol = '',
    this.direction = HistoryDirection.all,
    this.profitFilter = HistoryProfitFilter.all,
  });
  final HistoryRange selected;
  final DateTime? from;
  final DateTime? to;
  final String symbol;
  final HistoryDirection direction;
  final HistoryProfitFilter profitFilter;
  @override
  State<_HistoryFilterSheet> createState() => _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends State<_HistoryFilterSheet> {
  late HistoryRange _range = widget.selected;
  late DateTime? _from = widget.from;
  late DateTime? _to = widget.to;
  late String _symbol = widget.symbol;
  late HistoryDirection _direction = widget.direction;
  late HistoryProfitFilter _profitFilter = widget.profitFilter;
  late final TextEditingController _symbolController = TextEditingController(
    text: _symbol,
  );
  bool get _canApply =>
      _range != HistoryRange.custom || (_from != null && _to != null);
  @override
  void dispose() {
    _symbolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      padding: EdgeInsets.fromLTRB(
        20.w,
        12.h,
        20.w,
        20.h +
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(
                    alpha: AppColors.alphaMuted,
                  ),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            Gap.vLg,
            Text(
              'positions.filter_history'.tr,
              style: AppText.title(color: scheme.onSurface, fontSize: 16.sp),
            ),
            14.verticalSpace,
            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: [
                for (final range in HistoryRange.values)
                  _RangeChip(
                    label: range.labelKey.tr,
                    selected: _range == range,
                    onTap: () => setState(() => _range = range),
                  ),
              ],
            ),
            18.verticalSpace,
            Text(
              'positions.symbol'.tr,
              style: AppText.subtitle(color: scheme.onSurface, fontSize: 13.sp),
            ),
            Gap.vSm,
            TextField(
              controller: _symbolController,
              onChanged: (value) => _symbol = value.trim(),
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'positions.all_symbols'.tr,
                prefixIcon: Icon(Icons.search_rounded, size: 20.w),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 12.h,
                ),
              ),
            ),
            14.verticalSpace,
            Text(
              'positions.direction'.tr,
              style: AppText.subtitle(color: scheme.onSurface, fontSize: 13.sp),
            ),
            Gap.vSm,
            _ChoiceRow<HistoryDirection>(
              values: HistoryDirection.values,
              selected: _direction,
              label: (value) => value.name.tr,
              onChanged: (value) => setState(() => _direction = value),
            ),
            14.verticalSpace,
            Text(
              'positions.result'.tr,
              style: AppText.subtitle(color: scheme.onSurface, fontSize: 13.sp),
            ),
            Gap.vSm,
            _ChoiceRow<HistoryProfitFilter>(
              values: HistoryProfitFilter.values,
              selected: _profitFilter,
              label: (value) => value.name.tr,
              onChanged: (value) => setState(() => _profitFilter = value),
            ),
            if (_range == HistoryRange.custom) ...[
              Gap.vLg,
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'positions.from'.tr,
                      value: _from,
                      onPick: (d) => setState(() => _from = d),
                    ),
                  ),
                  Gap.hMd,
                  Expanded(
                    child: _DateField(
                      label: 'positions.to'.tr,
                      value: _to,
                      onPick: (d) => setState(() => _to = d),
                    ),
                  ),
                ],
              ),
            ],
            22.verticalSpace,
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canApply
                    ? () => Navigator.of(context).pop(
                        HistoryFilterResult(
                          range: _range,
                          from: _from,
                          to: _to,
                          symbol: _symbol,
                          direction: _direction,
                          profitFilter: _profitFilter,
                        ),
                      )
                    : null,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  'positions.apply'.tr,
                  style: AppText.subtitle(
                    color: scheme.onPrimary,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
  });
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8.w,
    runSpacing: 8.h,
    children: [
      for (final value in values)
        _RangeChip(
          label: label(value),
          selected: value == selected,
          onTap: () => onChanged(value),
        ),
    ],
  );
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppChoiceChip(
      label: label,
      selected: selected,
      onTap: onTap,
      radius: 12,
      fontSize: 13,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
      selectedColor: scheme.onPrimary,
      unselectedColor: scheme.onSurface,
      selectedFill: scheme.primary,
      unselectedFill: Colors.transparent,
      borderColor: selected
          ? scheme.primary
          : scheme.onSurface.withValues(alpha: AppColors.alphaHairline),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
  });
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.subtitle(
            color: scheme.onSurface.withValues(alpha: AppColors.alphaMuted),
            fontSize: 12.sp,
          ),
        ),
        6.verticalSpace,
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? now,
              firstDate: DateTime(now.year - 5),
              lastDate: now,
            );
            if (picked != null) onPick(picked);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: scheme.onSurface.withValues(
                  alpha: AppColors.alphaHairline,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null
                        ? 'positions.select_date'.tr
                        : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.subtitle(
                      color: scheme.onSurface,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_outlined, size: 16.w),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
