import 'package:get/get.dart';

import '../../../app/flavor/flavor_resolver.dart';
import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../models/support_models.dart';
import '../repositories/support_repository.dart';

/// Drives the Support screen and the "Open a ticket" bottom sheet. Ticket data
/// loading (skeleton / error / empty) is handled by [BaseController] via a
/// single `DataState<SupportData>`; this class only adds the sheet's form UI
/// state. Swap the repository for the real API and nothing here or in the view
/// changes.
class SupportController extends BaseController<SupportData> {
  SupportController(this._repository);

  final SupportRepository _repository;

  // "Open a ticket" sheet form state.
  final topics = <String>[
    'Rule question',
    'Billing',
    'Payout',
    'Technical issue',
    'Other',
  ];
  final accounts = <String>[
    'Not account specific',
    '100311 · Instant \$20k',
    '100482 · ${FlavorResolver.appName} 2-Step \$100k',
  ];

  final selectedTopic = 'Rule question'.obs;
  final selectedAccount = 'Not account specific'.obs;
  final message = ''.obs;

  void selectTopic(String value) => selectedTopic.value = value;
  void selectAccount(String value) => selectedAccount.value = value;
  void setMessage(String value) => message.value = value;

  @override
  Future<ApiResponse<SupportData>> fetch() => _repository.getSupport();

  @override
  bool isEmpty(SupportData data) => data.isEmpty;
}
