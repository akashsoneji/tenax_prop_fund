import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The bordered "floating label" container used across the verification forms.
///
/// Renders a rounded outline with the [label] notched into the top border
/// (matching the design's `OutlineInputBorder` look) and lays out [child]
/// inside. Reused by [AppLabeledField] and [AppLabeledDropdown] so every input
/// on the KYC screens shares one border treatment, spacing, and theme colours.
class LabeledFieldShell extends StatelessWidget {
  const LabeledFieldShell({
    super.key,
    required this.label,
    required this.child,
    this.minHeight = 58,
  });

  final String label;
  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = scheme.onSurface.withValues(alpha: 0.18);
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12.5,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 2),
          child,
        ],
      ),
    );
  }
}

/// A reusable floating-label text field matching the KYC design. Renders a
/// borderless [TextField] inside a [LabeledFieldShell] so the border and label
/// styling stay identical to the dropdowns.
class AppLabeledField extends StatelessWidget {
  const AppLabeledField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minHeight = 58,
    this.trailing,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final double minHeight;

  /// Optional trailing widget (e.g. the inline "Send OTP" action or a check).
  final Widget? trailing;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final field = TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      onChanged: onChanged,
      style: GoogleFonts.beVietnamPro(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: scheme.onSurface,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        hintText: hint,
        hintStyle: GoogleFonts.beVietnamPro(
          fontSize: 16,
          color: scheme.onSurface.withValues(alpha: 0.4),
        ),
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );
    return LabeledFieldShell(
      label: label,
      minHeight: maxLines > 1 ? minHeight : 58,
      child: trailing == null
          ? field
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: field),
                const SizedBox(width: 8),
                trailing!,
              ],
            ),
    );
  }
}
