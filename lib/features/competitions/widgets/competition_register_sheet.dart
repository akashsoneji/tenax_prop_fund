import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text.dart';
import '../controllers/competitions_controller.dart';
import '../models/competition_models.dart';

/// Bottom sheet that asks which trading account to enter a competition with,
/// then hands the choice to [CompetitionsController.register].
class CompetitionRegisterSheet extends StatelessWidget {
  const CompetitionRegisterSheet({
    super.key,
    required this.competition,
    required this.accounts,
  });

  final Competition competition;
  final List<CompetitionAccountOption> accounts;

  static Future<void> show(
    BuildContext context, {
    required Competition competition,
    required List<CompetitionAccountOption> accounts,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => CompetitionRegisterSheet(
        competition: competition,
        accounts: accounts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = Get.find<CompetitionsController>();

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.72,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'competitions.select_account'.tr,
              style: AppText.title(fontSize: 16.sp, color: scheme.onSurface),
            ),
            SizedBox(height: 4.h),
            Text(
              competition.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.label(
                fontSize: 12.sp,
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 16.h),
            Flexible(
              child: accounts.isEmpty
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      child: Text(
                        'competitions.no_accounts'.tr,
                        textAlign: TextAlign.center,
                        style: AppText.body(
                          fontSize: 13.sp,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: accounts.length,
                      separatorBuilder: (_, _) => SizedBox(height: 10.h),
                      itemBuilder: (context, index) => Obx(
                        () => _AccountTile(
                          account: accounts[index],
                          selected: controller.selectedAccount.value?.id ==
                              accounts[index].id,
                          onTap: () =>
                              controller.selectAccount(accounts[index]),
                        ),
                      ),
                    ),
            ),
            SizedBox(height: 16.h),
            Obx(
              () => _ConfirmButton(
                enabled: controller.selectedAccount.value != null &&
                    !controller.isRegistering(competition),
                busy: controller.isRegistering(competition),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final entered = await controller.register(competition);
                  if (entered) navigator.pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.selected,
    required this.onTap,
  });

  final CompetitionAccountOption account;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.12)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.40),
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18.w,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  account.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.subtitle(
                    fontSize: 14.sp,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: Material(
        color: enabled
            ? scheme.primary
            : scheme.surfaceContainerHighest.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14.r),
          child: Center(
            child: busy
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      valueColor: AlwaysStoppedAnimation(scheme.onSurfaceVariant),
                    ),
                  )
                : Text(
                    'competitions.confirm_entry'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title(
                      fontSize: 15.sp,
                      color:
                          enabled ? AppColors.white : scheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
