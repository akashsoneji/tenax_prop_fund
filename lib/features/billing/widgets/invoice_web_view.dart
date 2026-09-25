import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../certificates/widgets/certificate_web_view.dart';

/// Renders the invoice HTML from `GET /finance/transactions/{id}/invoice`.
///
/// Unlike the landscape certificate, the invoice is a responsive portrait page
/// (`max-width: 720px` + `width=device-width`), so its own viewport is kept
/// and it reflows to the phone. Only the page chrome is tightened: the grey
/// backdrop and 40px outer padding are dropped because the app already frames
/// the sheet in a card. Exposes print/capture through the same
/// [CertificateWebActions] contract the certificate viewer uses.
class InvoiceWebView extends StatefulWidget {
  const InvoiceWebView({super.key, required this.html, required this.onReady});

  final String html;
  final ValueChanged<CertificateWebActions> onReady;

  @override
  State<InvoiceWebView> createState() => _InvoiceWebViewState();
}

class _InvoiceWebViewState extends State<InvoiceWebView> {
  InAppWebViewController? _controller;

  static const _overrideStyle = '<style>'
      'body{background:#fff !important;padding:0 !important}'
      '.sheet{border:0 !important;border-radius:0 !important}'
      '.head,.body,.foot{padding-left:16px !important;'
      'padding-right:16px !important}'
      '</style>';

  /// Injected in the markup (not via JS) so the first paint is already right.
  String get _preparedHtml {
    final html = widget.html;
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
        javaScriptEnabled: false,
        supportZoom: true,
        builtInZoomControls: true,
        displayZoomControls: false,
        transparentBackground: false,
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

  Future<Uint8List?> _capture() =>
      _controller?.takeScreenshot(
        screenshotConfiguration: ScreenshotConfiguration(
          compressFormat: CompressFormat.PNG,
        ),
      ) ??
      Future.value();
}
