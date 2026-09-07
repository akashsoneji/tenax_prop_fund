/// A tradable symbol plus its full spec sheet, shown as one card on the
/// "Symbols & specs" screen.
class SymbolSpec {
  const SymbolSpec({
    required this.code,
    required this.name,
    required this.category,
    required this.spread,
    required this.leverage,
    required this.contract,
    required this.minLot,
    required this.maxLot,
    required this.pipValue,
    required this.swapLong,
    required this.swapShort,
  });

  final String code;
  final String name;
  final String category;

  // Spec grid values (2 rows x 4 cols).
  final String spread;
  final String leverage;
  final String contract;
  final String minLot;
  final String maxLot;
  final String pipValue;
  final String swapLong;
  final String swapShort;

  /// Muted subtitle under the code, e.g. "Gold · Metals".
  String get subtitle => '$name · $category';
}
