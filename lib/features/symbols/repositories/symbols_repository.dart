import '../../../core/network/api_response.dart';
import '../models/symbol_models.dart';

/// Single source of truth for symbol/spec data. Today it returns demo data
/// after a short delay to simulate the network; when the instruments API lands,
/// replace the body of [getSymbols] with an `ApiClient` call + `fromJson`. The
/// controller and view do not change when that swap happens.
class SymbolsRepository {
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
