import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logger/app_logger.dart' show log;
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import 'app_status_controller.dart';
import 'in_app_update_service.dart';
import 'update_web_view_screen.dart';
import '../../shared/theme/app_spacing.dart';

enum _State { idle, downloading, installing, error, installBlocked }

/// Full-screen dialog shown when a soft/force update is available.
/// If the backend URL points at a `.apk` the file is downloaded and handed to
/// the OS installer; otherwise it opens the store URL through the controller.
class ForceUpdateDialog extends StatefulWidget {
  const ForceUpdateDialog({super.key, required this.isForceUpdate});

  final bool isForceUpdate;

  @override
  State<ForceUpdateDialog> createState() => _ForceUpdateDialogState();
}

class _ForceUpdateDialogState extends State<ForceUpdateDialog> {
  _State _state = _State.idle;
  double? _progress;
  String? _error;

  Future<void> _handleUpdateTap() async {
    // "Try again" from the install-blocked state — reopen the installer for
    // the APK we already downloaded rather than downloading it again.
    if (_state == _State.installBlocked) {
      await _reopenInstaller();
      return;
    }

    final controller = Get.find<AppStatusController>();
    final data = controller.statusData.value;

    // 1. Pick the URL that matches THIS platform. Android build should never
    //    open an iOS App Store link, and vice versa.
    final url = _urlForCurrentPlatform(data?.updateUrlAndroid, data?.updateUrlIos);

    // 2. Direct APK on Android → download + install in-app (no webview).
    if (Platform.isAndroid &&
        url.isNotEmpty &&
        InAppUpdateService.instance.isApkUrl(url)) {
      await _downloadAndInstallApk(url);
      return;
    }

    // 3. Play Store / App Store link → hand off to the native store app.
    //    Opening these inside a webview is broken (Play blocks its own store
    //    UI in embedded webviews) so an external launch is the right thing.
    if (url.isNotEmpty && _isStoreUrl(url)) {
      await _launchExternal(url);
      return;
    }

    // 4. Plain website (release notes, hosted landing page, direct download
    //    portal) → open inside the app so the user does not lose context.
    if (url.isNotEmpty) {
      await Get.to<void>(
        () => UpdateWebViewScreen(
          url: url,
          title: 'app_status.update_available'.tr,
        ),
      );
      return;
    }

    // 5. Backend gave us nothing → fall back to the platform store guess.
    await controller.openAppStore();
    return;
  }

  /// Picks the update URL for the platform the app is running on. Falls back
  /// to the other platform's URL only when the correct one is empty — that
  /// covers backends that ship a single link for both stores.
  String _urlForCurrentPlatform(String? androidUrl, String? iosUrl) {
    final a = androidUrl?.trim() ?? '';
    final i = iosUrl?.trim() ?? '';
    if (Platform.isIOS) return i.isNotEmpty ? i : a;
    if (Platform.isAndroid) return a.isNotEmpty ? a : i;
    return a.isNotEmpty ? a : i;
  }

  /// True for Google Play / Apple App Store links (any host variant + the
  /// `market://` scheme). Store URLs must be opened by the OS, not embedded.
  bool _isStoreUrl(String url) {
    final lower = url.toLowerCase();
    return lower.startsWith('market://') ||
        lower.startsWith('itms-apps://') ||
        lower.contains('play.google.com/store') ||
        lower.contains('apps.apple.com') ||
        lower.contains('itunes.apple.com');
  }

  Future<void> _launchExternal(String url) async {
    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        log.e('ForceUpdateDialog: launchUrl returned false for $url');
      }
    } catch (e, st) {
      log.e('ForceUpdateDialog: launchUrl failed', error: e, stackTrace: st);
    }
  }

  Future<void> _downloadAndInstallApk(String url) async {
    setState(() {
      _state = _State.downloading;
      _progress = 0.0;
      _error = null;
    });

    final result = await InAppUpdateService.instance.downloadAndInstall(
      url,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );

    if (!mounted) return;
    switch (result) {
      case DownloadResult.success:
        // Installer intent fired. Show a small helper state so the user knows
        // they need to tap "Install" in the OS dialog.
        setState(() {
          _state = _State.installing;
          _progress = 1.0;
        });
        break;
      case DownloadResult.downloadError:
        setState(() {
          _state = _State.error;
          _error = 'app_status.download_failed'.tr;
        });
        break;
      case DownloadResult.installError:
        // Download succeeded, installer refused. On Android this is almost
        // always "Install unknown apps" being off for this app.
        setState(() {
          _state = _State.installBlocked;
          _error = 'app_status.install_blocked_body'.tr;
        });
        break;
    }
  }

  /// Second-attempt installer launch (user taps "Try again" after enabling
  /// "Install unknown apps"). Skips the download and reopens the installer.
  Future<void> _reopenInstaller() async {
    setState(() {
      _state = _State.installing;
      _error = null;
    });
    final result = await InAppUpdateService.instance.reopenInstaller();
    if (!mounted) return;
    if (result == DownloadResult.success) return;
    setState(() {
      _state = _State.installBlocked;
      _error = 'app_status.install_blocked_body'.tr;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppStatusController>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final data = controller.statusData.value;
    final releaseNotes = data?.releaseNotes?.trim() ?? '';
    final latest = data?.appVersion ?? controller.latestVersion.value;
    final androidUrl = data?.updateUrlAndroid ?? '';
    final hasApk = Platform.isAndroid &&
        androidUrl.isNotEmpty &&
        InAppUpdateService.instance.isApkUrl(androidUrl);
    final progressPct =
        ((_progress ?? 0) * 100).clamp(0, 100).toStringAsFixed(0);

    // Landscape / tablet: cap the card width so the icon+title don't stretch
    // edge-to-edge on wide viewports. Portrait phones fall back to the full
    // width minus the horizontal gutter.
    final maxCardWidth =
        MediaQuery.of(context).size.width > 600 ? 440.0 : double.infinity;

    // Reuse the app-wide hero gradient (shades of the flavor primary) so
    // the dialog reads as part of the same brand system as the equity card,
    // payout journey card, and other hero surfaces.
    final gradient = AppTheme.heroGradient(scheme);

    return PopScope(
      canPop: !widget.isForceUpdate,
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxCardWidth),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.5 : 0.15),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // -----------------------------------------------------
                        // Header — gradient wash with the icon + version pill.
                        // -----------------------------------------------------
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 20.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                scheme.primary
                                    .withValues(alpha: isDark ? 0.22 : 0.10),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Column(
                            children: [
                              // Gradient icon with a soft glow behind it.
                              Container(
                                width: 84.w,
                                height: 84.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: gradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.brandPurple
                                          .withValues(alpha: 0.35),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _headerIcon(),
                                  size: 42.w,
                                  color: Colors.white,
                                ),
                              ),
                              14.verticalSpace,
                              _VersionPill(latest: latest),
                            ],
                          ),
                        ),
                        // -----------------------------------------------------
                        // Body — title, subtitle, optional release notes.
                        // -----------------------------------------------------
                        Padding(
                          padding: EdgeInsets.fromLTRB(24.w, 4.h, 24.w, 20.h),
                          child: Column(
                            children: [
                              Text(
                                _titleFor(),
                                textAlign: TextAlign.center,
                                style: textTheme.titleLarge?.copyWith(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              Gap.vSm,
                              Text(
                                _subtitleFor(latest),
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontSize: 14.sp,
                                  color: scheme.onSurfaceVariant,
                                  height: 1.45,
                                ),
                              ),
                              if (_state == _State.downloading) ...[
                                18.verticalSpace,
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'app_status.downloading_title'.tr,
                                      style: textTheme.labelMedium?.copyWith(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      '$progressPct%',
                                      style: textTheme.labelMedium?.copyWith(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.brandPurple,
                                      ),
                                    ),
                                  ],
                                ),
                                Gap.vSm,
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: LinearProgressIndicator(
                                    value: _progress,
                                    minHeight: 8.h,
                                    backgroundColor: scheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      AppColors.brandPurple,
                                    ),
                                  ),
                                ),
                              ],
                              if (releaseNotes.isNotEmpty) ...[
                                20.verticalSpace,
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(14.w),
                                  decoration: BoxDecoration(
                                    color: scheme.surfaceContainerHighest
                                        .withValues(
                                            alpha: isDark ? 0.35 : 0.55),
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.auto_awesome_rounded,
                                            size: 14.w,
                                            color: AppColors.brandPurple,
                                          ),
                                          6.horizontalSpace,
                                          Text(
                                            'app_status.whats_new'.tr,
                                            style: textTheme.labelMedium
                                                ?.copyWith(
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w700,
                                              color: scheme.onSurfaceVariant,
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Gap.vSm,
                                      Text(
                                        releaseNotes,
                                        style: textTheme.bodySmall?.copyWith(
                                          fontSize: 13.sp,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              22.verticalSpace,
                              _CtaButton(
                                label: _ctaLabel(hasApk),
                                icon: _ctaIcon(hasApk),
                                gradient: gradient,
                                isError: _state == _State.error ||
                                    _state == _State.installBlocked,
                                // Only the download step is a blocking wait.
                                // In `installing` the OS dialog is up (or the
                                // user dismissed it) — CTA stays tappable so
                                // they can reopen the installer.
                                loading: _state == _State.downloading,
                                onPressed: _state == _State.downloading
                                    ? null
                                    : (_state == _State.installing
                                        ? _reopenInstaller
                                        : _handleUpdateTap),
                              ),
                              if (!widget.isForceUpdate &&
                                  _state == _State.idle) ...[
                                6.verticalSpace,
                                TextButton(
                                  onPressed: () async {
                                    await controller.skipUpdateFor6Hours();
                                    controller.resetDialogFlag();
                                    Get.back<void>(closeOverlays: true);
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 6.h,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'app_status.remind_later'.tr,
                                    style: textTheme.labelMedium?.copyWith(
                                      fontSize: 13.sp,
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _headerIcon() {
    switch (_state) {
      case _State.error:
        return Icons.error_outline_rounded;
      case _State.installBlocked:
        return Icons.lock_outline_rounded;
      case _State.downloading:
        return Icons.cloud_download_rounded;
      case _State.installing:
        return Icons.install_mobile_rounded;
      case _State.idle:
        return Icons.rocket_launch_rounded;
    }
  }

  IconData? _ctaIcon(bool hasApk) {
    switch (_state) {
      case _State.error:
      case _State.installBlocked:
        return Icons.refresh_rounded;
      case _State.installing:
        return Icons.install_mobile_rounded;
      case _State.downloading:
        return null;
      case _State.idle:
        return hasApk
            ? Icons.download_rounded
            : Icons.arrow_forward_rounded;
    }
  }

  String _titleFor() {
    switch (_state) {
      case _State.downloading:
        return 'app_status.downloading_title'.tr;
      case _State.installing:
        return 'app_status.installing'.tr;
      case _State.error:
        return 'app_status.download_failed'.tr;
      case _State.installBlocked:
        return 'app_status.install_blocked_title'.tr;
      case _State.idle:
        return 'app_status.update_available'.tr;
    }
  }

  String _subtitleFor(String latest) {
    if (_state == _State.error) return _error ?? 'app_status.download_failed'.tr;
    if (_state == _State.installBlocked) {
      return _error ?? 'app_status.install_blocked_body'.tr;
    }
    if (_state == _State.installing) return 'app_status.tap_install_prompt'.tr;
    if (_state == _State.downloading) return 'app_status.please_wait'.tr;
    return 'app_status.update_message'.trParams({'version': latest});
  }

  String _ctaLabel(bool hasApk) {
    switch (_state) {
      case _State.error:
        return 'app_status.retry'.tr;
      case _State.installBlocked:
        return 'app_status.try_install_again'.tr;
      case _State.downloading:
        return 'app_status.downloading_title'.tr;
      case _State.installing:
        return 'app_status.open_installer'.tr;
      case _State.idle:
        return hasApk
            ? 'app_status.download_install'.tr
            : 'app_status.update_now'.tr;
    }
  }
}

/// Small "v1.0.0 → v1.0.1" chip shown under the header icon.
class _VersionPill extends StatelessWidget {
  const _VersionPill({required this.latest});

  final String latest;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.brandPurple.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: AppColors.brandPurple.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.new_releases_rounded,
            size: 14.w,
            color: AppColors.brandPurple,
          ),
          6.horizontalSpace,
          Text(
            'v$latest',
            style: textTheme.labelMedium?.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Primary CTA — gradient fill in idle state, danger red in error state, and
/// a compact loader while downloading / installing.
class _CtaButton extends StatelessWidget {
  const _CtaButton({
    required this.label,
    required this.gradient,
    required this.isError,
    required this.loading,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final LinearGradient gradient;
  final bool isError;
  final bool loading;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final disabled = onPressed == null && !loading;

    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: isError ? null : gradient,
            color: isError ? AppColors.danger : null,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: (isError ? AppColors.danger : AppColors.brandPurple)
                    .withValues(alpha: 0.30),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            onTap: loading ? null : onPressed,
            child: SizedBox(
              height: 44.h,
              width: double.infinity,
              child: Center(
                child: loading
                    ? SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 18.w, color: Colors.white),
                            Gap.hSm,
                          ],
                          Text(
                            label,
                            style: textTheme.labelLarge?.copyWith(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
