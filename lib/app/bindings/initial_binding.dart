import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../core/network/api_client.dart';
import '../../core/websocket/websocket_manager.dart';
import '../../features/symbols/services/favorites_service.dart';
import '../../features/symbols/services/market_watch_v2_service.dart';
import '../../features/authentication/repositories/auth_repository.dart';
import '../../features/authentication/services/auth_service.dart';
import '../flavor/flavor_config.dart';

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
    Get.put<WebSocketManager>(
      WebSocketManager(_config),
      permanent: true,
    );
    // Live market-watch socket. Permanent + self-connecting (see its onInit)
    // so ticks are flowing from app open and survive background/foreground.
    Get.put<MarketWatchV2Service>(
      MarketWatchV2Service(_config, Get.find<FlutterSecureStorage>()),
      permanent: true,
    );
    // Favorited instruments store — persists metadata + keeps the socket
    // subscription in lockstep with the favorite set. Right after the socket so
    // onInit can resubscribe saved favorites from app open.
    Get.put<FavoritesService>(
      FavoritesService(Get.find<GetStorage>(), Get.find<MarketWatchV2Service>()),
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
  }
}