import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/competition_models.dart';

/// Single source of truth for competition data. Currently serves a static demo
/// [CompetitionInfo] so the screen renders without the live API.
class CompetitionsRepository {
  CompetitionsRepository(this._api);

  // ignore: unused_field
  final ApiClient _api;

  Future<ApiResponse<CompetitionInfo>> getCompetitions() =>
      Future.value(ApiResponse.success(_demo));

  static const _demo = CompetitionInfo(
    title: 'Summer Trading Cup',
    status: 'Live',
    dateRange: 'Aug 1 – Aug 31, 2026',
    entrants: '2,480',
    prizePool: '\$25,000',
    accounts: '\$100K Challenge',
    entry: 'Free',
    rank: '#128',
    prizes: [
      CompetitionPrize('1st', '\$10,000 cash + funded account'),
      CompetitionPrize('2nd', '\$5,000 cash'),
      CompetitionPrize('3rd', '\$2,500 cash'),
      CompetitionPrize('4th–10th', '\$500 each'),
    ],
    rules: [
      CompetitionRule('Expert Advisors', 'Not allowed'),
      CompetitionRule('Minimum trading days', '5 days'),
      CompetitionRule('Max daily loss', '5%'),
      CompetitionRule('Max overall loss', '10%'),
    ],
  );
}
