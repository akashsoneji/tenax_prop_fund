import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';

/// Search-by-login field plus an "All plans" dropdown, matching the web toolbar
/// but stacked for mobile width. Emits changes up to the controller.
class AccountsSearchBar extends StatelessWidget {
  const AccountsSearchBar({
    super.key,
    required this.hintText,
    required this.allPlansLabel,
    required this.planOptions,
    required this.selectedPlan,
    required this.onQueryChanged,
    required this.onPlanChanged,
  });

  final String hintText;
  final String allPlansLabel;
  final List<String> planOptions;
  final String selectedPlan;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onPlanChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = scheme.brightness == Brightness.dark
        ? AppColors.white.withValues(alpha: 0.05)
        : scheme.primary.withValues(alpha: 0.05);
    final border = scheme.primary.withValues(alpha: 0.14);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            style: AppText.base(color: scheme.onSurface, fontSize: 14.sp),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: fill,
              hintText: hintText,
              hintStyle: AppText.base(
                color: scheme.onSurfaceVariant,
                fontSize: 13.5.sp,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20.w,
                color: scheme.onSurfaceVariant,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 10.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: scheme.primary, width: 1.4.w),
              ),
            ),
          ),
        ),
        10.horizontalSpace,
        Expanded(
          flex: 2,
          child: Container(
            height: 42.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedPlan.isEmpty ? null : selectedPlan,
                isExpanded: true,
                isDense: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: scheme.onSurfaceVariant,
                ),
                hint: Text(
                  allPlansLabel,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.base(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: AppText.base(color: scheme.onSurface, fontSize: 13.5.sp),
                dropdownColor: scheme.surfaceContainerHighest,
                items: [
                  DropdownMenuItem<String>(
                    value: '',
                    child: Text(allPlansLabel),
                  ),
                  for (final plan in planOptions)
                    DropdownMenuItem<String>(
                      value: plan,
                      child: Text(plan, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => onPlanChanged(v ?? ''),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
