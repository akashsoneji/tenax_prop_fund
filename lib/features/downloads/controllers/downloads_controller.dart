import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../models/download_models.dart';
import '../repositories/downloads_repository.dart';

/// Drives the Downloads & guides screen. Data loading (skeleton / error /
/// empty) is handled by [BaseController] via a single
/// `DataState<List<DownloadSection>>`. Swap the repository for the real API and
/// nothing here or in the view changes.
class DownloadsController extends BaseController<List<DownloadSection>> {
  DownloadsController(this._repository);

  final DownloadsRepository _repository;

  @override
  Future<ApiResponse<List<DownloadSection>>> fetch() =>
      _repository.getDownloads();

  @override
  bool isEmpty(List<DownloadSection> data) => data.isEmpty;
}
