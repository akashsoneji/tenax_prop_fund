import 'package:flutter/material.dart';

/// THE single source of truth for every raw color in the app.
///
/// Nothing else in the codebase should contain a `Color(0xFF…)` literal — pull
/// the semantic token from here instead. To reskin the app, change a value in
/// THIS file and it updates everywhere.
///
/// Near-identical shades have been intentionally MERGED into one token (e.g.
/// the handful of pale-lavender track greys all collapse to [track], the two
/// amber text inks collapse to [warningInk]) so there is exactly one knob per
/// visual role, never several almost-equal hexes drifting apart.
class AppColors {
  const AppColors._();

  // ---------------------------------------------------------------------------
  // Brand
  // ---------------------------------------------------------------------------
  /// Deep brand purple — light-mode primary (also the flavor default).
  static const brandPurple = Color(0xFF4A0D55);

  /// Lighter lavender used as the DARK-mode primary (deep purple reads muddy
  /// on black).
  static const brandPurpleLight = Color(0xFFB57BC0);

  /// Magenta end of the brand gradient.
  static const brandMagenta = Color(0xFF9B1FA3);

  /// Slightly deeper magenta used by the KYC banner gradient.
  static const brandMagentaDeep = Color(0xFF8A1A8F);

  /// Yellow accent — active tab, progress accents, key highlights (never a CTA
  /// fill).
  static const accent = Color(0xFFFDCC29);

  // ---------------------------------------------------------------------------
  // Hero inks (dark purple hero cards, constant across brightness)
  // ---------------------------------------------------------------------------
  static const heroInk = Color(0xFF3A0A44);
  static const heroInkDeep = Color(0xFF2A0632);

  // ---------------------------------------------------------------------------
  // Status / semantic
  // ---------------------------------------------------------------------------
  /// Primary success green (PnL up, passed, funded, verified). Merged target
  /// for every `0xFF16A34A` in the app.
  static const success = Color(0xFF16A34A);

  /// Darker/brighter greens used only by the account progress gradient.
  static const successDeep = Color(0xFF15803D);
  static const successBright = Color(0xFF22C55E);

  /// Primary danger red (PnL down, breached, errors). Merged target for every
  /// `0xFFD92D20`.
  static const danger = Color(0xFFD92D20);

  /// Brighter red used by destructive icon buttons (sheet close).
  static const dangerBright = Color(0xFFEF4444);

  /// Amber warning accent (open ticket status, warning icons).
  static const warning = Color(0xFFF59E0B);

  /// Amber TEXT ink on light tinted banners. Merges the old `0xFFB6791F`,
  /// `0xFFB25A12`, `0xFFA36A00`, `0xFFB07A12` (all near-identical burnt-amber).
  static const warningInk = Color(0xFFB6791F);

  /// Bright gold/amber accent — progress gradients, medium-impact dots, pending
  /// status. ONE token merging the near-identical `0xFFE0A417`, `0xFFD9930A`,
  /// `0xFFE0A500`, `0xFFEA8A0C`.
  static const amber = Color(0xFFE0A417);

  /// Info blue accent (demo badge, informational chips).
  static const info = Color(0xFF2563EB);

  /// Cyan/teal accent pair — used on dark purple hero cards where a cool
  /// highlight reads better than gold. Bright is the ink/border, deep is the
  /// gradient end on filled CTAs.
  static const cyanBright = Color(0xFF22D3EE);
  static const cyanDeep = Color(0xFF0E9AAE);

  /// Bright pink highlight paired with [brandMagenta] on dark purple heroes.
  static const pinkBright = Color(0xFFF472B6);

  /// Slightly cooled white — the gradient end of a white CTA so the fill has
  /// depth instead of reading as flat paper.
  static const frostWhite = Color(0xFFE6DCEC);

  // ---------------------------------------------------------------------------
  // Surfaces & ink — DARK
  // ---------------------------------------------------------------------------
  static const surfaceDark = Color(0xFF0F0812);
  static const cardDark = Color(0xFF1B1B1F);

  /// Dark bottom-sheet / dialog / elevated input surface. Merges `0xFF1B1220`
  /// and `0xFF1B1B1F`-adjacent sheet backgrounds.
  static const sheetDark = Color(0xFF1B1220);

  // ---------------------------------------------------------------------------
  // Surfaces & ink — LIGHT
  // ---------------------------------------------------------------------------
  static const surfaceLight = Color(0xFFFBF8FD);
  static const cardLight = Colors.white;

  /// Primary ink on light surfaces.
  static const inkLight = Color(0xFF1A0620);

  /// Muted ink on light surfaces (secondary text). Merged target for the old
  /// `0xFF5B4A63` and the black54/black45 label greys.
  static const inkMutedLight = Color(0xFF5B4A63);

  // ---------------------------------------------------------------------------
  // Neutral light tracks / fills / borders (MERGED near-duplicates)
  // ---------------------------------------------------------------------------
  /// Pale-lavender track / segmented-control / chip fill. ONE token replacing
  /// the old `0xFFEDE7F0`, `0xFFEDE3F1`, `0xFFEDE7F1`, `0xFFEDEAF0`,
  /// `0xFFF1EBF4`, `0xFFF3EDF6` — all visually the same.
  static const track = Color(0xFFEDE7F1);

  /// Very soft lavender fill (quick-action tiles). Slightly lighter than
  /// [track]; merges `0xFFF6F3F8`.
  static const trackSoft = Color(0xFFF6F3F8);

  /// Hairline border / divider on light surfaces. ONE token replacing the old
  /// `0xFFE7DFEC`, `0xFFE9E2EE`, `0xFFE1DDE5`.
  static const border = Color(0xFFE7DFEC);

  // ---------------------------------------------------------------------------
  // Auth screen dark gradient
  // ---------------------------------------------------------------------------
  static const authTop = Color(0xFF160419);
  static const authBottom = Color(0xFF24072B);
  static const authLightTop = Color(0xFFFBF7FC);

  // ---------------------------------------------------------------------------
  // Standard opacity steps — use these instead of ad-hoc alpha values so
  // "muted", "hairline", "faint" are consistent everywhere.
  // ---------------------------------------------------------------------------
  static const double alphaMuted = 0.65;
  static const double alphaFaint = 0.45;
  static const double alphaHairline = 0.10;

  // ---------------------------------------------------------------------------
  // Neutral pass-throughs — so feature code never imports Flutter's `Colors`.
  // These are the ONLY place `Colors.*` is allowed; everything else pulls the
  // token from here (use `AppColors.white`, `.black`, `.transparent`).
  // ---------------------------------------------------------------------------
  static const white = Colors.white;
  static const black = Colors.black;
  static const transparent = Colors.transparent;
}
