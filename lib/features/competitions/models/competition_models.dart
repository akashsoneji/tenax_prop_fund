import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Domain models for the Competitions screen. Shapes mirror the live
/// `GET /growth/competitions` envelope, whose `data` nests `competitions[]`,
/// `competitions_meta`, `accounts[]` and `stats`. Everything is
/// display-oriented so the views bind directly and the controller holds a
/// single `DataState<CompetitionsData>`.

/// Lifecycle of a competition as reported by `status`. The API also sends a
/// ready-made `status_label`; this enum exists so tone/filtering decisions live
/// in one place instead of `if (status == 'active')` scattered across widgets.
enum CompetitionStatus {
  live,
  upcoming,
  ended;

  static CompetitionStatus parse(String? raw) {
    switch (raw) {
      case 'active':
        return CompetitionStatus.live;
      case 'ended':
      case 'finished':
      case 'closed':
        return CompetitionStatus.ended;
      default:
        return CompetitionStatus.upcoming;
    }
  }

  /// Filter key used by the status tabs and `CompetitionsData.filter`.
  String get key => switch (this) {
        CompetitionStatus.live => 'live',
        CompetitionStatus.upcoming => 'upcoming',
        CompetitionStatus.ended => 'ended',
      };

  /// Fallback translation key, used when the API omits `status_label`.
  String get labelKey => switch (this) {
        CompetitionStatus.live => 'competitions.status.live',
        CompetitionStatus.upcoming => 'competitions.status.upcoming',
        CompetitionStatus.ended => 'competitions.status.ended',
      };

  /// Theme-driven tone so both light and dark render correctly with no
  /// hardcoded colors.
  Color tone(ColorScheme scheme) => switch (this) {
        CompetitionStatus.live => scheme.primary,
        CompetitionStatus.upcoming => scheme.tertiary,
        CompetitionStatus.ended => scheme.outline,
      };
}

/// One prize tier: `{place: 1, label: "1st place", amount: "$500.00"}`.
/// `amount` is null until the organiser funds the tier.
@immutable
class CompetitionPrize {
  const CompetitionPrize({
    required this.place,
    required this.label,
    this.amount,
  });

  final int place;
  final String label;
  final String? amount;

  factory CompetitionPrize.fromJson(Map<String, dynamic> json) =>
      CompetitionPrize(
        place: (json['place'] as num?)?.toInt() ?? 0,
        label: json['label'] as String? ?? '',
        amount: json['amount'] as String?,
      );
}

/// One leaderboard row. `isYou` highlights the signed-in trader's row.
@immutable
class CompetitionLeaderboardRow {
  const CompetitionLeaderboardRow({
    required this.rank,
    required this.name,
    required this.score,
    required this.isYou,
  });

  final int rank;
  final String name;
  final String score;
  final bool isYou;

  factory CompetitionLeaderboardRow.fromJson(Map<String, dynamic> json) =>
      CompetitionLeaderboardRow(
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        score: json['score'] as String? ?? '',
        isYou: json['is_you'] as bool? ?? false,
      );
}

/// An account the trader may enter with — `{id, label: "#2000005 · challenge"}`.
@immutable
class CompetitionAccountOption {
  const CompetitionAccountOption({required this.id, required this.label});

  final int id;
  final String label;

  factory CompetitionAccountOption.fromJson(Map<String, dynamic> json) =>
      CompetitionAccountOption(
        id: (json['id'] as num?)?.toInt() ?? 0,
        label: json['label'] as String? ?? '',
      );
}

/// Pagination block (`competitions_meta`).
@immutable
class CompetitionsMeta {
  const CompetitionsMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.totalPages,
    required this.hasNext,
  });

  final int currentPage;
  final int perPage;
  final int total;
  final int totalPages;
  final bool hasNext;

  static const empty = CompetitionsMeta(
    currentPage: 1,
    perPage: 0,
    total: 0,
    totalPages: 0,
    hasNext: false,
  );

  factory CompetitionsMeta.fromJson(Map<String, dynamic> json) =>
      CompetitionsMeta(
        currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
        perPage: (json['per_page'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        totalPages: (json['total_pages'] as num?)?.toInt() ?? 0,
        hasNext: json['has_next'] as bool? ?? false,
      );
}

/// Header figures (`stats`) — the combined cash pool across competitions.
@immutable
class CompetitionsStats {
  const CompetitionsStats({
    required this.cashPool,
    required this.cashPoolMinor,
    required this.hasCompetitions,
  });

  final String cashPool;
  final int cashPoolMinor;
  final bool hasCompetitions;

  static const empty = CompetitionsStats(
    cashPool: '',
    cashPoolMinor: 0,
    hasCompetitions: false,
  );

  factory CompetitionsStats.fromJson(Map<String, dynamic> json) =>
      CompetitionsStats(
        cashPool: json['cash_pool'] as String? ?? '',
        cashPoolMinor: (json['cash_pool_minor'] as num?)?.toInt() ?? 0,
        hasCompetitions: json['has_competitions'] as bool? ?? false,
      );
}

/// A single competition with its prizes, rules and leaderboard.
@immutable
class Competition {
  const Competition({
    required this.id,
    required this.name,
    required this.slug,
    required this.status,
    required this.statusLabel,
    required this.description,
    required this.startsAt,
    required this.endsAt,
    required this.prizePool,
    required this.currency,
    required this.entriesCount,
    required this.registered,
    required this.myRank,
    required this.myScore,
    required this.canRegister,
    required this.registrationNote,
    required this.prizes,
    required this.rules,
    required this.leaderboard,
  });

  final int id;
  final String name;
  final String slug;
  final CompetitionStatus status;
  final String statusLabel;
  final String? description;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String prizePool;
  final String currency;
  final int entriesCount;
  final bool registered;
  final int? myRank;
  final String? myScore;
  final bool canRegister;
  final String? registrationNote;
  final List<CompetitionPrize> prizes;
  final List<String> rules;
  final List<CompetitionLeaderboardRow> leaderboard;

  /// "19 Sep – 21 Sep 2026", or just one side when the other is missing.
  /// Empty when the organiser has scheduled neither end of the window.
  String get dateRange {
    final start = startsAt;
    final end = endsAt;
    if (start == null && end == null) return '';
    final format = DateFormat('d MMM yyyy');
    if (start == null) return format.format(end!.toLocal());
    if (end == null) return format.format(start.toLocal());
    return '${DateFormat('d MMM').format(start.toLocal())} – '
        '${format.format(end.toLocal())}';
  }

  /// Rank display for the card/detail stat row.
  String get myRankLabel => myRank == null ? '—' : '#$myRank';

  factory Competition.fromJson(Map<String, dynamic> json) {
    final prizes = (json['prizes'] as List<dynamic>?) ?? const [];
    final rules = (json['rules'] as List<dynamic>?) ?? const [];
    final leaderboard = (json['leaderboard'] as List<dynamic>?) ?? const [];
    return Competition(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      status: CompetitionStatus.parse(json['status'] as String?),
      statusLabel: json['status_label'] as String? ?? '',
      description: json['description'] as String?,
      startsAt: DateTime.tryParse(json['starts_at'] as String? ?? ''),
      endsAt: DateTime.tryParse(json['ends_at'] as String? ?? ''),
      prizePool: json['prize_pool'] as String? ?? '',
      currency: json['currency'] as String? ?? '',
      entriesCount: (json['entries_count'] as num?)?.toInt() ?? 0,
      registered: json['registered'] as bool? ?? false,
      myRank: (json['my_rank'] as num?)?.toInt(),
      myScore: json['my_score'] as String?,
      canRegister: json['can_register'] as bool? ?? false,
      registrationNote: json['registration_note'] as String?,
      prizes: prizes
          .whereType<Map<String, dynamic>>()
          .map(CompetitionPrize.fromJson)
          .toList(),
      rules: rules.whereType<String>().toList(),
      leaderboard: leaderboard
          .whereType<Map<String, dynamic>>()
          .map(CompetitionLeaderboardRow.fromJson)
          .toList(),
    );
  }
}

/// The full payload behind the Competitions screen.
@immutable
class CompetitionsData {
  const CompetitionsData({
    required this.competitions,
    required this.meta,
    required this.accounts,
    required this.stats,
  });

  final List<Competition> competitions;
  final CompetitionsMeta meta;
  final List<CompetitionAccountOption> accounts;
  final CompetitionsStats stats;

  bool get isEmpty => competitions.isEmpty;

  static const empty = CompetitionsData(
    competitions: [],
    meta: CompetitionsMeta.empty,
    accounts: [],
    stats: CompetitionsStats.empty,
  );

  /// Competitions matching a status-tab key (`all` returns everything).
  List<Competition> filter(String statusKey) {
    if (statusKey == 'all') return competitions;
    return competitions.where((c) => c.status.key == statusKey).toList();
  }

  Competition? byId(int id) {
    for (final competition in competitions) {
      if (competition.id == id) return competition;
    }
    return null;
  }

  factory CompetitionsData.fromJson(Map<String, dynamic> json) {
    final list = (json['competitions'] as List<dynamic>?) ?? const [];
    final accounts = (json['accounts'] as List<dynamic>?) ?? const [];
    return CompetitionsData(
      competitions: list
          .whereType<Map<String, dynamic>>()
          .map(Competition.fromJson)
          .toList(),
      meta: CompetitionsMeta.fromJson(
        (json['competitions_meta'] as Map?)?.cast<String, dynamic>() ??
            const {},
      ),
      accounts: accounts
          .whereType<Map<String, dynamic>>()
          .map(CompetitionAccountOption.fromJson)
          .toList(),
      stats: CompetitionsStats.fromJson(
        (json['stats'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}
