import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/verification/models/verification_models.dart';
import 'app_labeled_field.dart';

/// A floating-label dropdown matching the KYC design. Shares [LabeledFieldShell]
/// with [AppLabeledField] so a dropdown and a text field sit flush in a Row
/// with identical borders. Selection is fully controlled by the caller.
class AppLabeledDropdown extends StatelessWidget {
  const AppLabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final String? value;
  final List<VerificationOption> options;
  final ValueChanged<String?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LabeledFieldShell(
      label: label,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(14.r),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: scheme.onSurface.withValues(alpha: 0.6)),
          hint: Text(
            hint ?? label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 16.sp,
              color: scheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          style: GoogleFonts.beVietnamPro(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
          dropdownColor: scheme.surface,
          items: [
            for (final o in options)
              DropdownMenuItem(value: o.value, child: Text(o.label)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
