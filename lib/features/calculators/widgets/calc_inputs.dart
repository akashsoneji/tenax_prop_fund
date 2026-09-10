import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';

/// A single labelled numeric input
/// outlined field with a floating label. Theme-driven border + text colors.
class CalcInputField extends StatefulWidget {
  const CalcInputField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<CalcInputField> createState() => _CalcInputFieldState();
}

class _CalcInputFieldState extends State<CalcInputField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      style: GoogleFonts.beVietnamPro(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: false,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      ),
    );
  }
}

/// Labelled symbol dropdown (outlined, floating label) for the Calculators
/// screen. Generic over any list of symbol strings.
class CalcSymbolDropdown extends StatelessWidget {
  const CalcSymbolDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'calculators.symbol'.tr,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: false,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: scheme.onSurface.withValues(alpha: 0.6)),
          dropdownColor: scheme.brightness == Brightness.dark
              ? AppColors.sheetDark
              : Colors.white,
          style: GoogleFonts.beVietnamPro(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          items: [
            for (final s in items)
              DropdownMenuItem(value: s, child: Text(s)),
          ],
        ),
      ),
    );
  }
}
