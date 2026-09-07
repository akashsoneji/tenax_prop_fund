import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../models/symbol_models.dart';
import '../repositories/symbols_repository.dart';
import '../services/market_watch_v2_service.dart';

/// Drives the "Symbols & specs" screen. Loading (skeleton / error / empty) is
/// handled by [BaseController] via a single `DataState<List<SymbolSpec>>`; swap
/// the repository for the real instruments API and nothing here or in the view
/// changes.
class SymbolsController extends BaseController<List<SymbolSpec>> {
  SymbolsController(this._repository);

  final SymbolsRepository _repository;

  @override
  Future<ApiResponse<List<SymbolSpec>>> fetch() async {
    final res = await _repository.getSymbols();
    // Once the spec list is known, subscribe those codes to the live feed so
    // each card can show streaming bid/ask. The socket itself is app-wide and
    // already connected (see MarketWatchV2Service in InitialBinding).
    if (res.success && res.data != null && res.data!.isNotEmpty) {
      final codes = res.data!.map((s) => s.code).toList();
      Get.find<MarketWatchV2Service>().subscribeSymbols(codes);
    }
    return res;
  }

  @override
  bool isEmpty(List<SymbolSpec> data) => data.isEmpty;
}
