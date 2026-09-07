import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/accounts_controller.dart';
import '../repositories/accounts_repository.dart';

/// Wires [AccountsController] (and its repository) for the "My accounts"
/// screen. Registered lazily so the flow only allocates when the user opens the
/// route.
class AccountsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AccountsRepository>(
      () => AccountsRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<AccountsController>(
      () => AccountsController(Get.find<AccountsRepository>()),
    );
  }
}
