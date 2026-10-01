import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tenax_prop_flutter/shared/theme/app_spacing.dart';
import 'package:tenax_prop_flutter/shared/theme/app_text.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_checkbox.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_dashed.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_empty_view.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_gradient_button.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_info_banner.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_pill.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_segmented_control.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_stat_grid.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_stat_tile.dart';
import 'package:tenax_prop_flutter/shared/widgets/icon_leading_row.dart';
import 'package:tenax_prop_flutter/shared/widgets/key_value_row.dart';
import 'package:tenax_prop_flutter/shared/widgets/section_header.dart';

/// Every shared building block that carries the app's font, colour and size
/// decisions, laid out on one page for the golden test.
class DesignGallery extends StatelessWidget {
  const DesignGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Headline Large', style: text.headlineLarge),
            Text('Title Medium', style: text.titleMedium),
            Text('Body medium · 400', style: text.bodyMedium),
            Text('w500 w600 w700 w800',
                style: AppText.base(fontSize: 14.sp, fontWeight: FontWeight.w800)),
            Gap.vMd,
            Wrap(spacing: 6.w, runSpacing: 6.h, children: [
              for (final c in [scheme.primary, scheme.secondary, scheme.surface,
                  scheme.onSurface, scheme.outlineVariant, scheme.error])
                SizedBox(width: 40.w, height: 24.h, child: ColoredBox(color: c)),
            ]),
            Gap.vMd,
            AppGradientButton(label: 'Continue', onPressed: () {}),
            Gap.vMd,
            Row(children: [
              AppPill(label: 'Active', color: scheme.primary, showDot: true),
              Gap.hSm,
              AppPill(label: 'Failed', color: scheme.error, bordered: true),
            ]),
            Gap.vMd,
            AppSegmentedControl(labels: const ['Open', 'Pending', 'Closed'], selected: 1, onChanged: (_) {}),
            Gap.vMd,
            const AppStatTile(label: 'Balance', value: '\$10,250.00', icon: Icons.account_balance_wallet_outlined, boxed: true),
            Gap.vMd,
            const AppStatGrid(stats: [
              AppStat(label: 'Equity', value: '\$9,980'),
              AppStat(label: 'Profit', value: '+\$420'),
              AppStat(label: 'Drawdown', value: '3.2%'),
              AppStat(label: 'Days', value: '12'),
            ]),
            Gap.vMd,
            const SectionHeader('Trading rules'),
            const RulesCard(children: [
              KeyValueRow(label: 'Max daily loss', value: '5%'),
              KeyValueRow(label: 'Profit target', value: '10%', emphasize: true, showDivider: false),
            ]),
            Gap.vMd,
            IconLeadingRow(icon: Icons.lock_outline, title: 'Security', subtitle: 'Password, 2FA', onTap: () {}),
            AppCheckbox(value: true, onChanged: (_) {}, label: 'I accept the terms'),
            const AppDashedDivider(color: Colors.grey),
            const AppInfoBanner(title: 'Heads up', body: 'Payouts are processed within 24 hours.'),
            Gap.vSm,
            const AppInfoBanner(title: 'Warning', body: 'Margin level is low.', tone: BannerTone.warning),
            Gap.vMd,
            const AppEmptyView(messageKey: 'state.empty_message', titleKey: 'state.empty_title', boxed: true),
          ],
        ),
      ),
    );
  }
}
