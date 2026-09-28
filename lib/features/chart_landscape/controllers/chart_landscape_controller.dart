import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/trade/trade_ticket.dart';
import '../../chart/services/chart_preload_service.dart';
import '../../positions/controllers/positions_controller.dart';
import '../../symbols/services/market_watch_v2_service.dart';

/// Orchestrates the landscape full-screen chart + trade split view.
///
/// It owns only what is specific to this PRESENTATION: the orientation and
/// system-UI lock, and whether the trade rail is expanded. Everything else is
/// delegated to the same shared singletons portrait uses — symbol selection to
/// [MarketWatchV2Service], order placement to [PositionsController] — so the
/// two orientations can never drift apart in behaviour.
///
/// The chart itself is the SAME warm webview the Markets tab was showing: that
/// tab unmounts and releases it as this route opens, so full screen attaches an
/// already-painted instance instead of warming a second one (two live chart
/// webviews make the platform drop a render surface).
///
/// It is a plain [GetxController] rather than a `BaseController`: the screen
/// has no REST call of its own — the chart is a webview and quotes stream from
/// the shared market-watch socket — so there is no [DataState] to drive.
class ChartLandscapeController extends GetxController {
  ChartLandscapeController({
    required this._marketWatch,
    required this._positions,
    required this._preload,
  });

  final MarketWatchV2Service _marketWatch;
  final PositionsController _positions;
  final ChartPreloadService _preload;

  /// Whether the trade rail is expanded. Collapsing it gives the chart the full
  /// width for analysis without leaving the screen.
  final railOpen = true.obs;

  /// Guards the orientation restore so an exit via the back pill followed by
  /// the route's own teardown does not re-issue the system calls.
  bool _restored = false;

  /// Symbol currently displayed, kept in step with the app-wide selection so
  /// leaving landscape lands the user on the same instrument in portrait.
  String get symbol {
    final selected = _marketWatch.selectedSymbol.value;
    return selected.isEmpty ? ChartPreloadService.defaultSymbol : selected;
  }

  /// The app-wide selected-symbol observable, exposed so the chart pane can
  /// watch it directly instead of rebuilding inside a reactive builder.
  RxString get selectedSymbol => _marketWatch.selectedSymbol;

  /// Chart URL for [value], built by the shared preload service so asking for
  /// the warmed symbol returns the exact string it was warmed with — the
  /// handed-off instance then attaches with no reload.
  String urlFor(String value) => _preload.urlFor(value);

  /// False until the device has finished rotating into landscape.
  ///
  /// The chart is held back until then on purpose: attaching it while the
  /// window is still portrait-shaped makes the charting library lay out at the
  /// wrong size and then rebuild when the rotation lands — which showed up as
  /// a blank pane and a multi-second load. Mounting once, at the final size,
  /// keeps the handed-over instance instant.
  final rotationSettled = false.obs;

  _RotationWatcher? _rotationWatcher;

  /// Starts watching for the OS to actually apply the rotation.
  ///
  /// This is EVENT-DRIVEN (`WidgetsBindingObserver.didChangeMetrics`), not a
  /// polling loop. A poll built on `WidgetsBinding.instance.endOfFrame` only
  /// advances when something ELSE schedules a new frame — on an otherwise
  /// idle screen that could be nothing for seconds, and it only happened to
  /// unblock when a live price tick forced a rebuild. That was the real cause
  /// of "chart takes 5-7 seconds to load": the wait, not the chart.
  /// `didChangeMetrics` fires the instant the OS reports the new window size,
  /// independent of whether Flutter is painting anything.
  void _watchRotation() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    if (view.physicalSize.width > view.physicalSize.height) {
      rotationSettled.value = true;
      return;
    }
    _rotationWatcher = _RotationWatcher(() {
      if (isClosed) return;
      rotationSettled.value = true;
      _rotationWatcher?.dispose();
      _rotationWatcher = null;
    });
  }

  @override
  void onInit() {
    super.onInit();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _watchRotation();
  }

  void toggleRail() => railOpen.toggle();

  /// Restores portrait + normal system chrome and pops. Safe to call from the
  /// back pill, a `PopScope` callback and [onClose] — only the first one acts.
  Future<void> exit() async {
    _restoreOrientation();
    if (Get.key.currentState?.canPop() ?? false) Get.back<void>();
  }

  void _restoreOrientation() {
    if (_restored) return;
    _restored = true;
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// Mirrors a symbol change into the app-wide selection and persists it as the
  /// next launch's warm symbol, exactly as the portrait tab does.
  void selectSymbol(String next) {
    if (next.isEmpty || next == symbol) return;
    _marketWatch.selectSymbol(next);
    _preload.saveSymbol(next);
  }

  /// Submits the ticket through the shared positions controller — the same
  /// call the portrait dock makes, so validation, toasts and logging match.
  Future<void> submitTicket(TradeTicket ticket) =>
      _positions.placeTicket(ticket);

  @override
  void onClose() {
    _rotationWatcher?.dispose();
    _restoreOrientation();
    super.onClose();
  }
}

/// Minimal [WidgetsBindingObserver] that calls [onChanged] the next time the
/// window's metrics change, then stays alive for a second call in case the
/// platform reports the rotation in two steps (has been observed on some
/// Android OEM skins). Disposes itself after the caller is done.
class _RotationWatcher extends WidgetsBindingObserver {
  _RotationWatcher(this.onChanged) {
    WidgetsBinding.instance.addObserver(this);
  }

  final VoidCallback onChanged;

  @override
  void didChangeMetrics() => onChanged();

  void dispose() => WidgetsBinding.instance.removeObserver(this);
}
