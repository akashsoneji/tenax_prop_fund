import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The ONE primary CTA
/// purple → magenta gradient with WHITE text in both light and dark mode.
///
/// Do NOT wire `scheme.onPrimary` here — that flips to dark ink in dark mode
/// (see [AppTheme]) and would disappear against the gradient. White is the
/// only readable choice on this fill and is baked in.
///
/// Use everywhere the user takes the main action (Sign in, Create account,
/// Send code, Verify, Continue, Save, etc.). For a secondary/ghost action
/// prefer `OutlinedButton`; for a link-style action use `TextButton`.
class AppGradientButton extends StatefulWidget {
  const AppGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.height = 54,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final double height;

  /// When true (default) the button fills its parent horizontally. Set false
  /// when embedding inside a Row where you want intrinsic width.
  final bool expand;

  @override
  State<AppGradientButton> createState() => _AppGradientButtonState();
}

class _AppGradientButtonState extends State<AppGradientButton>
    with TickerProviderStateMixin {
  AnimationController? _sweep;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.loading) _sweep!.repeat();
  }

  @override
  void didUpdateWidget(covariant AppGradientButton old) {
    super.didUpdateWidget(old);
    final c = _sweep;
    if (c == null || !mounted) return;
    if (widget.loading) {
      if (!c.isAnimating) c.repeat();
    } else {
      c.stop();
      c.value = 0;
    }
  }

  @override
  void dispose() {
    _sweep?.stop();
    _sweep?.dispose();
    _sweep = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabled = widget.onPressed == null || widget.loading;

    final btn = Opacity(
      opacity: disabled ? 0.85 : 1,
      child: Material(
      color: AppColors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: disabled ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(14.r),
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient(scheme),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: SizedBox(
              height: widget.height,
              child: Stack(
                children: [
                  if (widget.loading && _sweep != null)
                    AnimatedBuilder(
                      animation: _sweep!,
                      builder: (context, _) {
                        final v = _sweep?.value ?? 0.0;
                        return Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14.r),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: const [
                                    AppColors.transparent,
                                    Color(0x33FFFFFF),
                                    AppColors.transparent,
                                  ],
                                  stops: [v - 0.2, v, v + 0.2],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  Center(
                    child: widget.loading
                        ? SizedBox(
                            width: 22.w,
                            height: 22.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(widget.icon,
                                    color: Colors.white, size: 18.w),
                                SizedBox(width: 10.w),
                              ],
                              Text(
                                widget.label,
                                style: GoogleFonts.beVietnamPro(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return widget.expand
        ? SizedBox(width: double.infinity, child: btn)
        : btn;
  }
}
