import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/account_controller.dart';
import '../repositories/account_repository.dart';

/// Wires [AccountController] (and its repository) for the Account risk
/// dashboard. Registered lazily so the flow only allocates when the user opens
/// the route.
class AccountBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AccountRepository>(
      () => AccountRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<AccountController>(
      () => AccountController(Get.find<AccountRepository>()),
    );
  }
}
