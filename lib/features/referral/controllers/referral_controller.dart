import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/widgets/app_toast.dart';
import '../models/referral_models.dart';
import '../repositories/referral_repository.dart';

/// Drives the "Refer & earn" screen. Data loading (skeleton / error / empty) is
/// handled by [BaseController] via a single `DataState<ReferralData>`; this
/// class adds the copy-code / share actions, which read the loaded referral
/// data and put the share link on the clipboard (no external share plugin).
class ReferralController extends BaseController<ReferralData> {
  ReferralController(this._repository);

  final ReferralRepository _repository;

  @override
  Future<ApiResponse<ReferralData>> fetch() => _repository.getReferral();

  @override
  bool isEmpty(ReferralData data) => data.isEmpty;

  /// The loaded referral payload, or null while loading / on error.
  ReferralData? get _data => state.valueOrNull;

  void copyCode() {
    final code = _data?.referralCode ?? '';
    if (code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: code));
    AppToast.success('referral.code_copied'.trParams({'arg': code}));
  }

  void shareLink() {
    final url = _data?.shareUrl ?? '';
    if (url.isEmpty) return;
    Clipboard.setData(ClipboardData(text: url));
    AppToast.success('referral.link_copied'.tr);
  }
}
