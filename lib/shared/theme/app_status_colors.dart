import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The one place a backend status string becomes a colour.
///
/// Statuses come from different endpoints (payouts, commissions, invoices) but
/// mean the same things, so every list shows "paid" green and "rejected" red
/// the same way. Unknown / in-flight statuses fall back to the warning ink.
class AppStatusColors {
  const AppStatusColors._();

  static const _success = {'paid', 'disbursed', 'completed', 'approved'};
  static const _info = <String>{};
  static const _error = {'rejected', 'cancelled', 'canceled', 'failed'};

  /// Colour for [status] (case-insensitive). Pass [info] to give extra
  /// statuses the info tone — e.g. payouts show "approved" as info (approved
  /// but not yet paid), while commissions treat it as success.
  static Color of(
    String status,
    ColorScheme scheme, {
    Set<String> info = _info,
  }) {
    final key = status.toLowerCase();
    if (info.contains(key)) return AppColors.info;
    if (_success.contains(key)) return AppColors.success;
    if (_error.contains(key)) return scheme.error;
    return AppColors.warningInk;
  }

  /// "pending_review" → "Pending_review": first letter upper-cased, as the
  /// status lists have always shown raw backend statuses.
  static String label(String status) {
    final key = status.toLowerCase();
    return key.isEmpty ? '-' : key[0].toUpperCase() + key.substring(1);
  }
}
