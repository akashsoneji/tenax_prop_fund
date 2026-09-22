import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/widgets/app_toast.dart';
import '../models/offer_models.dart';
import '../repositories/offers_repository.dart';

/// Drives the "My offers" screen. Data loading (skeleton / error / empty) is
/// handled by [BaseController] via a single `DataState<OffersData>`; this class
/// wires the repository and the copy-code action.
class OffersController extends BaseController<OffersData> {
  OffersController(this._repository);

  final OffersRepository _repository;

  @override
  Future<ApiResponse<OffersData>> fetch() => _repository.getOffers();

  @override
  bool isEmpty(OffersData data) => data.isEmpty;

  /// Puts the voucher code on the clipboard so it can be pasted at checkout.
  void copyCode(Offer offer) {
    if (offer.code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: offer.code));
    AppToast.success('offers.code_copied'.tr);
  }
}
