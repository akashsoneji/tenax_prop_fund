/// Data models for the Trading Rules screen.
///
/// The screen has 4 tabs; each tab is just a list of cards. We model them as
/// plain immutable Dart classes (no codegen) because the data is static demo
/// content that the controller seeds once at construction time.
library;

import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

/// The full payload the Trading Rules screen needs in one fetch, so the
/// controller holds a single `DataState<TradingRulesData>` instead of several
/// loosely-related static lists. Mirrors `AccountsData`.
class TradingRulesData {
  const TradingRulesData({
    required this.closingRules,
    required this.closingTip,
    required this.canDoRows,
    required this.delayRows,
    required this.planRows,
  });

  final List<ClosingRule> closingRules;
  final RulesTip closingTip;
  final List<CanDoRow> canDoRows;
  final List<DelayRow> delayRows;
  final List<PlanRow> planRows;

  bool get isEmpty =>
      closingRules.isEmpty &&
      canDoRows.isEmpty &&
      delayRows.isEmpty &&
      planRows.isEmpty;
}

/// The 4 segments shown in the screen's top tab bar.
///
/// Order here = visual order in the tab bar.
enum RulesTab {
  closes('What closes an account'),
  canDo('What I can do'),
  delays('Delays a reward'),
  everything('Everything');

  const RulesTab(this.label);
  final String label;
}

/// Severity/tone of a "rule" card on the first tab. Drives the accent color
/// (red for danger, purple for warning, green for info, neutral for plain).
enum RuleTone {
  danger,
  warning,
  info,
  neutral;

  Color background(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    switch (this) {
      case RuleTone.danger:
        return dark
            ? AppColors.danger.withValues(alpha: 0.16)
            : const Color(0xFFFDECEC); // pale red (light)
      case RuleTone.warning:
        return dark
            ? scheme.primary.withValues(alpha: 0.18)
            : const Color(0xFFF6ECFB); // pale purple
      case RuleTone.info:
        return dark
            ? const Color(0xFF2E6BD6).withValues(alpha: 0.18)
            : const Color(0xFFEAF3FF); // pale blue
      case RuleTone.neutral:
        return scheme.surfaceContainerHighest;
    }
  }

  Color accent(ColorScheme scheme) {
    switch (this) {
      case RuleTone.danger:
        return AppColors.danger; // brand red
      case RuleTone.warning:
        return scheme.primary; // brand purple
      case RuleTone.info:
        return const Color(0xFF1E88E5); // info blue
      case RuleTone.neutral:
        return scheme.onSurfaceVariant;
    }
  }
}

/// A single numbered rule card on the "What closes an account" tab.
class ClosingRule {
  const ClosingRule({
    required this.index,
    required this.title,
    required this.body,
    required this.highlight,
    required this.tone,
  });

  final int index;
  final String title;
  final String body;

  /// Short, brand-red/bold callout under the body, e.g. "5% · $5,000 …".
  final String highlight;
  final RuleTone tone;
}

/// "You get a warning first" card at the bottom of the first tab.
class RulesTip {
  const RulesTip({required this.title, required this.body});
  final String title;
  final String body;
}

/// A row on the "What I can do" tab — checklist of permitted / prohibited
/// strategies and instruments.
class CanDoRow {
  const CanDoRow({
    required this.label,
    required this.status,
    this.footnote,
  });

  final String label;
  final CanDoStatus status;

  /// Right-column text e.g. "Yes", "No", "Above 60 seconds", or "Yes, gap
  /// risk is yours" — kept on the model so future i18n stays simple.
  final String? footnote;
}

enum CanDoStatus {
  yes,
  no,
  conditional,
}

/// A row on the "Delays a reward" tab — rule + consequence label.
class DelayRow {
  const DelayRow({
    required this.title,
    required this.body,
    required this.consequence,
  });

  final String title;
  final String body;
  final String consequence;
}

/// A row in the "Your plan" list on the "Everything" tab.
class PlanRow {
  const PlanRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;

  /// True for the dollar/percent column so the value renders bolder and in
  /// brand purple, matching the design.
  final bool emphasized;
}
