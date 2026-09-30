import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Full-screen in-app WebView used by the force-update dialog when the backend
/// returns a non-APK update link (Play Store page, iOS App Store page, or a
/// hosted release notes page). Mirrors white_label's `WebViewScreen` — the
/// user stays inside the app instead of being bounced out to the browser.
class UpdateWebViewScreen extends StatefulWidget {
  const UpdateWebViewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  @override
  State<UpdateWebViewScreen> createState() => _UpdateWebViewScreenState();
}

class _UpdateWebViewScreenState extends State<UpdateWebViewScreen> {
  InAppWebViewController? _controller;
  bool _isLoading = true;
  int _progress = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
          onPressed: () => Get.back<void>(),
        ),
        title: Text(
          widget.title,
          style: textTheme.titleMedium?.copyWith(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: scheme.onSurface),
            onPressed: () => _controller?.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              supportZoom: true,
              useHybridComposition: true,
              transparentBackground: true,
              mediaPlaybackRequiresUserGesture: false,
            ),
            onWebViewCreated: (c) => _controller = c,
            onLoadStart: (_, _) {
              if (mounted) setState(() => _isLoading = true);
            },
            onLoadStop: (_, _) {
              if (mounted) setState(() => _isLoading = false);
            },
            onProgressChanged: (_, p) {
              if (mounted) setState(() => _progress = p);
            },
          ),
          if (_isLoading && _progress < 100)
            LinearProgressIndicator(
              value: _progress == 0 ? null : _progress / 100.0,
              minHeight: 2.h,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
        ],
      ),
    );
  }
}
