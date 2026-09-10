import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/app_loader.dart';
import '../services/chart_preload_service.dart';

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
  });

  final String url;
  final String symbol;
  final VoidCallback? onReady;

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
    if (Get.isRegistered<ChartPreloadService>()) {
      final service = Get.find<ChartPreloadService>();
      _headlessWebView = service.headlessWebView;
      if (service.isReady) _isLoading = false;
      warmSymbol = service.currentSymbol;
    }
    // A warm instance already shows the preloaded (last-viewed) symbol; a cold
    // fallback loads whatever symbol was requested.
    _loadedSymbol =
        _headlessWebView != null ? (warmSymbol ?? widget.symbol) : widget.symbol;
    _pendingSymbol =
        widget.symbol != _loadedSymbol ? widget.symbol : null;
    _startLoadingTimeout();
  }

  @override
  void didUpdateWidget(covariant ChartInAppWebView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.url != widget.url) {
      if (mounted) {
        setState(() {
          _isReady = false;
          _isLoading = true;
          _hasError = false;
        });
      }
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
    unawaited(updateSymbol(symbolToApply).then((success) {
      if (success) {
        _loadedSymbol = symbolToApply;
        _pendingSymbol = null;
        _retryCount = 0;
        return;
      }
      _retryCount++;
      if (_retryCount >= 3) {
        _loadedSymbol = symbolToApply;
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

  /// Builds the chart URL for [symbol] by REPLACING the `symbol` query param on
  /// the base URL (never appending — appending produced the malformed
  /// `?symbol=..&symbol=..` URL that showed "no data").
  String _urlForSymbol(String symbol) {
    final base = Uri.parse(widget.url);
    final query = Map<String, String>.from(base.queryParameters)
      ..['symbol'] = symbol;
    return base.replace(queryParameters: query).toString();
  }

  /// When attaching a pre-warmed headless instance, [onLoadStop] does not fire
  /// again, so poll the load progress for a short window and flip to ready as
  /// soon as the page is complete. Falls through to the loading timeout if the
  /// instance was not actually pre-loaded.
  Future<void> _markReadyIfLoaded() async {
    for (var attempt = 0; attempt < 20; attempt++) {
      if (!mounted || _controller == null || _isReady) return;
      final progress = await _controller!.getProgress();
      if (progress == 100) {
        await _revealWhenPainted();
        return;
      }
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  /// Keeps the loader up until the TradingView chart CANVAS is actually painted,
  /// not merely until the HTML finished. The charting library boots in several
  /// stages (shell → library init → saved-state restore → datafeed redraw); if
  /// we reveal on HTML-load the user watches those stages happen and it looks
  /// like the chart refreshes 3-4 times. Polling for a sized <canvas> hides all
  /// of that under the loader so the chart appears once, already drawn.
  Future<void> _revealWhenPainted() async {
    const canvasCheck = '''
      (function() {
        var c = document.querySelector('canvas');
        return !!(c && c.width > 0 && c.height > 0);
      })();
    ''';
    for (var attempt = 0; attempt < 60; attempt++) {
      if (!mounted || _controller == null || _isReady) return;
      final painted = await _controller!.evaluateJavascript(source: canvasCheck);
      if (painted == true) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted || _isReady) return;
    _loadingTimeout?.cancel();
    setState(() {
      _isLoading = false;
      _hasError = false;
      _isReady = true;
    });
    widget.onReady?.call();
    _applyPendingSymbol();
  }

  Future<void> _retry() async {
    if (_controller == null) return;
    setState(() {
      _hasError = false;
      _isLoading = true;
      _isReady = false;
    });
    _startLoadingTimeout();
    final retryUrl =
        widget.symbol.isNotEmpty ? _urlForSymbol(widget.symbol) : widget.url;
    await _controller!.loadUrl(urlRequest: URLRequest(url: WebUri(retryUrl)));
  }

  InAppWebViewSettings get _fallbackSettings => InAppWebViewSettings(
        javaScriptEnabled: true,
        transparentBackground: true,
        cacheEnabled: true,
        cacheMode: CacheMode.LOAD_DEFAULT,
        domStorageEnabled: true,
      );

  URLRequest get _fallbackRequest {
    final url =
        widget.symbol.isNotEmpty ? _urlForSymbol(widget.symbol) : widget.url;
    return URLRequest(url: WebUri(url));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.expand(
      child: Stack(
        children: [
          InAppWebView(
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
              if (kDebugMode) debugPrint('[Chart] onLoadStart -> $url');
              if (!mounted || _isReady) return;
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            },
            onLoadStop: (controller, url) {
              if (kDebugMode) debugPrint('[Chart] onLoadStop  -> $url');
              if (!mounted) return;
              // Keep the loader up until the chart canvas is actually painted so
              // the library's multi-stage boot stays hidden (no visible refresh).
              _loadedSymbol = widget.symbol;
              if (_pendingSymbol == widget.symbol) _pendingSymbol = null;
              unawaited(_revealWhenPainted());
            },
            onReceivedError: (controller, request, error) {
              if (!mounted) return;
              if (request.isForMainFrame == true) {
                setState(() {
                  _hasError = true;
                  _isLoading = false;
                  _isReady = false;
                });
              }
            },
            // The charting library emits noisy INFO/WARNING console messages
            // (e.g. "state ... does not match a schema"). Swallow everything
            // below ERROR so the debug panel is not flooded; surface only
            // genuine JS errors when debugging.
            onConsoleMessage: (controller, consoleMessage) {
              if (kDebugMode &&
                  consoleMessage.messageLevel ==
                      ConsoleMessageLevel.ERROR) {
                debugPrint('[Chart JS] ${consoleMessage.message}');
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
