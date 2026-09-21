import 'package:get/get.dart';

import '../../accounts/services/primary_account_service.dart';
import '../models/symbol_models.dart';
import '../repositories/symbols_repository.dart';
import '../services/favorites_service.dart';

/// Drives the instrument search sheet: loads the instruments list once, then
/// exposes a [filtered] view derived from [query] + [selectedCategory].
/// Favoriting delegates to the app-wide [FavoritesService] (which owns the
/// socket sub/unsubscribe), so this controller holds no networking.
class SearchInstrumentsController extends GetxController {
  SearchInstrumentsController(this._repository, this._favorites);

  final SymbolsRepository _repository;
  final FavoritesService _favorites;

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString query = ''.obs;
  final RxString selectedCategory = InstrumentCategory.all.obs;
  final RxList<Instrument> _all = <Instrument>[].obs;

  /// Filter pills: "All" plus the category names the API returned.
  final RxList<String> categories = <String>[InstrumentCategory.all].obs;

  FavoritesService get favorites => _favorites;

  /// The user's active/primary MT5 account id, or `null` when they have no
  /// accounts yet (fresh registration) or none is marked primary — in that case
  /// the symbols endpoint is called unscoped.
  int? get _activeAccountId {
    if (!Get.isRegistered<PrimaryAccountService>()) return null;
    return Get.find<PrimaryAccountService>().primaryAccountId.value;
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = '';
    final res = await _repository.getInstruments(accountId: _activeAccountId);
    if (isClosed) return;
    if (res.success && res.data != null) {
      _all.assignAll(res.data!.instruments);
      categories.assignAll([InstrumentCategory.all, ...res.data!.categories]);
      if (!categories.contains(selectedCategory.value)) {
        selectedCategory.value = InstrumentCategory.all;
      }
    } else {
      error.value = res.message ?? 'errors.generic'.tr;
    }
    isLoading.value = false;
  }

  void setQuery(String value) => query.value = value.trim();

  void setCategory(String category) => selectedCategory.value = category;

  /// Instruments matching the active category pill AND the search text.
  List<Instrument> get filtered {
    final cat = selectedCategory.value;
    final q = query.value.toLowerCase();
    return _all.where((i) {
      final catOk = cat == InstrumentCategory.all || i.category == cat;
      final qOk = q.isEmpty ||
          i.code.toLowerCase().contains(q) ||
          i.name.toLowerCase().contains(q);
      return catOk && qOk;
    }).toList();
  }

  /// Toggles a favorite. On add, passes the full [Instrument] (with API
  /// metadata) so the favorite can render a proper card; falls back to a
  /// code-only add if the tapped code isn't in the loaded list.
  void toggleFavorite(String code) {
    if (_favorites.isFavorite(code)) {
      _favorites.remove(code);
      return;
    }
    final match = _all.firstWhereOrNull((i) => i.code == code);
    if (match != null) {
      _favorites.add(match);
    } else {
      _favorites.addByCode(code);
    }
  }
}
