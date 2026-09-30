import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/app_loader.dart';
import '../services/chart_preload_service.dart';
import '../services/chart_warmer.dart';

/// Optimized embedded chart. On first mount it attaches the pre-warmed
/// [HeadlessInAppWebView] from [ChartPreloadService] (loaded at app boot from
/// the flavor's remote chart URL), so the chart paints almost instantly. Symbol
/// changes are applied via JS injection (no full reload) using the chart page's
/// `window.__changeSymbol` / `__setSymbol` / `setSymbol` hooks; a full URL
/// reload is only a last resort.
class ChartInAppWebView extends StatefulWidget {
  const ChartInAppWebView({
    super.key,
    required this.url,
    required this.symbol,
    this.onReady,
    this.warmer,
  });

  final String url;
  final String symbol;
  final VoidCallback? onReady;

  /// Warm instance pool to attach from. Defaults to the portrait
  /// [ChartPreloadService]; the landscape split view passes its own warmer,
  /// which is sized for the landscape viewport (see [ChartWarmer]).
  final ChartWarmer? warmer;

  @override
  State<ChartInAppWebView> createState() => _ChartInAppWebViewState();
}

class _ChartInAppWebViewState extends State<ChartInAppWebView> {
  InAppWebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isReady = false;
  Timer? _loadingTimeout;

  String? _pendingSymbol;
  Timer? _pendingSymbolTimer;
  int _retryCount = 0;

  HeadlessInAppWebView? _headlessWebView;

  /// True when the preload service reported a painted canvas at attach time, so
  /// the attached instance can reveal on the first poll instead of waiting.
  bool _warmAlreadyPainted = false;

  /// Bumped whenever the platform webview must be torn down and rebuilt from
  /// scratch (renderer process killed by the OS) — forces Flutter to discard
  /// the old `InAppWebView` element instead of diffing onto a dead one.
  int _webviewGeneration = 0;

  /// Wall clock from mount, so every trace line shows where the seconds go.
  final Stopwatch _clock = Stopwatch()..start();

  /// Counts canvas re-layouts observed while the loader is up. Each one is a
  /// redraw the user would have seen as a "flicker" had the chart been visible.
  int _canvasResizes = 0;

  /// Counts chart-library boot messages (`onReady` …) seen on the JS console.
  /// More than one of these AFTER reveal means the page is re-creating the chart
  /// widget — that is a genuine visible flicker, not just a boot redraw.
  int _chartInits = 0;

  /// When the chart library last (re)built its widget. Reveal waits for a quiet
  /// window after this, so the library's repeated boots happen UNDER the loader
  /// instead of on screen as 2-3 flickers.
  DateTime? _lastChartInitAt;

  void _trace(String message) {
    if (!kDebugMode) return;
    debugPrint('[Chart] +${_clock.elapsedMilliseconds}ms $message');
  }

  /// Warm-instance pool this webview attaches from: the one the caller injected
  /// (landscape passes its own, sized for that viewport), else the app-wide
  /// portrait [ChartPreloadService], else null when neither is registered.
  ChartWarmer? get _warmer {
    final injected = widget.warmer;
    if (injected != null) return injected;
    if (Get.isRegistered<ChartPreloadService>()) {
      return Get.find<ChartPreloadService>();
    }
    return null;
  }

  /// The symbol currently displayed by the webview. When we attach the warm
  /// headless instance it is already showing the preloaded default symbol, so
  /// we start from that — this prevents a needless JS switch / reload on first
  /// open (the bug that made the first load cold and produced a double-`symbol`
  /// URL).
  late String _loadedSymbol;

  @override
  void initState() {
    super.initState();
    // Attach the pre-warmed headless webview if it exists.
    String? warmSymbol;
    final service = _warmer;
    if (service != null) {
      // Only ONE on-screen webview can host the warm instance; a second screen
      // gets null here and loads its own from cache.
      _headlessWebView = service.claim();
      if (_headlessWebView != null && service.isReady) {
        // Preload already settled the headless canvas, so we can reveal on the
        // first check instead of re-polling. NOTE: we deliberately keep the
        // loader UP (do NOT clear _isLoading here) — attaching the headless
        // instance to the screen makes the remote chart SPA re-layout/re-render
        // once, and revealing before that settles is what looks like a fast
        // flicker. _revealWhenPainted clears the loader after the settle wait.
        _warmAlreadyPainted = true;
      }
      warmSymbol = service.shownSymbol;
      _trace('initState warm=${_headlessWebView != null} '
          'preloadReady=${service.isReady} warmupMs=${service.warmupMs} '
          'warmSymbol=$warmSymbol requested=${widget.symbol}');
    } else {
      _trace('initState NO preload service — cold load ${widget.symbol}');
    }
    // A warm instance already shows the preloaded (last-viewed) symbol; a cold
    // fallback loads whatever symbol was requested.
    _loadedSymbol =
        _headlessWebView != null ? (warmSymbol ?? widget.symbol) : widget.symbol;
    _pendingSymbol =
        widget.symbol != _loadedSymbol ? widget.symbol : null;
    if (_pendingSymbol != null) {
      _trace('pending symbol switch on first mount: '
          '$_loadedSymbol -> $_pendingSymbol (costs an extra redraw)');
    }
    _startLoadingTimeout();
  }

  @override
  void didUpdateWidget(covariant ChartInAppWebView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // A URL that differs ONLY by the `symbol` param is a symbol switch, not a
    // different chart page — handle it via the fast in-place JS path below.
    if (_differsBeyondSymbol(oldWidget.url, widget.url)) {
      if (mounted) {
        setState(() {
          _isReady = false;
          _isLoading = true;
          _hasError = false;
        });
      }
      _trace('FULL RELOAD (url changed beyond symbol): ${widget.url}');
      _pendingSymbol = widget.symbol;
      _retryCount = 0;
      _startLoadingTimeout();
      _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(widget.url)));
      return;
    }

    if (widget.symbol != _loadedSymbol) {
      _pendingSymbol = widget.symbol;
      _retryCount = 0;
      if (_isReady) _applyPendingSymbol();
    }
  }

  @override
  void dispose() {
    _loadingTimeout?.cancel();
    _pendingSymbolTimer?.cancel();
    // Intentionally NOT disposing the headless webview — it is owned by
    // ChartPreloadService and kept warm for the next open.
    if (_headlessWebView != null) _warmer?.release();
    super.dispose();
  }

  void _startLoadingTimeout() {
    _loadingTimeout?.cancel();
    _loadingTimeout = Timer(const Duration(seconds: 15), () {
      if (!mounted || _isReady) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    });
  }

  void _applyPendingSymbol() {
    _pendingSymbolTimer?.cancel();
    if (_pendingSymbol == null || !_isReady || _controller == null) return;

    final symbolToApply = _pendingSymbol!;
    _trace('applying symbol $_loadedSymbol -> $symbolToApply via JS');
    unawaited(updateSymbol(symbolToApply).then((success) {
      if (success) {
        _trace('symbol switch ok -> $symbolToApply');
        _loadedSymbol = symbolToApply;
        if (_headlessWebView != null) _warmer?.noteShownSymbol(symbolToApply);
        _pendingSymbol = null;
        _retryCount = 0;
        return;
      }
      _retryCount++;
      _trace('symbol switch MISS (retry $_retryCount) -> $symbolToApply');
      if (_retryCount >= 3) {
        _trace('JS switch gave up — hard reloading URL for $symbolToApply');
        _loadedSymbol = symbolToApply;
        if (_headlessWebView != null) _warmer?.noteShownSymbol(symbolToApply);
        _controller?.loadUrl(
          urlRequest: URLRequest(url: WebUri(_urlForSymbol(symbolToApply))),
        );
        _pendingSymbol = null;
        _retryCount = 0;
        return;
      }
      _pendingSymbolTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted && _pendingSymbol == symbolToApply) _applyPendingSymbol();
      });
    }));
  }

  Future<bool> updateSymbol(String symbol) async {
    if (_controller == null || symbol.isEmpty) return false;
    if (!_isReady) {
      _pendingSymbol = symbol;
      return false;
    }

    final sym = symbol;
    final symClean =
        sym.contains('.') ? sym.substring(0, sym.lastIndexOf('.')) : sym;

    try {
      var res = await _controller!.evaluateJavascript(source: _jsSource(sym));
      if (res == 'ok') return true;

      res = await _controller!.evaluateJavascript(source: _jsSource(symClean));
      if (res == 'ok') return true;

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted || _controller == null) return false;

      res = await _controller!.evaluateJavascript(source: _jsSource(sym));
      if (res == 'ok') return true;
      res = await _controller!.evaluateJavascript(source: _jsSource(symClean));
      return res == 'ok';
    } catch (_) {
      return false;
    }
  }

  String _jsSource(String s) => '''
    (function() {
      var sym = ${_jsStr(s)};
      function trySet(t) {
        try { if (typeof selectedSymbol!=='undefined') selectedSymbol=t; } catch(e) {}
        try {
          if (typeof window.__changeSymbol==='function') {
            var res = window.__changeSymbol(t);
            if (res === true || res === undefined) return true;
          }
        } catch(e) {}
        try {
          if (typeof window.__setSymbol==='function') {
            var res = window.__setSymbol(t);
            if (res === true || res === undefined) return true;
          }
        } catch(e) {}
        for (var prop in window) {
          try {
            if (prop !== 'webkit' && window[prop] && typeof window[prop].setSymbol === 'function') {
              window[prop].setSymbol(t, "5", function(){});
              return true;
            }
          } catch(e) {}
        }
        try { if (typeof updateSymbol==='function') { updateSymbol(t); return true; } } catch(e) {}
        try { if (typeof createTradingViewChart==='function') { createTradingViewChart(t); return true; } } catch(e) {}
        return false;
      }
      if (trySet(sym)) return 'ok';
      return 'miss';
    })();
  ''';

  static String _jsStr(String s) => '"${s.replaceAll('"', r'\"')}"';

  /// True when [a] and [b] point at genuinely different chart pages, i.e. they
  /// differ in something other than the `symbol` query param.
  static bool _differsBeyondSymbol(String a, String b) {
    if (a == b) return false;
    final ua = Uri.parse(a);
    final ub = Uri.parse(b);
    if (ua.scheme != ub.scheme || ua.host != ub.host || ua.port != ub.port) {
      return true;
    }
    if (ua.path != ub.path) return true;
    final qa = Map<String, String>.from(ua.queryParameters)..remove('symbol');
    final qb = Map<String, String>.from(ub.queryParameters)..remove('symbol');
    return !mapEquals(qa, qb);
  }

  /// Builds the chart URL for [symbol] by REPLACING the `symbol` query param on
  /// the base URL (never appending — appending produced the malformed
  /// `?symbol=..&symbol=..` URL that showed "no data").
  String _urlForSymbol(String symbol) {
    final base = Uri.parse(widget.url);
    final query = Map<String, String>.from(base.queryParameters)
      ..['symbol'] = symbol;
    return base.replace(queryParameters: query).toString();
  }

  /// Tells the chart page its viewport just changed. A warm instance is loaded
  /// off screen at ONE size (e.g. portrait), so attaching it somewhere else
  /// (e.g. the landscape split view) changes the native view's size without
  /// the charting library ever finding out — canvases are pixel buffers, they
  /// do not repaint themselves just because their container resized. Without
  /// this the chart shows the stale (wrong-size/blank) frame from its warm-up
  /// until something else forces a redraw — which is why switching the symbol
  /// "fixed" it: that path recreates the chart, incidentally at the new size.
  Future<void> _notifyViewportChanged() async {
    if (_controller == null) return;
    try {
      await _controller!.evaluateJavascript(source: '''
        (function() {
          window.dispatchEvent(new Event('resize'));
          if (window.visualViewport) {
            window.visualViewport.dispatchEvent(new Event('resize'));
          }
        })();
      ''');
    } catch (_) {
      // Best effort — a page with no resize listener just keeps its old frame,
      // which is what would have happened anyway.
    }
  }

  /// When attaching a pre-warmed headless instance, [onLoadStop] does not fire
  /// again, so poll the load progress for a short window and flip to ready as
  /// soon as the page is complete. Falls through to the loading timeout if the
  /// instance was not actually pre-loaded.
  Future<void> _markReadyIfLoaded() async {
    // The preload already confirmed a painted canvas — reveal immediately.
    if (_warmAlreadyPainted) {
      // Give the platform view one layout pass to actually resize before
      // nudging the page, then reveal once the resulting redraw settles.
      await WidgetsBinding.instance.endOfFrame;
      await _notifyViewportChanged();
      await _revealWhenPainted();
      return;
    }
    // A warm instance was ATTACHED here even though preload had not yet
    // confirmed a painted canvas — it may still need the same viewport nudge
    // once it does finish loading at whatever size it now has.
    var nudged = false;
    for (var attempt = 0; attempt < 20; attempt++) {
      if (!mounted || _controller == null || _isReady) return;
      final progress = await _controller!.getProgress();
      if (progress == 100) {
        if (_headlessWebView != null && !nudged) {
          nudged = true;
          await _notifyViewportChanged();
        }
        await _revealWhenPainted();
        return;
      }
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  /// Reveals the chart once the page has loaded. It first makes a BEST-EFFORT
  /// wait for the canvas to settle (so the library's multi-stage boot —
  /// shell → init → state restore → datafeed redraw — stays hidden and the
  /// chart does not appear to refresh 2-3 times), but it ALWAYS reveals
  /// afterwards. The canvas probe must never gate the reveal: some chart builds
  /// render into an element the probe can't measure, and gating on it there
  /// left the loader up until the 15s timeout ("Chart unavailable").
  Future<void> _revealWhenPainted() async {
    _trace('reveal start (warmAlreadyPainted=$_warmAlreadyPainted)');
    // A warm attach never replays the boot `onReady`s on THIS widget, so the
    // quiet-window wait below returned instantly and the re-init triggered by
    // the attach/viewport resize played out on screen as 2-3 refreshes. Start
    // the quiet window now so any rebuild after this keeps the loader up.
    _lastChartInitAt = DateTime.now();
    // The remote chart SPA re-renders a couple of times right after load (shell
    // → library → datafeed redraw). Canvas SIZE stabilises before that content
    // re-render finishes, so a size probe alone reveals too early and the user
    // sees a quick flicker. Hold the loader for a short floor so those redraws
    // happen underneath it, then reveal once.
    final settle = Future<void>.delayed(const Duration(milliseconds: 700));
    await _waitForStableCanvas(_controller);
    await settle;
    // The page rebuilds the chart widget several times during boot (each one is
    // an `onReady` on the JS console). Revealing between two of those rebuilds
    // is exactly what the user sees as 2-3 flickers, so hold the loader until no
    // new rebuild has been reported for a quiet window.
    await _waitForChartInitsToSettle();
    if (!mounted || _isReady) return;
    _loadingTimeout?.cancel();
    setState(() {
      _isLoading = false;
      _hasError = false;
      _isReady = true;
    });
    _trace('REVEALED canvasResizes=$_canvasResizes chartInits=$_chartInits '
        'symbol=$_loadedSymbol — any redraw logged after this line is a '
        'user-visible flicker');
    widget.onReady?.call();
    _applyPendingSymbol();
  }

  /// Best-effort wait for the chart canvas to settle: returns as soon as its
  /// size stays the SAME across [_stableTicksNeeded] consecutive polls, or after
  /// [_stableMaxTicks] polls, whichever comes first. This ONLY hides the boot
  /// flicker — the caller reveals regardless of the outcome, so a chart the
  /// probe can't measure still shows promptly instead of hanging.
  Future<void> _waitForStableCanvas(InAppWebViewController? controller) async {
    if (controller == null) return;
    var last = '';
    var stable = 0;
    for (var attempt = 0; attempt < _stableMaxTicks; attempt++) {
      if (!mounted || _isReady) return;
      String probe = '';
      try {
        final res = await controller.evaluateJavascript(source: paintProbeJs);
        if (res is String) probe = res;
      } catch (_) {
        // Eval can be rejected mid-boot — treat as not-yet-stable.
      }
      if (probe.isNotEmpty && probe == last) {
        if (++stable >= _stableTicksNeeded) {
          _trace('canvas stable at "$probe" after ${attempt + 1} polls');
          return;
        }
      } else {
        if (probe.isNotEmpty) {
          _canvasResizes++;
          _trace('canvas change #$_canvasResizes: "$last" -> "$probe"');
        }
        stable = 0;
        last = probe;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Holds until the chart library has stopped rebuilding itself: returns once
  /// [_quietAfterInit] has passed with no new `onReady`, or after
  /// [_initSettleMaxWait] regardless, so a page that keeps re-initialising
  /// forever still reveals instead of sitting behind the loader.
  Future<void> _waitForChartInitsToSettle() async {
    final deadline = DateTime.now().add(_initSettleMaxWait);
    while (mounted && !_isReady && DateTime.now().isBefore(deadline)) {
      final last = _lastChartInitAt;
      if (last == null || DateTime.now().difference(last) >= _quietAfterInit) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _trace('chart inits never went quiet — revealing anyway '
        '(chartInits=$_chartInits)');
  }

  /// Quiet window with no chart rebuild that counts as "boot finished".
  static const _quietAfterInit = Duration(milliseconds: 1200);

  /// Hard cap on [_waitForChartInitsToSettle] so reveal is never blocked.
  static const _initSettleMaxWait = Duration(seconds: 6);

  /// Consecutive equal-size polls (×100ms) that mark the canvas "settled".
  static const _stableTicksNeeded = 4;

  /// Hard cap on the settle wait (×100ms) so reveal is never delayed beyond it.
  static const _stableMaxTicks = 25;

  Future<void> _retry() async {
    setState(() {
      _hasError = false;
      _isLoading = true;
      _isReady = false;
    });
    _startLoadingTimeout();
    // A render-process crash already tore down the controller — rebuild the
    // InAppWebView from a cold URL via the widget key instead of calling into
    // a dead controller.
    if (_controller == null) return;
    final retryUrl =
        widget.symbol.isNotEmpty ? _urlForSymbol(widget.symbol) : widget.url;
    await _controller!.loadUrl(urlRequest: URLRequest(url: WebUri(retryUrl)));
  }

  InAppWebViewSettings get _fallbackSettings => InAppWebViewSettings(
        javaScriptEnabled: true,
        transparentBackground: true,
        cacheEnabled: true,
        // Cache-first so a cold open (no preload) still loads the shell + JS
        // bundle from disk on the 2nd+ launch instead of re-downloading it.
        // Honour the server's cache headers — see ChartWarmer.warmSettings.
        cacheMode: CacheMode.LOAD_DEFAULT,
        domStorageEnabled: true,
        databaseEnabled: true,
        // Without this the native webview layer composites ABOVE Flutter's
        // Stack on Android (Virtual Display mode) instead of blending into it:
        // overlay widgets like the fullscreen button silently disappear behind
        // it, and every internal repaint of the page can flash through as a
        // visible flicker.
        useHybridComposition: false,
      );

  URLRequest get _fallbackRequest {
    final url =
        widget.symbol.isNotEmpty ? _urlForSymbol(widget.symbol) : widget.url;
    return URLRequest(
      url: WebUri(url),
      cachePolicy: URLRequestCachePolicy.RETURN_CACHE_DATA_ELSE_LOAD,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.expand(
      child: Stack(
        children: [
          InAppWebView(
            key: ValueKey(_webviewGeneration),
            // Ties the native platform view's lifetime to the WARMER, not to
            // this widget. Without it, disposing this widget (leaving the tab,
            // popping the landscape route) destroys the native webview even
            // though the Dart-side HeadlessInAppWebView object survives — so
            // the next attach looked "warm" but was actually a cold reload.
            keepAlive: _warmer?.keepAlive,
            // Attaching the pre-warmed instance overrides initialUrlRequest /
            // initialSettings; those are only used for the cold fallback.
            headlessWebView: _headlessWebView,
            initialUrlRequest:
                _headlessWebView == null ? _fallbackRequest : null,
            initialSettings:
                _headlessWebView == null ? _fallbackSettings : null,
            onWebViewCreated: (controller) async {
              _controller = controller;
              // A pre-warmed instance is usually already loaded, but onLoadStop
              // does NOT fire again on attach — so poll readiness briefly and
              // flip to ready as soon as the DOM is complete.
              await _markReadyIfLoaded();
            },
            onLoadStart: (controller, url) {
              _trace('onLoadStart -> $url');
              if (!mounted || _isReady) return;
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            },
            onLoadStop: (controller, url) {
              _trace('onLoadStop -> $url');
              if (!mounted) return;
              // Keep the loader up until the chart canvas is actually painted so
              // the library's multi-stage boot stays hidden (no visible refresh).
              // Trust the URL that actually loaded: a warm/headless instance can
              // finish on a DIFFERENT symbol than the one requested, and blindly
              // recording widget.symbol here dropped the pending switch and left
              // the chart showing the previous symbol.
              final loaded = url?.queryParameters['symbol'];
              _loadedSymbol =
                  (loaded != null && loaded.isNotEmpty) ? loaded : widget.symbol;
              if (_pendingSymbol == _loadedSymbol) _pendingSymbol = null;
              unawaited(_revealWhenPainted());
            },
            onReceivedError: (controller, request, error) {
              if (kDebugMode) {
                debugPrint('[Chart] onReceivedError mainFrame='
                    '${request.isForMainFrame} url=${request.url} '
                    'type=${error.type} desc=${error.description}');
              }
              if (!mounted) return;
              if (request.isForMainFrame == true) {
                setState(() {
                  _hasError = true;
                  _isLoading = false;
                  _isReady = false;
                });
              }
            },
            onReceivedHttpError: (controller, request, response) {
              if (kDebugMode) {
                debugPrint('[Chart] onReceivedHttpError mainFrame='
                    '${request.isForMainFrame} url=${request.url} '
                    'status=${response.statusCode}');
              }
            },
            // Low-RAM devices let Android's OOM killer take the WebView
            // renderer process under memory pressure — without this the
            // screen just stays on whatever frame it last painted forever.
            // Show the retry state instead so the user can recover in place.
            onRenderProcessGone: (controller, detail) {
              _trace('onRenderProcessGone didCrash=${detail.didCrash}');
              if (_headlessWebView != null) _warmer?.disposeWarm();
              _headlessWebView = null;
              _controller = null;
              if (!mounted) return;
              setState(() {
                _hasError = true;
                _isLoading = false;
                _isReady = false;
                _webviewGeneration++;
              });
            },
            // The charting library emits noisy INFO/WARNING console messages
            // (e.g. "state ... does not match a schema"). Swallow everything
            // below ERROR so the debug panel is not flooded; surface only
            // genuine JS errors when debugging.
            onConsoleMessage: (controller, consoleMessage) {
              final msg = consoleMessage.message;
              // `onReady` is emitted once per chart-widget construction, so its
              // count is the number of times the page built the chart. >1 after
              // reveal == the visible multi-flicker.
              if (msg.contains('onReady')) {
                _chartInits++;
                _lastChartInitAt = DateTime.now();
                _trace('chart init #$_chartInits '
                    '(afterReveal=$_isReady) — each one repaints the chart');
                return;
              }
              if (kDebugMode &&
                  consoleMessage.messageLevel == ConsoleMessageLevel.ERROR) {
                debugPrint('[Chart JS] $msg');
              }
            },
          ),
          if (_isLoading)
            Container(
              color: scheme.surface,
              child: AppLoader(label: 'chart.loading'.tr),
            ),
          if (_hasError)
            Container(
              color: scheme.surface,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48.w, color: scheme.onSurfaceVariant),
                    SizedBox(height: 12.h),
                    Text('chart.unavailable'.tr,
                        style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 12.h),
                    OutlinedButton(
                      onPressed: _retry,
                      child: Text('state.retry'.tr),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
