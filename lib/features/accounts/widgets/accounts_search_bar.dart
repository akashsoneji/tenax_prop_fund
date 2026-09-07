import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

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
            style: TextStyle(color: scheme.onSurface, fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: fill,
              hintText: hintText,
              hintStyle: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 13.5,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: scheme.primary, width: 1.4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(14),
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
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextStyle(color: scheme.onSurface, fontSize: 13.5),
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
