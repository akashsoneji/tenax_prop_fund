import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/widgets/app_toast.dart';
import '../models/competition_models.dart';
import '../repositories/competitions_repository.dart';

/// Drives the Competitions screen. Data loading (skeleton / error / empty) is
/// handled by [BaseController] via a single `DataState<CompetitionsData>`;
/// this class only adds the status filter, the entry-account selection and the
/// register interaction. No widgets, no `BuildContext`, no networking.
class CompetitionsController extends BaseController<CompetitionsData> {
  CompetitionsController(this._repository);

  final CompetitionsRepository _repository;

  /// Active status tab: `all`, `live`, `upcoming` or `ended`.
  final statusFilter = 'all'.obs;

  /// Account chosen in the register sheet before entering a competition.
  final selectedAccount = Rxn<CompetitionAccountOption>();

  /// Competitions confirmed registered in this session, so the CTA flips
  /// immediately while the list refresh is still in flight.
  final locallyRegistered = <int>{}.obs;

  /// Competition id currently being submitted, so its CTA can show progress
  /// and double taps are inert.
  final registeringId = Rxn<int>();

  @override
  Future<ApiResponse<CompetitionsData>> fetch() =>
      _repository.getCompetitions();

  @override
  bool isEmpty(CompetitionsData data) => data.isEmpty;

  CompetitionsData get data => state.valueOrNull ?? CompetitionsData.empty;

  /// Competitions matching the active tab.
  List<Competition> get visible => data.filter(statusFilter.value);

  void setStatusFilter(String key) => statusFilter.value = key;

  /// True when the competition is registered server-side or in this session.
  bool isRegistered(Competition competition) =>
      competition.registered || locallyRegistered.contains(competition.id);

  bool isRegistering(Competition competition) =>
      registeringId.value == competition.id;

  void selectAccount(CompetitionAccountOption? account) =>
      selectedAccount.value = account;

  /// Enters [competition] with the account picked in the register sheet, then
  /// refreshes so `registered` / `entries_count` come from the server.
  /// Returns whether the entry was accepted.
  Future<bool> register(Competition competition) async {
    final account = selectedAccount.value;
    if (account == null ||
        !competition.canRegister ||
        isRegistered(competition) ||
        registeringId.value != null) {
      return false;
    }

    registeringId.value = competition.id;
    final result = await _repository.register(
      competitionId: competition.id,
      tradingAccountId: account.id,
    );
    if (isClosed) return result.success;
    registeringId.value = null;

    if (!result.success) return false;

    locallyRegistered.add(competition.id);
    selectedAccount.value = null;
    final message = result.data;
    if (message != null && message.isNotEmpty) AppToast.success(message);
    await refreshData();
    return true;
  }
}
