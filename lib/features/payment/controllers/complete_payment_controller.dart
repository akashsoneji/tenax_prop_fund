import 'dart:io';

import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/state/data_state.dart';
import '../../../shared/widgets/app_toast.dart';
import '../models/order_models.dart';
import '../repositories/orders_repository.dart';

/// Drives the manual "Complete payment" screen: loads the order + payment
/// instructions, lets the user attach a proof screenshot and submits it. The
/// order id arrives as a route argument.
class CompletePaymentController extends GetxController {
  CompletePaymentController({OrdersRepository? repository})
      : _repository = repository ?? OrdersRepository(Get.find<ApiClient>());

  final OrdersRepository _repository;

  late final String orderId = _argumentOrderId();

  final state = Rx<DataState<OrderDetails>>(const DataState.initial());
  final proofFile = Rxn<File>();
  final reference = ''.obs;
  final submitting = false.obs;

  OrderDetails? get details => state.value.valueOrNull;

  static String _argumentOrderId() {
    final args = Get.arguments;
    if (args is String) return args;
    if (args is num) return '${args.toInt()}';
    if (args is Map && args['orderId'] != null) return '${args['orderId']}';
    return '';
  }

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    state.value = const DataState.loading();
    final res = await _repository.getOrder(orderId);
    if (res.success && res.data != null) {
      state.value = DataState.success(res.data!);
    } else {
      state.value =
          DataState.failure(res.message ?? 'Could not load the order.');
    }
  }

  /// True while the native file picker is open. A second tap would throw
  /// `already_active`, so the view checks this before launching it.
  final picking = false.obs;

  void setProof(File file) => proofFile.value = file;

  /// Runs [pick] guarded so only one native picker session can be open.
  Future<void> pickProof(Future<String?> Function() pick) async {
    if (picking.value) return;
    picking.value = true;
    try {
      final path = await pick();
      if (path != null) proofFile.value = File(path);
    } finally {
      picking.value = false;
    }
  }

  /// True once a proof file is attached and we're not already submitting.
  bool get canSubmit => proofFile.value != null && !submitting.value;

  Future<void> submitProof() async {
    final file = proofFile.value;
    if (file == null) {
      AppToast.error('Please attach your payment proof first.');
      return;
    }
    submitting.value = true;
    final res = await _repository.submitProof(
      id: orderId,
      proof: file,
      reference: reference.value,
    );
    submitting.value = false;

    if (res.success && res.data != null) {
      state.value = DataState.success(res.data!);
      proofFile.value = null;
    }
  }
}
