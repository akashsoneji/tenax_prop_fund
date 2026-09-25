import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/invoice_viewer_controller.dart';
import '../models/billing_models.dart';
import '../repositories/billing_repository.dart';

/// Wires [InvoiceViewerController] for the invoice viewer. The
/// [BillingTransaction] arrives as route arguments; the repository is shared
/// with the Billing tab when that one is still alive.
class InvoiceViewerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BillingRepository>(
      () => BillingRepository(Get.find<ApiClient>()),
    );
    Get.lazyPut<InvoiceViewerController>(
      () => InvoiceViewerController(
        Get.find<BillingRepository>(),
        Get.arguments as BillingTransaction,
      ),
    );
  }
}
