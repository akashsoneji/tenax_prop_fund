import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/challenge_controller.dart';
import '../repositories/challenge_repository.dart';

/// Wires [ChallengeController] (and its repository) when the Choose-a-challenge
/// route opens. [fenix] keeps the controller alive across the Configure hop so
/// the chosen plan is preserved without re-seeding.
class ChallengeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChallengeRepository>(
      () => ChallengeRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<ChallengeController>(
      () => ChallengeController(Get.find<ChallengeRepository>()),
      fenix: true,
    );
  }
}
