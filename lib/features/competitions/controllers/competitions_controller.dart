import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../models/competition_models.dart';
import '../repositories/competitions_repository.dart';

/// Drives the Competitions screen. Data loading (skeleton / error / empty) is
/// handled by [BaseController] via a single `DataState<CompetitionInfo>`; this
/// class only adds the screen's UI state (whether the user has registered) so
/// the CTA can flip without a race. Swap the repository for the real API and
/// nothing here or in the view changes.
class CompetitionsController extends BaseController<CompetitionInfo> {
  CompetitionsController(this._repository);

  final CompetitionsRepository _repository;

  final registered = false.obs;

  @override
  Future<ApiResponse<CompetitionInfo>> fetch() => _repository.getCompetitions();

  @override
  bool isEmpty(CompetitionInfo data) => data.isEmpty;

  void register() {
    if (registered.value) return;
    registered.value = true;
  }
}
