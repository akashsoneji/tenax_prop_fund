import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

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

  bool _claimed = false;

  DateTime? _loadStartedAt;
  DateTime? _readyAt;

  /// Log prefix so portrait and landscape traces are distinguishable.
  @protected
  String get traceTag;

  /// Symbol the warm instance is currently showing. The on-screen webview reads
  /// this to avoid a needless symbol switch on first attach.
  String get currentSymbol;

  /// Hands the warm instance to a caller, or null when it is already in use.
  HeadlessInAppWebView? claim() {
    if (headlessWebView == null || _claimed) return null;
    _claimed = true;
    trace('claimed by on-screen webview (isReady=$isReady)');
    return headlessWebView;
  }

  /// Returns the warm instance to the pool when a screen is disposed.
  void release() {
    _claimed = false;
    trace('released back to pool');
  }

  /// True while an on-screen webview holds the warm instance.
  bool get isClaimed => _claimed;

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
        // iOS: serve the cached shell/bundle when present (the chart bundle is
        // immutable), hitting the network only on a cold cache.
        cachePolicy: URLRequestCachePolicy.RETURN_CACHE_DATA_ELSE_LOAD,
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
    );

    await headlessWebView?.run();
  }

  /// Settings shared by every warm instance. Cache-first so the 2nd+ launch
  /// skips re-downloading the immutable chart bundle.
  @protected
  InAppWebViewSettings get warmSettings => InAppWebViewSettings(
        javaScriptEnabled: true,
        transparentBackground: true,
        cacheEnabled: true,
        cacheMode: CacheMode.LOAD_CACHE_ELSE_NETWORK,
        domStorageEnabled: true,
        databaseEnabled: true,
        allowsInlineMediaPlayback: true,
        mediaPlaybackRequiresUserGesture: false,
        supportZoom: false,
      );

  /// Tears the warm instance down and resets the warmer so a later [warmUp]
  /// builds a fresh one. Used to release memory when the warmed screen is no
  /// longer reachable (tab left, logout, memory pressure).
  void disposeWarm() {
    if (headlessWebView == null) return;
    headlessWebView?.dispose();
    headlessWebView = null;
    isReady = false;
    _claimed = false;
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
    const canvasSize = '''
      (function() {
        var c = document.querySelector('canvas');
        if (!c || !(c.width > 0 && c.height > 0)) return '';
        return c.width + 'x' + c.height;
      })();
    ''';
    var last = '';
    var stable = 0;
    var polls = 0;
    var resizes = 0;
    for (var attempt = 0; attempt < 100; attempt++) {
      // The instance can be torn down mid-poll (tab left, memory pressure).
      if (headlessWebView == null) return;
      polls++;
      String size = '';
      try {
        final res = await controller.evaluateJavascript(source: canvasSize);
        if (res is String) size = res;
      } catch (_) {
        // Controller can momentarily reject eval during boot — keep polling.
      }
      if (size.isNotEmpty && size == last) {
        if (++stable >= 4) break;
      } else {
        // Each distinct canvas size is one re-layout of the charting library —
        // this counter is the measurable proxy for the visible "flicker".
        if (size.isNotEmpty) {
          resizes++;
          trace('headless canvas resize #$resizes: "$last" -> "$size"');
        }
        stable = 0;
        last = size;
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
