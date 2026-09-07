import 'package:flutter/material.dart';

/// A single prize tier row on the Competitions screen ("1st", "$3,000 cash…").
class CompetitionPrize {
  const CompetitionPrize(this.place, this.reward);
  final String place;
  final String reward;
}

/// A single competition-rule row ("Expert Advisors" → "Not allowed").
class CompetitionRule {
  const CompetitionRule(this.label, this.value);
  final String label;
  final String value;
}

/// Immutable snapshot of the active competition shown on the screen. Static
/// demo data today; swap the controller seed for a repository later with no
/// view change.
class CompetitionInfo {
  const CompetitionInfo({
    required this.title,
    required this.status,
    required this.dateRange,
    required this.entrants,
    required this.prizePool,
    required this.accounts,
    required this.entry,
    required this.rank,
    required this.prizes,
    required this.rules,
  });

  final String title;
  final String status;
  final String dateRange;
  final String entrants;
  final String prizePool;
  final String accounts;
  final String entry;
  final String rank;
  final List<CompetitionPrize> prizes;
  final List<CompetitionRule> rules;

  bool get isEmpty => title.isEmpty;

  static const empty = CompetitionInfo(
    title: '',
    status: '',
    dateRange: '',
    entrants: '',
    prizePool: '',
    accounts: '',
    entry: '',
    rank: '',
    prizes: [],
    rules: [],
  );

  /// Builds from the `GET /growth/competitions` envelope. When the
  /// `competitions` array is empty the screen shows its empty state.
  factory CompetitionInfo.fromJson(Map<String, dynamic> json) {
    final list = (json['competitions'] as List<dynamic>?) ?? const [];
    final maps = list.whereType<Map<String, dynamic>>().toList();
    if (maps.isEmpty) return CompetitionInfo.empty;
    final first = maps.first;
    final prizes = (first['prizes'] as List<dynamic>?) ?? const [];
    final rules = (first['rules'] as List<dynamic>?) ?? const [];
    return CompetitionInfo(
      title: first['title'] as String? ?? first['name'] as String? ?? '',
      status: first['status'] as String? ?? '',
      dateRange: first['date_range'] as String? ?? '',
      entrants: first['entrants']?.toString() ?? '',
      prizePool: first['prize_pool'] as String? ?? '',
      accounts: first['accounts'] as String? ?? '',
      entry: first['entry'] as String? ?? '',
      rank: first['rank']?.toString() ?? '',
      prizes: prizes
          .whereType<Map<String, dynamic>>()
          .map((p) => CompetitionPrize(
                p['place'] as String? ?? '',
                p['reward'] as String? ?? '',
              ))
          .toList(),
      rules: rules
          .whereType<Map<String, dynamic>>()
          .map((r) => CompetitionRule(
                r['label'] as String? ?? '',
                r['value'] as String? ?? '',
              ))
          .toList(),
    );
  }
}

/// A labelled stat shown in the hero grid (Prize pool / Accounts / Entry / Rank).
@immutable
class CompetitionStat {
  const CompetitionStat(this.label, this.value);
  final String label;
  final String value;
}
