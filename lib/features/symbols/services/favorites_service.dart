import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_interceptor.dart';
import '../models/symbol_models.dart';
import 'market_watch_v2_service.dart';

/// App-wide store of the user's favorited instruments. Persists each favorite's
/// metadata (code + name + category, sourced from the instruments REST API) in
/// [GetStorage] and keeps the live [MarketWatchV2Service] subscription in sync:
/// adding a favorite subscribes it, removing it unsubscribes. Registered
/// permanent in `InitialBinding` next to the socket so favorites stream from app
/// open.
///
/// When signed in, the server watchlist (`user/trade/marketwatch`) is the source
/// of truth: it is loaded on app open and after login ([syncFromServer]), and
/// every add/remove/reorder POSTs the FULL final list (the server replaces the
/// whole list). The local store is only a cache so the last list shows
/// instantly.
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
    Instrument(
      code: 'XAUUSD',
      name: 'Gold',
      category: InstrumentCategory.metals,
    ),
    Instrument(
      code: 'EURUSD',
      name: 'Euro / Dollar',
      category: InstrumentCategory.currency,
    ),
    Instrument(
      code: 'GBPUSD',
      name: 'Pound / Dollar',
      category: InstrumentCategory.currency,
    ),
  ];

  /// Favorited instruments, newest first (codes normalised). Bind with `Obx`.
  final RxList<Instrument> favorites = <Instrument>[].obs;

  /// Bumped on every sync so a late GET from a previous session is dropped.
  int _syncSeq = 0;

  /// Serialises POSTs so two quick edits never reach the server out of order.
  Future<void> _writeChain = Future<void>.value();

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
    syncFromServer();
  }

  /// Normalised codes of every favorite — used for socket sub/unsubscribe.
  List<String> get favoriteCodes => favorites.map((i) => i.code).toList();

  bool isFavorite(String code) {
    final sym = MarketWatchV2Service.normalizeSymbol(code);
    return favorites.any((i) => i.code == sym);
  }

  /// `GET user/trade/marketwatch` → replaces the local list with the server's.
  /// Called on app open and after login; a no-op when signed out. Never throws.
  Future<void> syncFromServer() async {
    final seq = ++_syncSeq;
    if (!await _hasToken()) return;
    try {
      final res = await Get.find<ApiClient>().getWeb<dynamic>(
        ApiEndpoints.marketWatch,
      );
      if (seq != _syncSeq) return;
      final symbols = _symbolsFrom(res.data);
      if (symbols == null) {
        log.w('FavoritesService: unexpected marketwatch GET body');
        return;
      }
      _applyServerList(symbols);
    } catch (e) {
      log.e('FavoritesService: marketwatch GET failed: $e');
    }
  }

  /// Adds an instrument (with its API metadata) to favorites and subscribes it
  /// on the live socket. No-op if already present.
  void add(Instrument instrument) {
    final sym = MarketWatchV2Service.normalizeSymbol(instrument.code);
    if (sym.isEmpty || isFavorite(sym)) return;
    favorites.insert(
      0,
      Instrument(
        code: sym,
        name: instrument.name,
        category: instrument.category,
      ),
    );
    _persist();
    _market.subscribeSymbols([sym]);
    _pushToServer();
  }

  /// Fallback for callers that only have a bare code: builds a minimal
  /// [Instrument] with an inferred category before delegating to [add].
  void addByCode(String code) {
    final sym = MarketWatchV2Service.normalizeSymbol(code);
    if (sym.isEmpty) return;
    add(
      Instrument(
        code: sym,
        name: sym,
        category: InstrumentCategory.classify(sym),
      ),
    );
  }

  /// Removes the favorite matching [code] and unsubscribes it from the socket.
  void remove(String code) {
    final sym = MarketWatchV2Service.normalizeSymbol(code);
    final before = favorites.length;
    favorites.removeWhere((i) => i.code == sym);
    if (favorites.length == before) return;
    _persist();
    _market.unsubscribeSymbols([sym]);
    _pushToServer();
  }

  /// Moves the favorite at [oldIndex] to [newIndex] and persists the new order.
  /// [newIndex] is the final position after removal (the
  /// `ReorderableListView.onReorderItem` convention).
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= favorites.length) return;
    final target = newIndex.clamp(0, favorites.length - 1);
    if (target == oldIndex) return;
    final item = favorites.removeAt(oldIndex);
    favorites.insert(target, item);
    _persist();
    _pushToServer();
  }

  void toggle(String code) => isFavorite(code) ? remove(code) : addByCode(code);

  void toggleWith(Instrument instrument) =>
      isFavorite(instrument.code) ? remove(instrument.code) : add(instrument);

  /// Queues a `POST user/trade/marketwatch` with the full current list. The
  /// list is read when the request actually runs, so the last edit always wins.
  /// On failure the server list is reloaded, rolling back the optimistic edit.
  void _pushToServer() {
    // A GET still in flight holds the pre-edit list; drop it so it cannot
    // overwrite this edit before the POST reads [favoriteCodes].
    _syncSeq++;
    _writeChain = _writeChain.then((_) async {
      if (!await _hasToken()) return;
      try {
        final res = await Get.find<ApiClient>().postWeb<dynamic>(
          ApiEndpoints.marketWatch,
          data: {'symbols': favoriteCodes},
        );
        final body = res.data;
        final ok = body is Map && body['status'] == true;
        final symbols = ok ? _symbolsFrom(body) : null;
        if (symbols == null) {
          log.w('FavoritesService: marketwatch POST rejected: $body');
          await syncFromServer();
        }
      } catch (e) {
        log.e('FavoritesService: marketwatch POST failed: $e');
        await syncFromServer();
      }
    });
  }

  /// Replaces [favorites] with the server symbols, keeping the cached name and
  /// category of symbols already known, and moves socket subscriptions to match.
  void _applyServerList(List<dynamic> serverSymbols) {
    final known = {for (final i in favorites) i.code: i};
    final next = <Instrument>[];
    final seen = <String>{};
    for (final raw in serverSymbols) {
      final sym = MarketWatchV2Service.normalizeSymbol(raw.toString());
      if (sym.isEmpty || !seen.add(sym)) continue;
      next.add(
        known[sym] ??
            Instrument(
              code: sym,
              name: sym,
              category: InstrumentCategory.classify(sym),
            ),
      );
    }

    final removed = known.keys.where((c) => !seen.contains(c)).toList();
    final added = seen.where((c) => !known.containsKey(c)).toList();
    favorites.assignAll(next);
    _persist();
    if (removed.isNotEmpty) _market.unsubscribeSymbols(removed);
    if (added.isNotEmpty) _market.subscribeSymbols(added);
  }

  /// GET and POST both answer `{status, data: {symbols: [...]}}`; older
  /// backends returned `data` as the bare list, so both are accepted.
  List<dynamic>? _symbolsFrom(dynamic body) {
    if (body is! Map) return null;
    final data = body['data'];
    if (data is List) return data;
    if (data is Map && data['symbols'] is List) return data['symbols'] as List;
    return null;
  }

  Future<bool> _hasToken() async {
    final token = await Get.find<FlutterSecureStorage>().read(
      key: ApiInterceptor.tokenKey,
    );
    return token != null && token.isNotEmpty;
  }

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
        out.add(
          Instrument(
            code: sym,
            name: (json['name'] ?? '').toString(),
            category: (json['category'] ?? '').toString(),
          ),
        );
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
