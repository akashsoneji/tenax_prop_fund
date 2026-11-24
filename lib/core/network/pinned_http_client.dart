import 'dart:io';

import 'package:flutter/services.dart';

/// TLS pinning for every REST and WebSocket connection the app opens itself.
///
/// The app trusts ONLY the Let's Encrypt (ISRG) roots bundled in
/// `assets/certs/isrg_roots.pem`, not the device trust store. A proxy CA that
/// someone installs to read or alter traffic (even into the system store on a
/// rooted phone) is therefore rejected.
///
/// If the servers ever move to a different certificate authority, add that
/// CA's root to the PEM file and ship an app update BEFORE switching, or
/// existing installs will fail to connect.
class PinnedHttpClient {
  PinnedHttpClient._();

  static const rootsAsset = 'assets/certs/isrg_roots.pem';

  static SecurityContext? _context;

  /// Loads the bundled roots. Call once before any network client is built.
  static Future<void> init() async {
    final data = await rootBundle.load(rootsAsset);
    initWithPem(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  static void initWithPem(List<int> pemBytes) {
    _context = SecurityContext(withTrustedRoots: false)
      ..setTrustedCertificatesBytes(pemBytes);
  }

  static HttpClient create() {
    final context = _context;
    if (context == null) {
      throw StateError('PinnedHttpClient.init() must run before networking');
    }
    return HttpClient(context: context);
  }
}
