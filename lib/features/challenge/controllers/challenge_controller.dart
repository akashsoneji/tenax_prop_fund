import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../models/challenge_models.dart';
import '../repositories/challenge_repository.dart';

class ChallengeController extends BaseController<ChallengeData> {
  ChallengeController(this._repository);

  final ChallengeRepository _repository;

  final mode = ChallengeMode.paid.obs;
  final step = ChallengeStep.twoStep.obs;
  final selectedPlan = 0.obs;
  final comparison = Rxn<ChallengeData>();
  final quote = Rxn<ChallengeQuote>();
  final isComparing = false.obs;
  final isQuoting = false.obs;
  final actionError = RxnString();

  void setMode(ChallengeMode value) => mode.value = value;
  void setStep(ChallengeStep value) => step.value = value;

  void selectPlan(int index) {
    final plans = state.valueOrNull?.plans ?? const <ChallengePlan>[];
    if (index >= 0 && index < plans.length) selectedPlan.value = index;
  }

  ChallengePlan currentPlan(ChallengeData data) {
    assert(data.plans.isNotEmpty, 'currentPlan requires at least one plan');
    return data.plans[selectedPlan.value.clamp(0, data.plans.length - 1)];
  }

  Future<void> loadComparison() async {
    isComparing.value = true;
    actionError.value = null;
    final response = await _repository.compare();
    isComparing.value = false;
    if (response.success && response.data != null) {
      comparison.value = response.data;
      return;
    }
    actionError.value = response.message ?? 'errors.generic'.tr;
  }

  Future<bool> loadQuote({required int planVersionId, List<int> addonIds = const []}) async {
    isQuoting.value = true;
    actionError.value = null;
    final response = await _repository.quote(
      planVersionId: planVersionId,
      addonIds: addonIds,
    );
    isQuoting.value = false;
    if (response.success && response.data != null) {
      quote.value = response.data;
      return true;
    }
    actionError.value = response.message ?? 'errors.generic'.tr;
    return false;
  }

  void onDataLoaded(ChallengeData data) {
    selectedPlan.value = data.plans.isEmpty
        ? 0
        : selectedPlan.value.clamp(0, data.plans.length - 1);
  }

  @override
  Future<ApiResponse<ChallengeData>> fetch() => _repository.getPlans();

  @override
  bool isEmpty(ChallengeData data) => data.isEmpty;
}
