import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_response.dart';
import '../models/symbol_models.dart';

/// Single source of truth for symbol/spec data. [getSymbols] still returns demo
/// spec cards for the "Symbols & specs" screen; [getInstruments] hits the live
/// instruments REST endpoint and parses `data.symbols` into [Instrument]s for
/// the search sheet + favorites metadata. Networking lives here, never in a
/// controller.
class SymbolsRepository {
  SymbolsRepository(this._api);

  final ApiClient _api;

  /// Live instruments list. Parses the envelope's `data.symbols` into
  /// [Instrument]s and `data.categories` into the filter pill names. Pass [q]
  /// to let the API filter server-side.
  Future<ApiResponse<InstrumentCatalog>> getInstruments({String? q}) {
    final query = q == null || q.isEmpty ? null : {'q': q};
    return ApiEnvelope.guard<InstrumentCatalog>(
      () => _api.get<dynamic>(ApiEndpoints.instruments, query: query),
      (data) {
        if (data is! Map<String, dynamic>) return InstrumentCatalog.empty;
        final rawSymbols = data['symbols'];
        final rawCategories = data['categories'];
        final instruments = rawSymbols is List
            ? rawSymbols
                .whereType<Map<String, dynamic>>()
                .map(Instrument.fromJson)
                .where((i) => i.code.isNotEmpty)
                .toList()
            : <Instrument>[];
        final categories = rawCategories is List
            ? rawCategories
                .whereType<Map<String, dynamic>>()
                .map((c) => (c['name'] ?? '').toString())
                .where((name) => name.isNotEmpty)
                .toList()
            : <String>[];
        return InstrumentCatalog(
          instruments: instruments,
          categories: categories,
        );
      },
      showErrorToast: false,
    );
  }

  Future<ApiResponse<List<SymbolSpec>>> getSymbols() async {
    try {
      // Simulated network latency so the shimmer is visible during development.
      await Future<void>.delayed(const Duration(milliseconds: 900));

      return ApiResponse.success(const [..._base, ..._base]);
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  // -------------------------------------------------------------------------
  // Demo data (moved out of the controller). Delete when the API is wired.
  // -------------------------------------------------------------------------
  static const _base = <SymbolSpec>[
    SymbolSpec(
      code: 'XAUUSD',
      name: 'Gold',
      category: 'Metals',
      spread: '2.8 pips',
      leverage: '1:20',
      contract: '100',
      minLot: '0.01',
      maxLot: '20.00',
      pipValue: '\$10.00',
      swapLong: '-2.4',
      swapShort: '+0.8',
    ),
    SymbolSpec(
      code: 'EURUSD',
      name: 'Euro / Dollar',
      category: 'Forex',
      spread: '2.8 pips',
      leverage: '1:20',
      contract: '100',
      minLot: '0.01',
      maxLot: '20.00',
      pipValue: '\$10.00',
      swapLong: '-2.4',
      swapShort: '+0.8',
    ),
    SymbolSpec(
      code: 'GBPUSD',
      name: 'Pound / Dollar',
      category: 'Forex',
      spread: '2.8 pips',
      leverage: '1:20',
      contract: '100',
      minLot: '0.01',
      maxLot: '20.00',
      pipValue: '\$10.00',
      swapLong: '-2.4',
      swapShort: '+0.8',
    ),
  ];
}
