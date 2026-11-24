import 'dart:async';

import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../symbols/services/favorites_service.dart';

/// A single MT5 account as returned by `GET /mt5accounts/get`. Only the fields
/// the active-account selector needs are parsed.
class PrimaryAccountItem {
  const PrimaryAccountItem({
    required this.id,
    required this.login,
    required this.isPrimary,
    required this.isActive,
    required this.planName,
  });

  final int id;
  final String login;
  final bool isPrimary;
  final bool isActive;
  final String planName;

  factory PrimaryAccountItem.fromJson(Map<String, dynamic> json) =>
      PrimaryAccountItem(
        id: (json['id'] as num?)?.toInt() ?? 0,
        login: json['login']?.toString() ?? '',
        isPrimary: json['is_primary'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? false,
        planName: json['plan_name'] as String? ?? '',
      );
}

/// App-wide holder of the user's ACTIVE (primary) MT5 account.
///
/// On login/startup it fetches `GET /mt5accounts/get` in the BACKGROUND (silent,
/// fire-and-forget) so it never blocks or alters the main-thread dashboard load.
/// When the user picks a different account in the switcher, [setPrimary] POSTs
/// `/mt5accounts/set-primary` — also in the background — and optimistically
/// updates the local state so the UI reflects the choice immediately.
class PrimaryAccountService extends GetxService {
  PrimaryAccountService(this._api);

  final ApiClient _api;

  /// The active account's id (`data.primary_account_id`). `null` until the
  /// background fetch resolves.
  final Rxn<int> primaryAccountId = Rxn<int>();

  /// All MT5 accounts from the last fetch (for the selector list).
  final RxList<PrimaryAccountItem> accounts = <PrimaryAccountItem>[].obs;

  /// The currently active account object, if present in [accounts].
  PrimaryAccountItem? get primary => accounts
      .firstWhereOrNull((a) => a.id == primaryAccountId.value);

  /// Drops every cached value so a newly logged-in user never sees the previous
  /// user's accounts. The service itself is permanent, so this is what stands in
  /// for disposal between sessions.
  void resetForNewSession() {
    _session++;
    accounts.clear();
    primaryAccountId.value = null;
  }

  /// Background refresh of the accounts list + active id. Silent (no toast) so a
  /// transient failure never interrupts the user; safe to call fire-and-forget.
  Future<void> refresh() async {
    final session = _session;
    final res = await ApiEnvelope.guard<_Mt5AccountsData>(
      () => _api.get<Map<String, dynamic>>(ApiEndpoints.mt5Accounts),
      _Mt5AccountsData.fromData,
      showErrorToast: false,
    );
    final data = res.data;
    // A logout/login happened while this was in flight — the response belongs
    // to the previous user.
    if (session != _session) return;
    if (!res.success || data == null) return;
    accounts.assignAll(data.accounts);
    primaryAccountId.value = data.primaryAccountId ??
        data.accounts.firstWhereOrNull((a) => a.isPrimary)?.id;
  }

  /// Sets [accountId] as the primary account. Optimistically updates local
  /// state, then persists via `POST /mt5accounts/set-primary` in the background.
  /// Returns true on success; on failure the previous id is restored.
  Future<bool> setPrimary(int accountId) async {
    final previous = primaryAccountId.value;
    if (previous == accountId) return true;
    primaryAccountId.value = accountId;
    final request = ++_setPrimaryRequest;
    final session = _session;

    final res = await ApiEnvelope.guard<int?>(
      () => _api.post<Map<String, dynamic>>(
        ApiEndpoints.mt5SetPrimary,
        data: {'account_id': accountId},
      ),
      (data) => data is Map<String, dynamic>
          ? (data['primary_account_id'] as num?)?.toInt()
          : null,
      showErrorToast: false,
    );

    // A newer pick (or a session reset) superseded this request — its result
    // must not overwrite the newer value.
    final isLatest = request == _setPrimaryRequest && session == _session;
    if (!res.success) {
      if (isLatest && primaryAccountId.value == accountId) {
        primaryAccountId.value = previous;
      }
      return false;
    }
    if (isLatest && res.data != null) primaryAccountId.value = res.data;
    // The server watchlist follows the active account, so reload it once the
    // switch is saved.
    if (isLatest && Get.isRegistered<FavoritesService>()) {
      unawaited(Get.find<FavoritesService>().syncFromServer());
    }
    return true;
  }

  int _session = 0;
  int _setPrimaryRequest = 0;
}

/// Parsed `data` block of `GET /mt5accounts/get`.
class _Mt5AccountsData {
  const _Mt5AccountsData({required this.accounts, required this.primaryAccountId});

  final List<PrimaryAccountItem> accounts;
  final int? primaryAccountId;

  static _Mt5AccountsData fromData(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return const _Mt5AccountsData(accounts: [], primaryAccountId: null);
    }
    final raw = data['accounts'];
    return _Mt5AccountsData(
      accounts: [
        if (raw is List)
          for (final e in raw)
            if (e is Map<String, dynamic>) PrimaryAccountItem.fromJson(e),
      ],
      primaryAccountId: (data['primary_account_id'] as num?)?.toInt(),
    );
  }
}
