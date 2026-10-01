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

  /// Font-only style per weight, built once. `GoogleFonts.beVietnamPro(...)`
  /// looks the variant up and allocates on every call; widgets rebuild often
  /// (live ticks), so roles derive from this cache with a cheap `copyWith`.
  static final Map<FontWeight?, TextStyle> _byWeight = {};

  static TextStyle _font(FontWeight? weight) =>
      _byWeight[weight] ??= GoogleFonts.beVietnamPro(fontWeight: weight);

  /// Swap this one call to change the entire app's font family.
  static TextStyle base({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      _font(fontWeight).copyWith(
        fontSize: fontSize,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// Applies the app font to an entire [TextTheme].
  static TextTheme textTheme(TextTheme base) =>
      GoogleFonts.beVietnamProTextTheme(base);

  // ---------------------------------------------------------------------------
  // Named roles = weight + default size. Pass color per call site (so the same
  // style works in light/dark) and override size/height/letterSpacing only
  // where the design asks for it. Sizes are ScreenUtil values (`13.sp`).
  // ---------------------------------------------------------------------------

  /// w800 — screen and card headings.
  static TextStyle heading({Color? color, double fontSize = 20, double? height, double? letterSpacing}) =>
      base(fontSize: fontSize, fontWeight: FontWeight.w800, color: color, height: height, letterSpacing: letterSpacing);

  /// w700 — titles, emphasised labels, links.
  static TextStyle title({Color? color, double fontSize = 16, double? height, double? letterSpacing}) =>
      base(fontSize: fontSize, fontWeight: FontWeight.w700, color: color, height: height, letterSpacing: letterSpacing);

  /// w600 — subtitles, row labels, chip text.
  static TextStyle subtitle({Color? color, double fontSize = 14, double? height, double? letterSpacing}) =>
      base(fontSize: fontSize, fontWeight: FontWeight.w600, color: color, height: height, letterSpacing: letterSpacing);

  /// w500 — body copy.
  static TextStyle body({Color? color, double fontSize = 14, double? height, double? letterSpacing}) =>
      base(fontSize: fontSize, fontWeight: FontWeight.w500, color: color, height: height, letterSpacing: letterSpacing);

  /// w400 — plain/secondary copy, captions, helper text.
  static TextStyle regular({Color? color, double fontSize = 14, double? height, double? letterSpacing}) =>
      base(fontSize: fontSize, fontWeight: FontWeight.w400, color: color, height: height, letterSpacing: letterSpacing);

  /// w500, small — field labels and meta text.
  static TextStyle label({Color? color, double fontSize = 12, double? height, double? letterSpacing}) =>
      base(fontSize: fontSize, fontWeight: FontWeight.w500, color: color, height: height, letterSpacing: letterSpacing);

  /// w800, large — numbers and amounts.
  static TextStyle value({Color? color, double fontSize = 22, double? height, double? letterSpacing}) =>
      base(fontSize: fontSize, fontWeight: FontWeight.w800, color: color, height: height, letterSpacing: letterSpacing);

}