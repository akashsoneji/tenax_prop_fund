import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/widgets/app_toast.dart';
import '../models/challenge_models.dart';
import '../repositories/challenge_repository.dart';

class ChallengeController extends BaseController<ChallengeData> {
  ChallengeController(this._repository);

  final ChallengeRepository _repository;

  final mode = ChallengeMode.paid.obs;
  final step = ChallengeStep.twoStep.obs;
  final selectedPlan = 0.obs;
  final comparison = Rxn<ChallengeData>();
  final compareSelected = 0.obs;
  final quote = Rxn<ChallengeQuote>();
  final isComparing = false.obs;
  final isQuoting = false.obs;
  final actionError = RxnString();

  void setMode(ChallengeMode value) => mode.value = value;

  void selectComparePlan(int index) => compareSelected.value = index;

  /// Navigates to Configure for the compare-screen [plan], seeding the shared
  /// catalogue (add-ons / platforms / payment methods / currency) from the main
  /// `/challenges` data so the configure screen has everything it needs.
  void buyComparePlan(ChallengePlan plan) {
    final catalogue = state.valueOrNull;
    final version = plan.versions.isNotEmpty ? plan.versions.first : null;
    if (version != null) loadQuote(planVersionId: version.id);
    Get.toNamed(
      AppRoutes.configure,
      arguments: <String, Object?>{
        'plan': plan,
        'plans': comparison.value?.plans ?? const <ChallengePlan>[],
        'addons': catalogue?.addons ?? const [],
        'platforms': catalogue?.platforms ?? const [],
        'paymentMethods': catalogue?.paymentMethods ?? const [],
        'currency': plan.currency,
        'quote': quote.value,
      },
    );
  }

  void setStep(ChallengeStep value) {
    step.value = value;
    selectedPlan.value = 0;
  }

  List<ChallengePlan> plansForStep(ChallengeData data) {
    final format = switch (step.value) {
      ChallengeStep.oneStep => '1-step',
      ChallengeStep.twoStep => '2-step',
      ChallengeStep.instant => 'instant',
    };
    return data.plans.where((plan) {
      final planFormat = plan.format
          .trim()
          .toLowerCase()
          .replaceAll('_', '-')
          .replaceAll(' ', '-');
      return planFormat == format;
    }).toList();
  }

  void selectPlan(int index) {
    final plans = state.valueOrNull == null
        ? const <ChallengePlan>[]
        : plansForStep(state.valueOrNull!);
    if (index >= 0 && index < plans.length) selectedPlan.value = index;
  }

  ChallengePlan currentPlan(ChallengeData data) {
    final plans = plansForStep(data);
    final safePlans = plans.isNotEmpty ? plans : data.plans;
    assert(safePlans.isNotEmpty, 'currentPlan requires at least one plan');
    return safePlans[selectedPlan.value.clamp(0, safePlans.length - 1)];
  }

  Future<void> loadComparison() async {
    isComparing.value = true;
    actionError.value = null;
    final response = await _repository.compare();
    isComparing.value = false;
    if (response.success && response.data != null) {
      comparison.value = response.data;
      compareSelected.value = 0;
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

  final isStartingTrial = false.obs;

  /// Starts the free trial for the given [trial] and routes by payment path
  /// (trials resolve to the `free` path — instant provision, no payment).
  Future<void> startFreeTrial(ChallengeTrial trial) async {
    final versionId = trial.planVersionId;
    if (versionId == null) {
      AppToast.error('errors.generic'.tr);
      return;
    }
    isStartingTrial.value = true;
    actionError.value = null;
    final response = await _repository.startFreeTrial(
      planVersionId: versionId,
      platformIntegrationId: trial.platformIntegrationId,
    );
    isStartingTrial.value = false;

    if (!response.success || response.data == null) {
      AppToast.error(response.message ?? 'errors.generic'.tr);
      return;
    }

    final result = response.data!;
    if (result.isManual) {
      Get.toNamed(AppRoutes.completePayment, arguments: result.orderId);
    } else if (result.isGateway && (result.gatewayUrl?.isNotEmpty ?? false)) {
      Get.toNamed(AppRoutes.gatewayPayment, arguments: result.gatewayUrl);
    } else {
      AppToast.success('Your trial account is being provisioned.');
      Get.until((route) => route.settings.name == AppRoutes.home);
    }
  }

  void onDataLoaded(ChallengeData data) {
    final plans = plansForStep(data);
    selectedPlan.value = plans.isEmpty
        ? 0
        : selectedPlan.value.clamp(0, plans.length - 1);
  }

  @override
  Future<ApiResponse<ChallengeData>> fetch() => _repository.getPlans();

  @override
  bool isEmpty(ChallengeData data) => data.isEmpty;
}
