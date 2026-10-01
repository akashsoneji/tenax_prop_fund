import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tenax_prop_flutter/shared/theme/app_colors.dart';
import 'package:tenax_prop_flutter/shared/theme/app_spacing.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_bottom_sheet.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_brand_badge.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_button.dart';
import 'package:tenax_prop_flutter/shared/theme/app_text.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_card.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_coming_soon.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_icon_button.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_label.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_status_pill.dart';
import 'package:tenax_prop_flutter/shared/widgets/app_option_card.dart';
import 'package:tenax_prop_flutter/shared/widgets/history/app_history_empty.dart';
import 'package:tenax_prop_flutter/shared/widgets/history/app_history_row.dart';
import 'package:tenax_prop_flutter/shared/widgets/history/app_load_more_button.dart';
import 'package:tenax_prop_flutter/shared/widgets/market/app_symbol_card.dart';

/// The shared widgets restored into `lib/shared` (and the ones added after),
/// on their own page so the original [DesignGallery] goldens stay untouched.
class SharedWidgetsGallery extends StatelessWidget {
  const SharedWidgetsGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: AppBrandBadge()),
            Gap.vMd,
            AppButton(label: 'Primary', onPressed: () {}),
            Gap.vSm,
            AppButton.outlined(label: 'Outlined', onPressed: () {}),
            Gap.vSm,
            AppButton.tonal(label: 'Tonal', icon: Icons.add, onPressed: () {}),
            Gap.vSm,
            Row(children: [
              AppButton.text(label: 'Text', onPressed: () {}),
              AppButton.text(label: 'Disabled', onPressed: null),
            ]),
            Gap.vMd,
            AppSymbolCard(
              code: 'EURUSD',
              subtitle: 'Euro vs US Dollar',
              onTap: () {},
              quote: const AppSymbolQuote(
                bid: '1.08412',
                ask: '1.08425',
                high: '1.08711',
                low: '1.08102',
                spread: '1.3',
              ),
            ),
            Gap.vMd,
            AppOptionCard(
              title: 'Bank transfer',
              status: 'Set up',
              meta: 'USD · 1–3 business days',
              description: 'Withdraw your payouts straight to your bank account.',
              actionLabel: 'Add this method',
              onAction: () {},
            ),
            Gap.vMd,
            AppHistoryRow(
              title: 'Crypto (USDT)',
              subtitle: '01 Oct 2026',
              amount: 'USD 250.00',
              statusLabel: 'Pending',
              statusColor: AppColors.amber,
              cancelLabel: 'Cancel',
              onCancel: () {},
            ),
            const AppHistoryRow(
              title: 'Bank transfer',
              subtitle: '28 Sep 2026',
              amount: 'USD 1,200.00',
              statusLabel: 'Disbursed',
              statusColor: AppColors.success,
            ),
            AppLoadMoreButton(
              label: 'Load more',
              loadingLabel: 'Loading…',
              loading: false,
              onPressed: () {},
            ),
            Gap.vSm,
            const AppHistoryEmpty(title: 'No payouts yet', message: 'Your payout requests will show up here.'),
            Gap.vMd,
            const AppBottomSheet(
              title: 'Change password',
              subtitle: 'Use at least 8 characters.',
              children: [SizedBox(height: 40)],
            ),
            SizedBox(
              height: 200.h,
              child: const AppComingSoon(title: 'Competitions', icon: Icons.emoji_events_outlined),
            ),
            Gap.vMd,
            Row(children: [
              const AppStatusPill(label: 'Paid', color: AppColors.success),
              Gap.hSm,
              const AppStatusPill(label: 'Pending', color: AppColors.warningInk),
              Gap.hSm,
              AppStatusPill(label: 'Rejected', color: Theme.of(context).colorScheme.error),
              const Spacer(),
              AppIconButton(icon: Icons.settings_outlined, onTap: () {}),
            ]),
            Gap.vMd,
            AppCard(
              padding: EdgeInsets.all(16.w),
              radius: 18.r,
              child: Row(children: [
                Expanded(
                  child: AppLabel(
                    'A very long account name that must ellipsize instead of overflowing',
                    style: AppText.title(fontSize: 14.sp),
                  ),
                ),
                Gap.hSm,
                Text('USD 1,250.00', style: AppText.value(fontSize: 16.sp)),
              ]),
            ),
            Gap.vSm,
            AppCard(
              padding: EdgeInsets.all(14.w),
              onTap: () {},
              child: Text('Tappable card', style: AppText.regular(fontSize: 13.sp)),
            ),
          ],
        ),
      ),
    );
  }
}
