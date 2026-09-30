import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/flavor/flavor_config.dart';
import 'app_colors.dart';
import 'app_text.dart';

/// Motion tokens — used across all screens for consistent feel.
abstract class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 600);
  static const page = Duration(milliseconds: 450);

  static const enter = Cubic(0.16, 1, 0.3, 1);
  static const transition = Cubic(0.65, 0, 0.35, 1);
  static const bounce = Cubic(0.34, 1.56, 0.64, 1);
}

/// Design tokens shared across all screens. All values are theme-driven so a
/// new flavor is reskinned purely by changing [FlavorConfig].
class AppTheme {
  const AppTheme._();

  // Accent (yellow highlight — active tab, progress accents, key CTAs).
  // Kept as an alias so existing `AppTheme.accent` call sites keep working;
  // the raw value now lives in [AppColors].
  static const Color accent = AppColors.accent;

  // Deep hero-card ink (used for the top equity card and payout journey card,
  // regardless of theme brightness — the screenshot keeps these dark).
  static const Color heroInk = AppColors.heroInk;
  static const Color heroInkDeep = AppColors.heroInkDeep;

  static ThemeData lightFromFlavor(FlavorConfig config) =>
      _build(config, Brightness.light);

  static ThemeData darkFromFlavor(FlavorConfig config) =>
      _build(config, Brightness.dark);

  static ThemeData _build(FlavorConfig config, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    // Primary is the flavor's brand color in BOTH themes unless the flavor
    // declares a dedicated dark-mode brand color (e.g. navy brand → gold).
    final primary =
        isDark ? (config.darkPrimaryColor ?? config.primaryColor) : config.primaryColor;
    const onPrimary = Colors.white;

    // Light-mode surfaces get a subtle warm-lavender bg + white cards for
    // clean contrast; dark-mode surfaces stay near-black.
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final onSurface = isDark ? Colors.white : AppColors.inkLight;
    final onSurfaceMuted =
        isDark ? Colors.white70 : AppColors.inkMutedLight;

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      onPrimary: onPrimary,
      secondary: config.secondaryColor,
      onSecondary: Colors.black,
      tertiary: config.secondaryColor,
      onTertiary: Colors.black,
      surface: surface,
      onSurface: onSurface,
      brightness: brightness,
    ).copyWith(
      // Kill Material 3's default bluish tertiary/surfaceTint that fromSeed
      // generates from a purple seed — every accent stays on-brand.
      surfaceTint: primary,
      onSurfaceVariant: onSurfaceMuted,
    );

    final baseTextTheme = isDark
        ? Typography.whiteMountainView
        : Typography.blackMountainView;

    // Apply Be Vietnam Pro then bake real weight/color into every role so
    // light-mode text isn't washed-out grey.
    final textTheme = AppText.textTheme(baseTextTheme).apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    ).copyWith(
      headlineLarge: GoogleFonts.beVietnamPro(
        fontSize: 32, fontWeight: FontWeight.w800, color: onSurface, height: 1.1,
      ),
      headlineMedium: GoogleFonts.beVietnamPro(
        fontSize: 26, fontWeight: FontWeight.w800, color: onSurface, height: 1.15,
      ),
      titleLarge: GoogleFonts.beVietnamPro(
        fontSize: 20, fontWeight: FontWeight.w700, color: onSurface,
      ),
      titleMedium: GoogleFonts.beVietnamPro(
        fontSize: 16, fontWeight: FontWeight.w600, color: onSurface,
      ),
      bodyLarge: GoogleFonts.beVietnamPro(
        fontSize: 15, fontWeight: FontWeight.w500, color: onSurface,
      ),
      bodyMedium: GoogleFonts.beVietnamPro(
        fontSize: 14, color: onSurface,
      ),
      labelLarge: GoogleFonts.beVietnamPro(
        fontSize: 14, fontWeight: FontWeight.w600, color: onSurface,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        titleTextStyle: GoogleFonts.beVietnamPro(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: primary.withValues(alpha: 0.4),
          disabledForegroundColor: onPrimary.withValues(alpha: 0.7),
          minimumSize: const Size.fromHeight(54),
          elevation: isDark ? 0 : 6,
          shadowColor: primary.withValues(alpha: 0.35),
          textStyle: GoogleFonts.beVietnamPro(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: primary, width: 1.2),
          textStyle: GoogleFonts.beVietnamPro(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.beVietnamPro(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.track,
        hintStyle: GoogleFonts.beVietnamPro(color: onSurfaceMuted),
        labelStyle: GoogleFonts.beVietnamPro(color: onSurfaceMuted),
        prefixIconColor: primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.sheetDark : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        titleTextStyle: GoogleFonts.beVietnamPro(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        contentTextStyle: GoogleFonts.beVietnamPro(
          fontSize: 14,
          color: onSurfaceMuted,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppColors.border,
      ),
    );
  }

  /// Big asymmetric "half-circle" corner used on hero pills across the app.
  /// One side keeps a soft [small] radius; the opposite side bulges out to a
  /// large [large] radius so the card reads as a rounded pill. Pass
  /// [mirror] to flip the bulge to the left side (design alternates sides).
  static BorderRadius heroPillRadius({
    bool mirror = false,
    double small = 26,
    double large = 88,
  }) =>
      mirror
          ? BorderRadius.only(
              topLeft: Radius.circular(large),
              bottomLeft: Radius.circular(large),
              topRight: Radius.circular(small),
              bottomRight: Radius.circular(small),
            )
          : BorderRadius.only(
              topRight: Radius.circular(large),
              bottomRight: Radius.circular(large),
              topLeft: Radius.circular(small),
              bottomLeft: Radius.circular(small),
            );

  /// Brand gradient used by auth CTAs and hero surfaces. Derived purely from
  /// the flavor's primary so no other brand's hue leaks into the fill.
  /// Kept on-brand: NEVER mixes the accent into the CTA fill.
  static LinearGradient brandGradient(ColorScheme scheme) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [scheme.primary, _shade(scheme.primary, 0.75)],
      );

  /// Deep hero gradient — CTAs, top equity card, payout journey card.
  /// Both ends are darker shades of the flavor's primary.
  static LinearGradient heroGradient(ColorScheme scheme) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _shade(scheme.primary, 0.7),
          scheme.primary,
          _shade(scheme.primary, 0.5),
        ],
      );

  /// Deepest shade of the flavor primary — replaces the old static hero ink
  /// for dark fills / ink-on-white text on hero surfaces.
  static Color heroInkOf(ColorScheme scheme) => _shade(scheme.primary, 0.5);

  /// Darkens [color] by scaling its HSL lightness by [factor].
  static Color _shade(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * factor).clamp(0.0, 1.0)).toColor();
  }

  /// KYC banner gradient — flavor primary → deeper shade of it.
  static LinearGradient kycGradient(ColorScheme scheme) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [scheme.primary, _shade(scheme.primary, 0.7)],
      );

  /// Brand CTA gradient (Create Account button).
  static LinearGradient ctaGradient(ColorScheme scheme) =>
      brandGradient(scheme);

  /// Frosted glass card — layer over any surface.
  static Widget glass({
    required Widget child,
    double radius = 20,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    Brightness? brightness,
    double sigma = 18,
  }) {
    final b = brightness ?? Brightness.light;
    final fill = b == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.55);
    final stroke = b == Brightness.dark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.7);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: stroke, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  /// Neutral card background used across dashboard sections.
  static BoxDecoration surfaceCard(ColorScheme scheme, {double radius = 16}) =>
      BoxDecoration(
        color: scheme.brightness == Brightness.dark
            ? AppColors.cardDark
            : Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: scheme.brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.track,
        ),
      );

  static Color glassOverlay(Brightness b) => b == Brightness.dark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.white.withValues(alpha: 0.55);
}
