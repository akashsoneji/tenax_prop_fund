import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../models/kyc_profile.dart';
import '../repositories/kyc_repository.dart';

/// Drives the Profile & KYC screen. Data loading (skeleton / error / empty) is
/// handled by [BaseController] via a single `DataState<KycProfile>`; the repo is
/// the single source of truth. Swap the repository for the real API and nothing
/// here or in the view changes.
class KycController extends BaseController<KycProfile> {
  KycController(this._repository);

  final KycRepository _repository;

  /// Convenience accessor for the loaded profile (null until success). Used by
  /// [EditProfileBinding] to seed the edit form.
  KycProfile? get profile => state.valueOrNull;

  @override
  Future<ApiResponse<KycProfile>> fetch() => _repository.getProfile();

  @override
  bool isEmpty(KycProfile data) => false;

  Future<void> refreshProfile() => refreshData();
}
