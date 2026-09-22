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

/// A tradable instrument as returned by the instruments REST API. Carries just
/// the metadata a favorite needs to render a card (code + name + category);
/// live prices come from [MarketWatchV2Service]. Also persisted verbatim by
/// [FavoritesService] via [toJson]/[fromJson].
class Instrument {
  const Instrument({
    required this.code,
    required this.name,
    required this.category,
  });

  final String code;
  final String name;
  final String category;

  factory Instrument.fromJson(Map<String, dynamic> json) {
    final code =
        (json['display_symbol'] ?? json['symbol'] ?? json['code'] ?? '')
            .toString();
    final name = (json['name'] ?? '').toString();
    final rawCat =
        (json['category_name'] ?? json['category'] ?? '').toString();
    final category =
        rawCat.isNotEmpty ? rawCat : InstrumentCategory.classify(code);
    return Instrument(code: code, name: name, category: category);
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'category': category,
      };
}

/// Parsed `data` of the instruments endpoint: the instrument list plus the
/// category names the API itself exposes (used to build the filter pills so
/// they always match the data).
class InstrumentCatalog {
  const InstrumentCatalog({required this.instruments, required this.categories});

  final List<Instrument> instruments;
  final List<String> categories;

  static const empty = InstrumentCatalog(instruments: [], categories: []);
}

/// Category filter values for the instrument search sheet. [all] is the
/// "everything" pill and is always prepended to the API categories.
/// [classify] infers a bucket from a symbol code when the API omits a category.
abstract class InstrumentCategory {
  static const all = 'All';
  static const currency = 'Currency';
  static const metals = 'Metals';
  static const crypto = 'Crypto';
  static const indices = 'Indices';
  static const shares = 'Shares';

  /// Best-effort bucket for a bare symbol code (used when the API sends none).
  static String classify(String code) {
    final c = code.toUpperCase();
    if (c.contains('XAU') || c.contains('XAG') || c.contains('GOLD')) {
      return metals;
    }
    if (c.contains('BTC') || c.contains('ETH') || c.contains('USDT')) {
      return crypto;
    }
    if (c.contains('US30') ||
        c.contains('NAS') ||
        c.contains('SPX') ||
        c.contains('GER')) {
      return indices;
    }
    if (c.length == 6 && RegExp(r'^[A-Z]{6}$').hasMatch(c)) return currency;
    return shares;
  }
}
