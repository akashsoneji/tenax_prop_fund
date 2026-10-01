import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text.dart';

/// Live password strength
/// gradient as the password gets stronger, plus a checklist of requirements
/// (length / number / symbol) each with a checkmark that animates in when met.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  static const _minLength = 8;

  int get _score {
    if (password.isEmpty) return 0;
    var score = 0;
    if (password.length >= _minLength) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_=+]').hasMatch(password)) score++;
    if (password.length >= 12) score++;
    return score;
  }

  String get _labelKey {
    return switch (_score) {
      <= 1 => 'register.strength_weak',
      2 => 'register.strength_fair',
      3 => 'register.strength_good',
      _ => 'register.strength_strong',
    };
  }

  Color _color(ColorScheme scheme) {
    return switch (_score) {
      <= 1 => scheme.error,
      2 => AppColors.warning,
      3 => Colors.amber,
      _ => Colors.green,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _color(scheme);
    final ratio = password.isEmpty ? 0.0 : _score / 4.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bar — 4 segments.
        Row(
          children: List.generate(4, (i) {
            final filled = i < _score;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 6.h,
                margin: EdgeInsets.only(right: i == 3 ? 0 : 6.w),
                decoration: BoxDecoration(
                  color: filled
                      ? color
                      : scheme.onSurface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
            );
          }),
        ),
        6.verticalSpace,
        Row(
          children: [
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: ratio),
                duration: const Duration(milliseconds: 200),
                builder: (_, _, _) => Opacity(
                  opacity: password.isEmpty ? 0 : 1,
                  child: Text(
                    _labelKey.tr,
                    style: AppText.base(
                      color: color,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Gap.vMd,
        _Requirement(
          met: password.length >= _minLength,
          label: 'register.req_length'.tr,
        ),
        _Requirement(
          met: RegExp(r'[0-9]').hasMatch(password),
          label: 'register.req_number'.tr,
        ),
        _Requirement(
          met: RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_=+]').hasMatch(password),
          label: 'register.req_symbol'.tr,
        ),
      ],
    );
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement({required this.met, required this.label});

  final bool met;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              met ? Icons.check_circle_rounded : Icons.circle_outlined,
              key: ValueKey(met),
              size: 16.w,
              color: met
                  ? Colors.green
                  : scheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          Gap.hSm,
          Text(
            label,
            style:
                AppText.base(
                  fontSize: 12.sp,
                  color: met
                      ? scheme.onSurface
                      : scheme.onSurface.withValues(alpha: 0.6),
                ).copyWith(
                  decoration: met ? TextDecoration.lineThrough : null,
                  decorationColor: scheme.onSurface.withValues(alpha: 0.4),
                ),
          ),
        ],
      ),
    );
  }
}
