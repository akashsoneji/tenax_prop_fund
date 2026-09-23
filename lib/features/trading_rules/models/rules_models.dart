/// Data models for the Trading Rules screen.
///
/// Mirrors `GET /support/rules` exactly: the payload is a list of tabs plus a
/// map of sections keyed by the tab `value`. Every tab is rendered the same
/// way (a card of rule lines), so the screen adapts to whatever the backend
/// publishes without any code change.
library;

import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

/// The full payload the Trading Rules screen needs in one fetch, so the
/// controller holds a single `DataState<TradingRulesData>`.
class TradingRulesData {
  const TradingRulesData({required this.tabs, required this.sections});

  final List<RulesTab> tabs;

  /// Keyed by [RulesTab.value].
  final Map<String, RulesSection> sections;

  factory TradingRulesData.fromJson(Map<String, dynamic> json) {
    final rawTabs = json['tabs'];
    final tabs = rawTabs is List
        ? rawTabs
              .whereType<Map>()
              .map((e) => RulesTab.fromJson(e.cast<String, dynamic>()))
              .where((t) => t.value.isNotEmpty)
              .toList()
        : <RulesTab>[];

    final rawSections = json['sections'];
    final sections = <String, RulesSection>{};
    if (rawSections is Map) {
      rawSections.forEach((key, value) {
        if (value is Map) {
          sections['$key'] = RulesSection.fromJson(value.cast<String, dynamic>());
        }
      });
    }

    return TradingRulesData(tabs: tabs, sections: sections);
  }

  RulesSection? sectionFor(String tabValue) => sections[tabValue];

  bool get isEmpty =>
      tabs.isEmpty || sections.values.every((s) => s.items.isEmpty);
}

/// One segment in the screen's top tab bar, straight from `data.tabs[]`.
class RulesTab {
  const RulesTab({required this.value, required this.label});

  final String value;
  final String label;

  factory RulesTab.fromJson(Map<String, dynamic> json) => RulesTab(
    value: '${json['value'] ?? ''}',
    label: '${json['label'] ?? json['value'] ?? ''}',
  );
}

/// The content of one tab: an optional heading/description plus the rule
/// lines the backend published under `sections.<tab>.list`.
class RulesSection {
  const RulesSection({this.title, this.body, required this.items});

  final String? title;
  final String? body;
  final List<String> items;

  factory RulesSection.fromJson(Map<String, dynamic> json) {
    final rawList = json['list'];
    return RulesSection(
      title: _text(json['title']),
      body: _text(json['body'] ?? json['description']),
      items: rawList is List
          ? rawList
                .map((e) => '$e'.trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : const <String>[],
    );
  }

  static String? _text(Object? value) {
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }
}

/// Severity/tone of a rules card. Drives the accent color (red for danger,
/// purple for warning, blue for info, neutral for plain).
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
