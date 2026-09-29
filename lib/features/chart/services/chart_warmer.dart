import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

/// JS readiness probe shared by the warm and the on-screen webview.
///
/// Charting libraries stack several `<canvas>` elements (crosshair/overlay,
/// watermark, the actual OHLC plot). Probing `document.querySelector('canvas')`
/// grabs whichever is FIRST in the DOM — often a thin overlay that settles to a
/// stable, non-zero size almost instantly while the real plot canvas is still
/// empty. That mismatch is what let the on-screen webview reveal a chart whose
/// header/toolbar were painted but whose candle area was blank, worst on slow
/// old devices where the real plot canvas takes longer to draw.
///
/// This probes the LARGEST canvas by area (almost always the plot pane) and
/// samples actual pixel data so a canvas that is merely sized but still blank
/// does not read as "ready".
const String paintProbeJs = '''
  (function() {
    var canvases = document.querySelectorAll('canvas');
    if (!canvases.length) return '';
    var target = null;
    var bestArea = 0;
    for (var i = 0; i < canvases.length; i++) {
      var el = canvases[i];
      var area = el.width * el.height;
      if (area > bestArea) { bestArea = area; target = el; }
    }
    if (!target || !(target.width > 0 && target.height > 0)) return '';
    var painted = 'unknown';
    try {
      var ctx = target.getContext('2d');
      if (ctx) {
        // Sample a small grid instead of the whole canvas — cheap enough to
        // run every 100ms without hurting an already-slow device.
        var w = target.width, h = target.height, sum = 0, samples = 0;
        for (var x = 4; x < w; x += Math.max(1, (w / 8) | 0)) {
          for (var y = 4; y < h; y += Math.max(1, (h / 8) | 0)) {
            var d = ctx.getImageData(x, y, 1, 1).data;
            sum += d[0] + d[1] + d[2] + d[3];
            samples++;
          }
        }
        painted = samples > 0 ? String(sum) : 'unknown';
      }
    } catch (e) {
      painted = 'unknown';
    }
    return target.width + 'x' + target.height + ':' + painted;
  })();
''';

/// Shared machinery for pre-warming a chart page in an off-screen
/// [HeadlessInAppWebView] so an on-screen [InAppWebView] can attach an
/// already-painted instance instead of doing a cold load.
///
/// One warmer owns exactly ONE headless instance, and a headless instance can
/// back only ONE on-screen webview at a time — hence [claim] / [release].
/// Portrait and landscape therefore use SEPARATE warmers ([ChartPreloadService]
/// and `ChartLandscapePreloadService`): the charting library re-creates its
/// widget on every resize, so a single instance warmed at one orientation would
/// re-initialise (2-3 visible redraws) when attached at the other.
abstract class ChartWarmer extends GetxService {
  HeadlessInAppWebView? headlessWebView;

  /// Keeps the ON-SCREEN webview's native platform view alive across widget
  /// dispose/rebuild (e.g. leaving the Charts tab, popping the landscape
  /// route). Without this, `flutter_inappwebview` destroys the native peer the
  /// moment its `InAppWebView` element is disposed — so even though this
  /// warmer's own `HeadlessInAppWebView` object survives, the platform view it
  /// pointed at is gone, and the NEXT attach is a full cold reload no matter
  /// how "warm" the Dart side thinks it is. This was the actual cause of
  /// "every portrait<->landscape round trip reloads the chart".
  final keepAlive = InAppWebViewKeepAlive();

  /// True once the warmed page has a canvas whose size has stopped changing,
  /// i.e. the chart library finished its multi-stage boot.
  bool isReady = false;

  final _claimed = false.obs;

  DateTime? _loadStartedAt;
  DateTime? _readyAt;

  /// Log prefix so portrait and landscape traces are distinguishable.
  @protected
  String get traceTag;

  /// Symbol the warm instance is currently showing. The on-screen webview reads
  /// this to avoid a needless symbol switch on first attach.
  String get currentSymbol;

  String? _shownSymbol;

  /// Symbol the warm instance is showing RIGHT NOW. [currentSymbol] is only the
  /// boot symbol (kept fixed so the preload URL never changes); once an
  /// on-screen webview switches the page in place via JS, the next screen that
  /// attaches the same instance must start from this instead.
  String get shownSymbol => _shownSymbol ?? currentSymbol;

  /// Called by the on-screen webview after it switched the attached warm page.
  void noteShownSymbol(String symbol) => _shownSymbol = symbol;

  /// Hands the warm instance to a caller, or null when it is already in use.
  HeadlessInAppWebView? claim() {
    if (headlessWebView == null || _claimed.value) return null;
    _claimed.value = true;
    trace('claimed by on-screen webview (isReady=$isReady)');
    return headlessWebView;
  }

  /// Returns the warm instance to the pool when a screen is disposed.
  void release() {
    _claimed.value = false;
    trace('released back to pool');
  }

  /// True while an on-screen webview holds the warm instance.
  bool get isClaimed => _claimed.value;

  /// Completes once no on-screen webview holds the warm instance. A popped
  /// route's widgets are disposed only after its exit animation, so a screen
  /// that wants the instance back must wait for this instead of claiming on pop.
  Future<void> waitUntilReleased() async {
    if (!_claimed.value) return;
    await _claimed.stream.firstWhere((claimed) => !claimed);
  }

  /// Milliseconds the warm-up took to reach a settled canvas, or null while it
  /// is still warming.
  int? get warmupMs => (_loadStartedAt == null || _readyAt == null)
      ? null
      : _readyAt!.difference(_loadStartedAt!).inMilliseconds;

  /// Builds and runs the headless instance for [url] at [size]. A second call
  /// is a no-op while an instance already exists, so callers can warm eagerly
  /// without guarding.
  ///
  /// [size] MUST match the size the chart will have on screen — the charting
  /// library rebuilds its widget on resize, and a mismatch turns the warm
  /// attach into a visible re-initialisation.
  @protected
  Future<void> warmUp({required String url, required Size size}) async {
    if (headlessWebView != null) return;

    _loadStartedAt = DateTime.now();
    isReady = false;
    trace('warming ${size.width.round()}x${size.height.round()} url=$url');

    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(url),
        // iOS: follow the server's cache headers (see warmSettings) so a
        // relaunch never runs a stale cached chart page.
        cachePolicy: URLRequestCachePolicy.USE_PROTOCOL_CACHE_POLICY,
      ),
      // A real off-screen size is REQUIRED — the default 0x0 makes the chart
      // skip layout/rendering entirely.
      initialSize: size,
      initialSettings: warmSettings,
      onLoadStart: (controller, loadedUrl) {
        _loadStartedAt = DateTime.now();
        trace('headless onLoadStart url=$loadedUrl');
      },
      onLoadStop: (controller, loadedUrl) {
        trace('headless onLoadStop url=$loadedUrl');
        // HTML finished, but the chart CANVAS is still booting. Flip [isReady]
        // only once it is painted so the on-screen webview can reveal instantly.
        unawaited(_markReadyWhenPainted(controller));
      },
      // Low-RAM devices (common on older/entry Android builds) let the OS OOM
      // killer take the WebView renderer process under memory pressure. Without
      // this the warm instance silently stays "ready" while its native peer is
      // gone, so every later attach looks warm but paints nothing — the app
      // must rebuild it from scratch instead of leaving it for dead.
      onRenderProcessGone: (controller, detail) {
        trace('headless renderer GONE (didCrash=${detail.didCrash}) — '
            'tearing down for a fresh warm-up');
        disposeWarm();
      },
    );

    await headlessWebView?.run();
  }

  /// Settings shared by every warm instance.
  ///
  /// Cache mode MUST follow the server's headers. The chart page is served with
  /// `Cache-Control: no-cache` and pulls unhashed scripts
  /// (`charting_library.standalone.js`, `chart-datafeed.js`); forcing
  /// cache-first made a relaunch run the OLD cached page/scripts against the
  /// NEW server bundle after every deploy — the toolbar rendered but the chart
  /// canvas stayed blank. LOAD_DEFAULT still reuses cached files, it just
  /// revalidates them (a cheap 304 when nothing changed).
  @protected
  InAppWebViewSettings get warmSettings => InAppWebViewSettings(
        javaScriptEnabled: true,
        transparentBackground: true,
        cacheEnabled: true,
        cacheMode: CacheMode.LOAD_DEFAULT,
        domStorageEnabled: true,
        databaseEnabled: true,
        allowsInlineMediaPlayback: true,
        mediaPlaybackRequiresUserGesture: false,
        supportZoom: false,
        // Virtual Display (the default) is measurably less stable across
        // older Android/WebView builds — the on-screen fallback already uses
        // Hybrid Composition for this reason; the warm instance must match it
        // so the SAME compositing mode is in effect whether the chart cold
        // loads or attaches from warm-up.
        // Hybrid composition draws the webview into its own Android surface,
        // which is what the Samsung Mali driver drops (blank chart pane). TLC
        // (virtual display) composites through the Flutter surface instead.
        useHybridComposition: false,
      );

  /// Tears the warm instance down and resets the warmer so a later [warmUp]
  /// builds a fresh one. Used to release memory when the warmed screen is no
  /// longer reachable (tab left, logout, memory pressure).
  void disposeWarm() {
    if (headlessWebView == null) return;
    headlessWebView?.dispose();
    headlessWebView = null;
    isReady = false;
    _claimed.value = false;
    _shownSymbol = null;
    _loadStartedAt = null;
    _readyAt = null;
    trace('warm instance disposed');
  }

  /// Polls the headless page until the chart CANVAS is painted AND its size has
  /// stayed the SAME across several consecutive polls, then marks the service
  /// ready. HTML `onLoadStop` fires well before the charting library finishes
  /// its multi-stage boot (shell → init → state restore → datafeed redraw), and
  /// each stage re-lays-out the canvas. Waiting for a STABLE canvas is what lets
  /// the on-screen webview reveal a fully-drawn chart with no visible refresh.
  Future<void> _markReadyWhenPainted(InAppWebViewController controller) async {
    var last = '';
    var stable = 0;
    var polls = 0;
    var resizes = 0;
    for (var attempt = 0; attempt < 100; attempt++) {
      // The instance can be torn down mid-poll (tab left, memory pressure).
      if (headlessWebView == null) return;
      polls++;
      String probe = '';
      try {
        final res = await controller.evaluateJavascript(source: paintProbeJs);
        if (res is String) probe = res;
      } catch (_) {
        // Controller can momentarily reject eval during boot — keep polling.
      }
      if (probe.isNotEmpty && probe == last) {
        if (++stable >= 4) break;
      } else {
        // Each distinct probe value is either a re-layout or a fresh paint of
        // the charting library's plot canvas — the measurable proxy for the
        // visible "flicker"/blank-chart window.
        if (probe.isNotEmpty) {
          resizes++;
          trace('headless canvas change #$resizes: "$last" -> "$probe"');
        }
        stable = 0;
        last = probe;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (headlessWebView == null) return;
    isReady = true;
    _readyAt = DateTime.now();
    trace('headless READY canvas=$last polls=$polls resizes=$resizes');
  }


  /// Logical size of the device screen, independent of the current rotation
  /// (`physicalSize` already follows the device, so callers that need a fixed
  /// orientation must order the edges themselves).
  @protected
  Size screenSize() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    if (size.width <= 0 || size.height <= 0) return const Size(375, 812);
    return size;
  }

  @protected
  void trace(String message) {
    if (!kDebugMode) return;
    final started = _loadStartedAt;
    final offset = started == null
        ? ''
        : '+${DateTime.now().difference(started).inMilliseconds}ms ';
    debugPrint('[$traceTag] $offset$message');
  }

  @override
  void onClose() {
    headlessWebView?.dispose();
    headlessWebView = null;
    super.onClose();
  }
}
