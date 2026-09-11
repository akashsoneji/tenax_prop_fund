import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/theme/app_colors.dart';

/// Live Bid/Ask pill shown in the Pending Order app bar.
class PendingOrderQuotePill extends StatelessWidget {
  const PendingOrderQuotePill({
    super.key,
    required this.bid,
    required this.ask,
    required this.digits,
    required this.bidLabel,
    required this.askLabel,
  });

  final double bid;
  final double ask;
  final int digits;
  final String bidLabel;
  final String askLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.only(right: 12.w),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: AppColors.alphaFaint),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuoteCell(
            label: bidLabel,
            value: bid.toStringAsFixed(digits),
            valueColor: AppColors.danger,
          ),
          SizedBox(width: 8.w),
          Container(
            width: 1.w,
            height: 22.h,
            color: scheme.outlineVariant.withValues(
              alpha: AppColors.alphaFaint,
            ),
          ),
          SizedBox(width: 8.w),
          _QuoteCell(
            label: askLabel,
            value: ask.toStringAsFixed(digits),
            valueColor: scheme.primary,
          ),
        ],
      ),
    );
  }
}

class _QuoteCell extends StatelessWidget {
  const _QuoteCell({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            fontSize: 9.5.sp,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          value,
          style: textTheme.titleSmall?.copyWith(
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w800,
            color: valueColor,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

/// Icon + title + trailing control row used above every ticket section.
class PendingOrderSectionHeader extends StatelessWidget {
  const PendingOrderSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 28.w,
          height: 28.w,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: AppColors.alphaHairline),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: scheme.outlineVariant.withValues(
                alpha: AppColors.alphaFaint,
              ),
            ),
          ),
          child: Icon(icon, color: scheme.primary, size: 16.w),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        trailing,
      ],
    );
  }
}

/// Horizontally scrollable lot presets (0.01 / 0.10 / 0.50 / 1.00).
class PendingOrderLotPresets extends StatelessWidget {
  const PendingOrderLotPresets({
    super.key,
    required this.presets,
    required this.volume,
    required this.maxWidth,
    required this.onSelected,
  });

  final List<double> presets;
  final double volume;
  final double maxWidth;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: maxWidth,
      height: 30.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: presets.length,
        separatorBuilder: (_, _) => SizedBox(width: 6.w),
        itemBuilder: (context, index) {
          final value = presets[index];
          final selected = (volume - value).abs() < 0.000001;
          return InkWell(
            borderRadius: BorderRadius.circular(999.r),
            onTap: () => onSelected(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primary.withValues(alpha: 0.14)
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999.r),
                border: Border.all(
                  color: selected
                      ? scheme.primary.withValues(alpha: AppColors.alphaFaint)
                      : scheme.outlineVariant.withValues(
                          alpha: AppColors.alphaFaint,
                        ),
                ),
              ),
              child: Text(
                value.toStringAsFixed(2),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: selected ? scheme.primary : scheme.onSurface,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Dropdown-style chooser for the six pending order types. Shows the current
/// selection and opens a sheet with every option (checked state on the active
/// one), mirroring the web terminal's order-type menu.
class PendingOrderTypeSelector extends StatelessWidget {
  const PendingOrderTypeSelector({
    super.key,
    required this.label,
    required this.selectedLabel,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final String label;
  final String selectedLabel;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  Future<void> _open(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42.w,
              height: 4.h,
              margin: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(999.r),
              ),
            ),
            ...List.generate(options.length, (i) {
              final selected = i == selectedIndex;
              return ListTile(
                dense: true,
                title: Text(
                  options[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    fontSize: 14.sp,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? scheme.primary : scheme.onSurface,
                  ),
                ),
                trailing: selected
                    ? Icon(Icons.check_rounded, size: 18.w, color: scheme.primary)
                    : null,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onSelected(i);
                },
              );
            }),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: () => _open(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: AppColors.alphaFaint),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    selectedLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22.w,
              color: scheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Allows a single decimal point and at most [decimals] fraction digits.
/// [decimals] comes from the live quote (`MarketPrice.digits`), so a 2-digit
/// symbol accepts `4342.31` while a 5-digit one accepts `1.15505`.
class DecimalPrecisionFormatter extends TextInputFormatter {
  const DecimalPrecisionFormatter(this.decimals);

  final int decimals;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final pattern = decimals <= 0
        ? RegExp(r'^\d*$')
        : RegExp('^\\d*\\.?\\d{0,$decimals}\$');
    return pattern.hasMatch(text) ? newValue : oldValue;
  }
}

/// Numeric field built on a real [TextFormField]: the label sits in the field
/// decoration and the minus / plus steppers are the prefix / suffix icons, so
/// focus, validation and keyboard behaviour come from the framework.
class PendingOrderStepperField extends StatelessWidget {
  const PendingOrderStepperField({
    super.key,
    required this.controller,
    required this.label,
    required this.onMinus,
    required this.onPlus,
    this.focusNode,
    this.inputFormatters,
    this.onChanged,
    this.onEditingComplete,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: AppColors.alphaFaint),
      ),
    );

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: inputFormatters,
      textAlign: TextAlign.center,
      textAlignVertical: TextAlignVertical.center,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: textTheme.titleSmall?.copyWith(
        fontSize: 15.sp,
        fontWeight: FontWeight.w800,
        height: 1.1,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        labelText: label,
        alignLabelWithHint: true,
        floatingLabelAlignment: FloatingLabelAlignment.center,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: textTheme.labelSmall?.copyWith(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 14.h),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.4.w),
        ),
        errorStyle: textTheme.labelSmall?.copyWith(
          fontSize: 10.sp,
          color: scheme.error,
        ),
        prefixIcon: _StepIcon(icon: Icons.remove_rounded, onTap: onMinus),
        suffixIcon: _StepIcon(icon: Icons.add_rounded, onTap: onPlus),
        prefixIconConstraints: BoxConstraints(minWidth: 52.w),
        suffixIconConstraints: BoxConstraints(minWidth: 52.w),
      ),
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
    );
  }
}

class _StepIcon extends StatelessWidget {
  const _StepIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      widthFactor: 1,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Material(
          color: scheme.primary.withValues(alpha: AppColors.alphaHairline),
          shape: CircleBorder(
            side: BorderSide(
              color: scheme.primary.withValues(alpha: AppColors.alphaFaint),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 34.w,
              height: 34.w,
              child: Icon(icon, size: 18.w, color: scheme.primary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact switch used by the section headers and the TP/SL rows.
class PendingOrderSwitch extends StatelessWidget {
  const PendingOrderSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.88,
      child: Switch(
        value: value,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
