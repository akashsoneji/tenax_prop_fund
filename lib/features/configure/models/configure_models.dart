import 'package:flutter/foundation.dart';

/// A single selectable add-on on the Configure screen.
@immutable
class Addon {
  const Addon({
    required this.id,
    required this.title,
    required this.description,
    required this.priceLabel,
    required this.tagLabel,
    this.priceMinor = 0,
  });

  final String id;
  final String title;
  final String description;
  final String priceLabel;
  final String tagLabel;
  final int priceMinor;
}

/// A row in the Configure "Summary" card.
@immutable
class SummaryRow {
  const SummaryRow(this.label, this.value, {this.emphasize = false});
  final String label;
  final String value;
  final bool emphasize;
}
