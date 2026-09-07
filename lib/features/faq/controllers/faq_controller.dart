import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../models/faq_models.dart';
import '../repositories/faq_repository.dart';

/// Drives the FAQ screen. Data loading (skeleton / error / empty) is handled by
/// [BaseController] via a single `DataState<List<FaqSection>>`; this class only
/// adds the screen's UI state (which entry is currently expanded). A single
/// reactive [expandedKey] holds the "section-index:item-index" of the open
/// panel so at most one is open at a time — no per-tile local state to drift
/// out of sync.
class FaqController extends BaseController<List<FaqSection>> {
  FaqController(this._repository);

  final FaqRepository _repository;

  /// null = all collapsed. Otherwise `<section>:<item>`.
  final expandedKey = RxnString('0:0');

  @override
  Future<ApiResponse<List<FaqSection>>> fetch() => _repository.getFaqs();

  @override
  bool isEmpty(List<FaqSection> data) => data.isEmpty;

  /// Toggles the panel identified by [section]/[item]. Opening one closes any
  /// other (accordion behaviour).
  void toggle(int section, int item) {
    final key = '$section:$item';
    expandedKey.value = expandedKey.value == key ? null : key;
  }

  bool isExpanded(int section, int item) =>
      expandedKey.value == '$section:$item';
}
