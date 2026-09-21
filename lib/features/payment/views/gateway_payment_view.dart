import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/app_loader.dart';

/// Hosted-gateway checkout. Opens the `gateway_url` returned by
/// `POST /challenges/purchase` (path `gateway`) inside an in-app webview so the
/// user completes payment without leaving the app, then returns via the app bar
/// back button.
class GatewayPaymentView extends StatefulWidget {
  const GatewayPaymentView({super.key});

  @override
  State<GatewayPaymentView> createState() => _GatewayPaymentViewState();
}

class _GatewayPaymentViewState extends State<GatewayPaymentView> {
  bool _isLoading = true;

  String get _url {
    final args = Get.arguments;
    if (args is Map && args['url'] is String) return args['url'] as String;
    if (args is String) return args;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = _url;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: scheme.onSurface, size: 24.w),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'payment.title'.tr,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: url.isEmpty
          ? Center(
              child: Text(
                'state.error'.tr,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          : Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(url)),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    useOnDownloadStart: true,
                    domStorageEnabled: true,
                    databaseEnabled: true,
                  ),
                  onLoadStart: (controller, uri) {
                    if (mounted) setState(() => _isLoading = true);
                  },
                  onLoadStop: (controller, uri) {
                    if (mounted) setState(() => _isLoading = false);
                  },
                  onReceivedError: (controller, request, error) {
                    if (mounted && request.isForMainFrame == true) {
                      setState(() => _isLoading = false);
                    }
                  },
                ),
                if (_isLoading)
                  Container(
                    color: scheme.surface,
                    child: AppLoader(label: 'state.loading'.tr),
                  ),
              ],
            ),
    );
  }
}
