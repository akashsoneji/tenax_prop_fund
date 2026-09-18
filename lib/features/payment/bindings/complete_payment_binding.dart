import 'package:get/get.dart';

import '../controllers/complete_payment_controller.dart';

/// Wires [CompletePaymentController] when the Complete-payment route opens.
class CompletePaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CompletePaymentController>(() => CompletePaymentController());
  }
}
