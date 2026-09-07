import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../models/challenge_models.dart';
import '../repositories/challenge_repository.dart';

/// Drives the Choose-a-challenge screen. Data loading (skeleton / error / empty)
/// is handled by [BaseController] via a single `DataState<ChallengeData>`; this
/// class only adds the screen's UI selection state (mode / step / selected plan)
/// and the derived getters. Swap the repository for the real API and nothing
/// here or in the view changes.
class ChallengeController extends BaseController<ChallengeData> {
  ChallengeController(this._repository);

  final ChallengeRepository _repository;

  final mode = ChallengeMode.paid.obs;
  final step = ChallengeStep.twoStep.obs;

  /// Index into the loaded plans of the highlighted price card. Defaults to the
  /// $100K card (index 1) to match the design.
  final selectedPlan = 1.obs;

  void setMode(ChallengeMode value) => mode.value = value;
  void setStep(ChallengeStep value) => step.value = value;
  void selectPlan(int index) {
    final plans = state.valueOrNull?.plans ?? const <ChallengePlan>[];
    if (index < 0 || index >= plans.length) return;
    selectedPlan.value = index;
  }

  /// The currently highlighted plan, from the loaded [data].
  ChallengePlan currentPlan(ChallengeData data) =>
      data.plans[selectedPlan.value.clamp(0, data.plans.length - 1)];

  @override
  Future<ApiResponse<ChallengeData>> fetch() => _repository.getPlans();

  @override
  bool isEmpty(ChallengeData data) => data.isEmpty;
}
