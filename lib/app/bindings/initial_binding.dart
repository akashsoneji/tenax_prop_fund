import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../core/app_status/app_status_controller.dart';
import '../../core/app_status/app_status_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_interceptor.dart';
import '../../core/websocket/websocket_manager.dart';
import '../../features/positions/services/account_ws_service.dart';
import '../../features/positions/services/positions_ws_service.dart';
import '../../features/accounts/services/primary_account_service.dart';
import '../../features/symbols/services/favorites_service.dart';
import '../../features/symbols/services/market_watch_v2_service.dart';
import '../../features/authentication/repositories/auth_repository.dart';
import '../../features/authentication/services/auth_service.dart';
import '../flavor/flavor_config.dart';
import '../routes/app_routes.dart';
import '../session/session_manager.dart';

/// Registers app-wide singletons before any route loads. Feature-specific
/// dependencies are registered by their own bindings.
class InitialBinding extends Bindings {
  InitialBinding(this._config);

  final FlavorConfig _config;

  @override
  void dependencies() {
    // Storage backends first.
    Get.put<FlutterSecureStorage>(
      const FlutterSecureStorage(),
      permanent: true,
    );
    Get.put<GetStorage>(GetStorage(), permanent: true);

    // SettingsController is already registered in main() before runApp so the
    // first GetMaterialApp.build can read theme + locale from it.

    // App-wide brand + env config.
    Get.put<FlavorConfig>(_config, permanent: true);

    // Network + WS singletons.
    Get.put<ApiClient>(
      ApiClient(_config, Get.find<FlutterSecureStorage>()),
      permanent: true,
    );
    // Single owner of every socket in the app. Services below open named
    // connections through it; it reconnects them all on app resume.
    final sockets = Get.put<WebSocketManager>(
      WebSocketManager(),
      permanent: true,
    );
    // Live market-watch socket. Permanent + self-connecting (see its onInit)
    // so ticks are flowing from app open and survive background/foreground.
    Get.put<MarketWatchV2Service>(
      MarketWatchV2Service(_config, Get.find<FlutterSecureStorage>(), sockets),
      permanent: true,
    );
    // Favorited instruments store — persists metadata + keeps the socket
    // subscription in lockstep with the favorite set. Right after the socket so
    // onInit can resubscribe saved favorites from app open.
    Get.put<FavoritesService>(
      FavoritesService(Get.find<GetStorage>(), Get.find<MarketWatchV2Service>()),
      permanent: true,
    );

    // Live trade sockets: `/op` (open positions) + `/po` (pending orders) and
    // `/account` (equity/margin). Permanent + self-connecting so the Positions
    // summary keeps ticking regardless of which tab is showing.
    Get.put<PositionsWsService>(
      PositionsWsService(_config, Get.find<FlutterSecureStorage>(), sockets),
      permanent: true,
    );
    Get.put<AccountWsService>(
      AccountWsService(_config, Get.find<FlutterSecureStorage>(), sockets),
      permanent: true,
    );

    // Auth data layer — shared across every flavor and available app-wide so
    // logout (from the More tab) and the splash session check can reach it.
    Get.put<AuthRepository>(
      AuthRepository(
        AuthService(Get.find<ApiClient>()),
      Get.find<FlutterSecureStorage>(),
      ),
      permanent: true,
    );

    // App-wide holder of the user's ACTIVE (primary) MT5 account. Its
    // background fetch runs on demand (post-login / splash) so it never blocks
    // or alters the main-thread dashboard load.
    Get.put<PrimaryAccountService>(
      PrimaryAccountService(Get.find<ApiClient>()),
      permanent: true,
    );

    // Maintenance mode + force-update. Service polls `/mobile-app-details` and
    // pushes into the controller; the controller drives the overlay + dialog.
    Get.put<AppStatusService>(AppStatusService(), permanent: true);
    Get.put<AppStatusController>(
      AppStatusController(Get.find<AppStatusService>()),
      permanent: true,
    );

    // Expired/revoked token on ANY authenticated request: wipe the session and
    // send the user back to Get Started. Registered here (not in core/) so the
    // network layer stays free of auth + routing dependencies.
    ApiInterceptor.onUnauthorized = _handleUnauthorized;
  }

  Future<void> _handleUnauthorized() async {
    try {
      await Get.find<AuthRepository>().clearSession();
    } finally {
      SessionManager.clear();
      if (Get.currentRoute != AppRoutes.getStarted) {
        Get.offAllNamed(AppRoutes.getStarted);
      }
    }
  }
}