import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// THE single source of truth for typography.
///
/// The app font is defined ONCE in [fontFamily]/[base]; change it here to swap
/// the whole app's typeface. Named style helpers below cover the recurring
/// roles so widgets stop hand-rolling `GoogleFonts.beVietnamPro(fontSize: …,
/// fontWeight: …)` with slightly different numbers each time.
///
/// Colors are intentionally NOT baked in — pass `color:` (usually
/// `scheme.onSurface`) at the call site so the same style works in light/dark.
class AppText {
  const AppText._();

  /// Swap this one call to change the entire app's font family.
  static TextStyle base({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.beVietnamPro(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// Applies the app font to an entire [TextTheme].
  static TextTheme textTheme(TextTheme base) =>
      GoogleFonts.beVietnamProTextTheme(base);

  // ---------------------------------------------------------------------------
  // Named roles (size + weight only). Pass color per call site.
  // ---------------------------------------------------------------------------
  static TextStyle heading({Color? color, double fontSize = 20}) =>
      base(fontSize: fontSize, fontWeight: FontWeight.w800, color: color);

  static TextStyle title({Color? color, double fontSize = 16}) =>
      base(fontSize: fontSize, fontWeight: FontWeight.w700, color: color);

  static TextStyle subtitle({Color? color, double fontSize = 14}) =>
      base(fontSize: fontSize, fontWeight: FontWeight.w600, color: color);

  static TextStyle body({Color? color, double fontSize = 14, double? height}) =>
      base(fontSize: fontSize, fontWeight: FontWeight.w500, color: color, height: height);

  static TextStyle label({Color? color, double fontSize = 12}) =>
      base(fontSize: fontSize, fontWeight: FontWeight.w500, color: color);

  static TextStyle value({Color? color, double fontSize = 22}) =>
      base(fontSize: fontSize, fontWeight: FontWeight.w800, color: color);
}
