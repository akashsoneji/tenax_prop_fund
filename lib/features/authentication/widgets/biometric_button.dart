import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';

import '../../../app/flavor/flavor_resolver.dart';

/// Round button that triggers a biometric prompt and returns the
/// authenticated email (or null if cancelled). The caller decides what to do
/// with that — typically route to dashboard via AuthController.
class BiometricButton extends StatefulWidget {
  const BiometricButton({
    super.key,
    required this.savedEmail,
    required this.onAuthenticated,
  });

  /// Email we last logged in with — passed to the backend after biometric
  /// success (no password re-entry required).
  final String? savedEmail;

  /// Called with the saved email on successful biometric authentication.
  final ValueChanged<String> onAuthenticated;

  @override
  State<BiometricButton> createState() => _BiometricButtonState();
}

class _BiometricButtonState extends State<BiometricButton> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _available = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!mounted) return;
      setState(() => _available = supported && canCheck);
    } catch (_) {
      if (!mounted) return;
      setState(() => _available = false);
    }
  }

  Future<void> _trigger() async {
    if (_busy || !_available || widget.savedEmail == null) return;
    setState(() => _busy = true);
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'login.biometric_reason'.trParams({
          'app': FlavorResolver.appName,
        }),
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (ok) widget.onAuthenticated(widget.savedEmail!);
    } catch (_) {
      // Swallow — user sees no biometric option if the device rejects.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_available || widget.savedEmail == null) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _trigger,
        child: SizedBox(
          width: 56.w,
          height: 56.h,
          child: _busy
              ? Padding(
                  padding: EdgeInsets.all(16.w),
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.fingerprint_rounded,
                  size: 28.w,
                  color: scheme.primary,
                ),
        ),
      ),
    );
  }
}
