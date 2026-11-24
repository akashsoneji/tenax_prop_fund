import 'package:get/get.dart';

import '../../features/accounts/services/primary_account_service.dart';
import '../../features/positions/services/account_ws_service.dart';
import '../../features/positions/services/positions_ws_service.dart';
import '../../features/symbols/services/favorites_service.dart';
import '../../features/symbols/services/market_watch_v2_service.dart';

/// Wipes the per-user state that OUTLIVES a logout.
///
/// Secure storage is cleared by `AuthRepository.clearSession()` and the
/// route-scoped feature controllers are disposed by `Get.offAllNamed`, but the
/// app's PERMANENT singletons (registered in `InitialBinding`) survive both. So
/// without this the next user sees the previous user's MT5 account list and
/// keeps receiving their live socket frames — the sockets stay authed on the old
/// login until the account number happens to change.
abstract final class SessionManager {
  /// Called right after the session is cleared (logout, and the 401 handler).
  /// The sockets restart with no token in storage, so they simply stay down.
  static void clear() => _resetServices();

  /// Called right after a successful login so the sockets re-auth with the NEW
  /// token and the active-account list is fetched for the user who just signed
  /// in. Both run in the background; neither blocks the first frame.
  static void start() {
    _resetServices();
    if (Get.isRegistered<PrimaryAccountService>()) {
      Get.find<PrimaryAccountService>().refresh();
    }
    if (Get.isRegistered<FavoritesService>()) {
      Get.find<FavoritesService>().syncFromServer();
    }
  }

  static void _resetServices() {
    if (Get.isRegistered<PrimaryAccountService>()) {
      Get.find<PrimaryAccountService>().resetForNewSession();
    }
    if (Get.isRegistered<PositionsWsService>()) {
      Get.find<PositionsWsService>().resetForNewSession();
    }
    if (Get.isRegistered<AccountWsService>()) {
      Get.find<AccountWsService>().resetForNewSession();
    }
    if (Get.isRegistered<MarketWatchV2Service>()) {
      Get.find<MarketWatchV2Service>().resetForNewSession();
    }
  }
}
