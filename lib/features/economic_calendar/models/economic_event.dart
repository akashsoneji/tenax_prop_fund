import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

/// Impact level
enum EventImpact { high, medium, low }

/// A single economic-calendar event row.
class EconomicEvent {
  const EconomicEvent({
    required this.currency,
    required this.title,
    required this.detail,
    required this.impact,
  });

  final String currency;
  final String title;
  final String detail;
  final EventImpact impact;

  Color impactColor(ColorScheme scheme) {
    switch (impact) {
      case EventImpact.high:
        return AppColors.danger;
      case EventImpact.medium:
        return AppColors.amber;
      case EventImpact.low:
        return AppColors.success;
    }
  }

  String get impactLabel {
    switch (impact) {
      case EventImpact.high:
        return 'High';
      case EventImpact.medium:
        return 'Medium';
      case EventImpact.low:
        return 'Low';
    }
  }
}

/// A day group of events ("Today", "Tomorrow", "Thu 7 Aug").
class EventDay {
  const EventDay(this.label, this.events);
  final String label;
  final List<EconomicEvent> events;
}
