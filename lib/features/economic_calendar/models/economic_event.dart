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

  /// Parses one calendar event row from the API. Field names are matched
  /// defensively (the API uses `currency`, `title`/`event`, `impact`) and the
  /// [detail] line is composed from time/forecast/previous/actual when present.
  factory EconomicEvent.fromJson(Map<String, dynamic> json) {
    String str(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
      return '';
    }

    final parts = <String>[];
    final time = str(['time', 'time_label', 'at']);
    if (time.isNotEmpty) parts.add(time);
    final forecast = str(['forecast']);
    if (forecast.isNotEmpty) parts.add('forecast $forecast');
    final previous = str(['previous']);
    if (previous.isNotEmpty) parts.add('previous $previous');
    final actual = str(['actual']);
    if (actual.isNotEmpty) parts.add('actual $actual');

    return EconomicEvent(
      currency: str(['currency', 'country', 'currency_code']),
      title: str(['title', 'event', 'name']),
      detail: parts.isEmpty ? str(['detail', 'description']) : parts.join(' · '),
      impact: _impactFrom(str(['impact', 'importance', 'impact_label'])),
    );
  }

  static EventImpact _impactFrom(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'high':
      case '3':
        return EventImpact.high;
      case 'low':
      case '1':
        return EventImpact.low;
      default:
        return EventImpact.medium;
    }
  }

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

  /// Groups a flat API `events` list into day buckets, preserving order. Each
  /// event is placed under its `date`/`day` label; events without one fall into
  /// a single untitled group.
  static List<EventDay> groupByDate(List<dynamic> raw) {
    final order = <String>[];
    final buckets = <String, List<EconomicEvent>>{};
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final label = [
        map['date_label'],
        map['date'],
        map['day'],
      ].firstWhere(
        (v) => v != null && v.toString().trim().isNotEmpty,
        orElse: () => '',
      ).toString();
      buckets.putIfAbsent(label, () {
        order.add(label);
        return <EconomicEvent>[];
      }).add(EconomicEvent.fromJson(map));
    }
    return [for (final l in order) EventDay(l, buckets[l]!)];
  }
}
