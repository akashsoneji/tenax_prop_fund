import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// What the viewer can do with the loaded document, handed up once the WebView
/// exists so the controller never holds a widget reference.
class CertificateWebActions {
  const CertificateWebActions({required this.print, required this.capture});

  /// Opens the OS print sheet ("Save as PDF" / "Save to Files").
  final Future<void> Function() print;

  /// PNG bytes of the rendered certificate, for sharing.
  final Future<Uint8List?> Function() capture;
}

/// Renders a certificate's HTML document in a pinch-zoomable WebView.
///
/// The markup arrives from the API as a complete standalone page, so it is
/// loaded as initial data rather than fetched again over the network. Two
/// things are rewritten before loading: the document's `width=device-width`
/// viewport (which squeezes its 860px-wide landscape sheet into a portrait
/// column on a phone) and its own print/back buttons, which belong to the web
/// portal rather than the app.
class CertificateWebView extends StatefulWidget {
  const CertificateWebView({
    super.key,
    required this.html,
    required this.onReady,
  });

  final String html;
  final ValueChanged<CertificateWebActions> onReady;

  @override
  State<CertificateWebView> createState() => _CertificateWebViewState();
}

class _CertificateWebViewState extends State<CertificateWebView> {
  InAppWebViewController? _controller;

  /// The sheet is `max-width: 860px` plus frame margins; laying the page out at
  /// this width and letting the WebView scale it down keeps the certificate's
  /// designed proportions instead of reflowing it into a tall column.
  static const _documentWidth = 920;

  static const _overrideStyle = '<style>'
      '.actions{display:none !important}'
      'body{background:#fff !important;padding:16px 12px !important}'
      '</style>';

  /// Rewrites the document's viewport + hides its web-only buttons. Done in the
  /// markup rather than via injected JS so the very first layout is already
  /// correct and the user never sees the portrait version flash.
  String get _preparedHtml {
    final html = widget.html.replaceFirst(
      RegExp(r'<meta\s+name="viewport"[^>]*>', caseSensitive: false),
      '<meta name="viewport" content="width=$_documentWidth">',
    );
    return html.contains('</head>')
        ? html.replaceFirst('</head>', '$_overrideStyle</head>')
        : '$_overrideStyle$html';
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialData: InAppWebViewInitialData(
        data: _preparedHtml,
        mimeType: 'text/html',
        encoding: 'utf-8',
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        supportZoom: true,
        builtInZoomControls: true,
        displayZoomControls: false,
        useWideViewPort: true,
        loadWithOverviewMode: true,
        enableViewportScale: true,
        verticalScrollBarEnabled: false,
        horizontalScrollBarEnabled: false,
      ),
      onWebViewCreated: (controller) {
        _controller = controller;
        widget.onReady(
          CertificateWebActions(print: _print, capture: _capture),
        );
      },
    );
  }

  Future<void> _print() async {
    await _controller?.printCurrentPage();
  }

  Future<Uint8List?> _capture() => _controller?.takeScreenshot(
            screenshotConfiguration: ScreenshotConfiguration(
              compressFormat: CompressFormat.PNG,
            ),
          ) ??
      Future.value();
}
