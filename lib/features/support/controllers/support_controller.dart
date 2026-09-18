import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../models/support_models.dart';
import '../repositories/support_repository.dart';

/// Drives the Support screen and the "Open a ticket" bottom sheet. Ticket data
/// loading (skeleton / error / empty) is handled by [BaseController] via a
/// single `DataState<SupportData>`; this class adds the sheet's form state and
/// the create/reply actions, all backed by the live `/support/*` API.
class SupportController extends BaseController<SupportData> {
  SupportController(this._repository);

  final SupportRepository _repository;

  // "Open a ticket" sheet form state.
  final selectedTopic = ''.obs;
  final subject = ''.obs;
  final message = ''.obs;
  final submitting = false.obs;

  /// Topic options come from the fetched payload; empty until the first load.
  List<SupportTopic> get topics => state.valueOrNull?.topics ?? const [];

  void selectTopic(String value) => selectedTopic.value = value;
  void setSubject(String value) => subject.value = value;
  void setMessage(String value) => message.value = value;

  @override
  Future<ApiResponse<SupportData>> fetch() => _repository.getSupport();

  @override
  bool isEmpty(SupportData data) => false;

  /// Submits a new ticket, then refreshes the list. Returns true on success so
  /// the sheet can close itself.
  Future<bool> submitTicket() async {
    if (selectedTopic.value.isEmpty ||
        subject.value.trim().isEmpty ||
        message.value.trim().isEmpty) {
      return false;
    }
    submitting.value = true;
    final res = await _repository.createTicket(
      topic: selectedTopic.value,
      subject: subject.value.trim(),
      message: message.value.trim(),
    );
    if (isClosed) return false;
    submitting.value = false;
    if (res.success) {
      subject.value = '';
      message.value = '';
      await refreshData();
      return true;
    }
    return false;
  }
}
