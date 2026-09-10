import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';

/// Shared animated backdrop for the auth module. Provides:
///
///  * Three drifting color blobs that form a soft mesh-gradient feel
///    (no shader dependency — pure `AnimatedBuilder` + `RadialGradient`).
///  * A low-opacity "ticker tape" of fake symbols scrolling across, hinting at
///    the trading-product context without requiring a market data feed.
///  * A dark-to-light fade so the foreground content sits on a calm surface.
///
/// Used by both LoginViewA and the register/forgot flows. Layout B uses its
/// own `MarketingScaffold` for the side-by-side composition.
class AuthScaffold extends StatefulWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.heroTitle,
    this.heroSubtitle,
    this.showTicker = true,
    this.padding = const EdgeInsets.fromLTRB(24, 60, 24, 24),
    this.bottomBar,
  });

  final Widget child;

  /// Optional hero headline shown above the content (e.g. "Trade smarter,\nfaster.").
  final String? heroTitle;
  final String? heroSubtitle;

  /// If true, a faint ticker scrolls at the bottom edge of the background.
  final bool showTicker;

  final EdgeInsets padding;

  /// Persistent bottom bar (e.g. primary CTA). Pinned above the safe-area
  /// inset so it stays visible while the content scrolls.
  final Widget? bottomBar;

  @override
  State<AuthScaffold> createState() => _AuthScaffoldState();
}

class _AuthScaffoldState extends State<AuthScaffold>
    with TickerProviderStateMixin {
  late final AnimationController _mesh = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _mesh.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final base = brightness == Brightness.dark
        ? scheme.surface
        : scheme.surface;

    return Scaffold(
      backgroundColor: base,
      body: Stack(
        children: [
          // Animated mesh-gradient feel.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _mesh,
              builder: (context, _) {
                return CustomPaint(
                  painter: _MeshPainter(
                    progress: _mesh.value,
                    pulse: _pulse.value,
                    primary: scheme.primary,
                    secondary: scheme.secondary,
                    tertiary: scheme.primary,
                    onSurface: scheme.onSurface,
                    dark: brightness == Brightness.dark,
                  ),
                );
              },
            ),
          ),
          // Ticker tape (optional).
          if (widget.showTicker)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.18,
                  child: _TickerTape(
                    color: brightness == Brightness.dark
                        ? AppColors.white
                        : scheme.onSurface,
                  ),
                ),
              ),
            ),
          // Foreground content.
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: widget.padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.heroTitle != null) ...[
                          Text(
                            widget.heroTitle!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.05,
                                  color: scheme.onSurface,
                                ),
                          ),
                          if (widget.heroSubtitle != null) ...[
                            SizedBox(height: 8.h),
                            Text(
                              widget.heroSubtitle!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.65),
                                  ),
                            ),
                          ],
                          SizedBox(height: 28.h),
                        ],
                        widget.child,
                      ],
                    ),
                  ),
                ),
                if (widget.bottomBar != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 12.h),
                    child: widget.bottomBar!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  _MeshPainter({
    required this.progress,
    required this.pulse,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.onSurface,
    required this.dark,
  });

  final double progress;
  final double pulse;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color onSurface;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: dark
            ? [AppColors.authTop, AppColors.authBottom]
            : [AppColors.authLightTop, const Color(0xFFFFFFFF)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Three drifting blobs.
    final t = progress * 2 * math.pi;
    final blobs = <_Blob>[
      _Blob(
        color: primary,
        radius: size.shortestSide * 0.85,
        offset: Offset(
          size.width * (0.30 + 0.10 * math.sin(t)),
          size.height * (0.18 + 0.06 * math.cos(t * 0.8)),
        ),
      ),
      _Blob(
        color: secondary,
        radius: size.shortestSide * 0.7,
        offset: Offset(
          size.width * (0.70 + 0.08 * math.cos(t * 1.1)),
          size.height * (0.55 + 0.08 * math.sin(t * 0.9)),
        ),
      ),
      _Blob(
        color: tertiary,
        radius: size.shortestSide * 0.6,
        offset: Offset(
          size.width * (0.45 + 0.12 * math.sin(t * 0.7 + 1.5)),
          size.height * (0.85 + 0.05 * math.cos(t * 0.6 + 1.2)),
        ),
      ),
    ];

    final pulseScale = 1.0 + 0.04 * pulse;
    for (final blob in blobs) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            blob.color.withValues(alpha: dark ? 0.28 : 0.18),
            blob.color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(
          center: blob.offset,
          radius: blob.radius * pulseScale,
        ));
      canvas.drawCircle(blob.offset, blob.radius * pulseScale, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter old) =>
      old.progress != progress ||
      old.pulse != pulse ||
      old.primary != primary ||
      old.secondary != secondary ||
      old.tertiary != tertiary ||
      old.dark != dark;
}

class _Blob {
  _Blob({required this.color, required this.radius, required this.offset});
  final Color color;
  final double radius;
  final Offset offset;
}

class _TickerTape extends StatefulWidget {
  const _TickerTape({required this.color});
  final Color color;

  @override
  State<_TickerTape> createState() => _TickerTapeState();
}

class _TickerTapeState extends State<_TickerTape>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
  )..repeat();

  // Static demo feed — keeps the visual weight on the brand rather than on
  // the data feed. Real quotes arrive via WebSocket on the dashboard.
  static const _rows = <String>[
    'BTC/USD  64,210.42  ▲ 1.84%',
    'ETH/USD   3,128.10  ▲ 0.62%',
    'EUR/USD   1.0893    ▼ 0.12%',
    'XAU/USD   2,341.20  ▲ 0.41%',
    'AAPL     189.55     ▲ 0.27%',
    'TSLA     172.18     ▼ 1.10%',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24.h,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: 0,
              maxWidth: double.infinity,
              child: Transform.translate(
                offset: Offset(-_ctrl.value * 320, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < 4; i++)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final row in _rows) ...[
                              Text(
                                row,
                                style: TextStyle(
                                  color: widget.color,
                                  fontSize: 12.sp,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                  letterSpacing: 0.4,
                                ),
                              ),
                              SizedBox(width: 24.w),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Side-by-side marketing scaffold for LoginViewB: tall illustrated panel on
/// the left with the brand promise, glass card with the form on the right.
/// On narrow screens it collapses to a vertical stack.
class MarketingScaffold extends StatelessWidget {
  const MarketingScaffold({
    super.key,
    required this.child,
    required this.heroTitle,
    required this.heroSubtitle,
  });

  final Widget child;
  final String heroTitle;
  final String heroSubtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 720;
          if (narrow) {
            return Column(
              children: [
                _MarketingPanel(
                  heroTitle: heroTitle,
                  heroSubtitle: heroSubtitle,
                  scheme: scheme,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24.w),
                    child: child,
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(
                flex: 5,
                child: _MarketingPanel(
                  heroTitle: heroTitle,
                  heroSubtitle: heroSubtitle,
                  scheme: scheme,
                ),
              ),
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(32.w),
                  child: Center(child: child),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MarketingPanel extends StatelessWidget {
  const _MarketingPanel({
    required this.heroTitle,
    required this.heroSubtitle,
    required this.scheme,
  });

  final String heroTitle;
  final String heroSubtitle;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient(scheme),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.candlestick_chart_rounded,
                  size: 56.w, color: AppColors.white),
              SizedBox(height: 24.h),
              Text(
                heroTitle,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 36.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                heroSubtitle,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.85),
                  fontSize: 16.sp,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 32.h),
              Wrap(
                spacing: 12.w,
                runSpacing: 8.h,
                children: [
                  _Pill(label: 'auth.pill_challenges'.tr),
                  _Pill(label: 'auth.pill_payouts'.tr),
                  _Pill(label: 'auth.pill_charts'.tr),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
