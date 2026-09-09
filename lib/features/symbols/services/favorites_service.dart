import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../models/symbol_models.dart';
import 'market_watch_v2_service.dart';

/// App-wide store of the user's favorited instruments. Persists each favorite's
/// metadata (code + name + category, sourced from the instruments REST API) in
/// [GetStorage] and keeps the live [MarketWatchV2Service] subscription in sync:
/// adding a favorite subscribes it, removing it unsubscribes. Registered
/// permanent in `InitialBinding` next to the socket so favorites stream from app
/// open.
class FavoritesService extends GetxService {
  FavoritesService(this._storage, this._market);

  final GetStorage _storage;
  final MarketWatchV2Service _market;

  static const _storageKey = 'favorite_instruments';
  static const _seededKey = 'favorite_instruments_seeded';

  /// Default watchlist for a fresh install so the screen is never empty. Seeded
  /// once (guarded by [_seededKey]); after that the user's edits win, including
  /// an intentionally empty list.
  static const _seed = <Instrument>[
    Instrument(code: 'XAUUSD', name: 'Gold', category: InstrumentCategory.metals),
    Instrument(
        code: 'EURUSD', name: 'Euro / Dollar', category: InstrumentCategory.currency),
    Instrument(
        code: 'GBPUSD', name: 'Pound / Dollar', category: InstrumentCategory.currency),
  ];

  /// Favorited instruments, newest first (codes normalised). Bind with `Obx`.
  final RxList<Instrument> favorites = <Instrument>[].obs;

  @override
  void onInit() {
    super.onInit();
    var loaded = _readPersisted();
    if (loaded.isEmpty && !(_storage.read<bool>(_seededKey) ?? false)) {
      loaded = List<Instrument>.from(_seed);
      favorites.assignAll(loaded);
      _persist();
      _storage.write(_seededKey, true);
    } else {
      favorites.assignAll(loaded);
    }
    final codes = favoriteCodes;
    if (codes.isNotEmpty) _market.subscribeSymbols(codes);
  }

  /// Normalised codes of every favorite — used for socket sub/unsubscribe.
  List<String> get favoriteCodes => favorites.map((i) => i.code).toList();

  bool isFavorite(String code) {
    final sym = MarketWatchV2Service.normalizeSymbol(code);
    return favorites.any((i) => i.code == sym);
  }

  /// Adds an instrument (with its API metadata) to favorites and subscribes it
  /// on the live socket. No-op if already present.
  void add(Instrument instrument) {
    final sym = MarketWatchV2Service.normalizeSymbol(instrument.code);
    if (sym.isEmpty || isFavorite(sym)) return;
    favorites.insert(
      0,
      Instrument(code: sym, name: instrument.name, category: instrument.category),
    );
    _persist();
    _market.subscribeSymbols([sym]);
  }

  /// Fallback for callers that only have a bare code: builds a minimal
  /// [Instrument] with an inferred category before delegating to [add].
  void addByCode(String code) {
    final sym = MarketWatchV2Service.normalizeSymbol(code);
    if (sym.isEmpty) return;
    add(Instrument(
      code: sym,
      name: sym,
      category: InstrumentCategory.classify(sym),
    ));
  }

  /// Removes the favorite matching [code] and unsubscribes it from the socket.
  void remove(String code) {
    final sym = MarketWatchV2Service.normalizeSymbol(code);
    final before = favorites.length;
    favorites.removeWhere((i) => i.code == sym);
    if (favorites.length == before) return;
    _persist();
    _market.unsubscribeSymbols([sym]);
  }

  /// Moves the favorite at [oldIndex] to [newIndex] and persists the new order.
  /// Mirrors `ReorderableListView`'s index convention (target shifts down by one
  /// when dragging downward).
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= favorites.length) return;
    var target = newIndex;
    if (oldIndex < target) target -= 1;
    target = target.clamp(0, favorites.length - 1);
    if (target == oldIndex) return;
    final item = favorites.removeAt(oldIndex);
    favorites.insert(target, item);
    _persist();
  }

  void toggle(String code) => isFavorite(code) ? remove(code) : addByCode(code);

  void toggleWith(Instrument instrument) =>
      isFavorite(instrument.code) ? remove(instrument.code) : add(instrument);

  /// Reads persisted favorites. Backward-compatible: an old store of bare code
  /// strings loads as code-only instruments so nothing breaks on upgrade.
  List<Instrument> _readPersisted() {
    final raw = _storage.read<List<dynamic>>(_storageKey) ?? const [];
    final out = <Instrument>[];
    for (final e in raw) {
      if (e is Map) {
        final json = Map<String, dynamic>.from(e);
        final sym = MarketWatchV2Service.normalizeSymbol(
          (json['code'] ?? '').toString(),
        );
        if (sym.isEmpty) continue;
        out.add(Instrument(
          code: sym,
          name: (json['name'] ?? '').toString(),
          category: (json['category'] ?? '').toString(),
        ));
      } else {
        final sym = MarketWatchV2Service.normalizeSymbol(e.toString());
        if (sym.isEmpty) continue;
        out.add(Instrument(code: sym, name: '', category: ''));
      }
    }
    return out;
  }

  void _persist() =>
      _storage.write(_storageKey, favorites.map((i) => i.toJson()).toList());
}
