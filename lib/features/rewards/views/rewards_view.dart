import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../billing/controllers/billing_controller.dart';
import '../../billing/models/billing_models.dart';
import '../../billing/widgets/billing_filter_tabs.dart';
import '../../billing/widgets/billing_transaction_list.dart';
import '../../payout_methods/controllers/payout_methods_controller.dart';
import '../../payout_methods/models/payout_method.dart';
import '../../payout_methods/widgets/payout_method_card.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/data_state_builder.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../../../shared/widgets/skeletons/skeletons.dart';
import '../controllers/rewards_controller.dart';
import '../models/reward_models.dart';
import '../widgets/info_banner.dart';
import '../widgets/requirement_row.dart';
import '../widgets/request_payout_sheet.dart';
import '../widgets/section_title.dart';
import '../widgets/staggered_grid.dart';
import '../widgets/stat_tile.dart';

/// Full Rewards screen. Composed of:
///
///  * Purple gradient hero header with the back button.
///  * 2x2 stat grid (Withdrawable / Pending / Paid out / Your share).
///  * "Requests" section — the blocking-issues card and the CTA.
///  * KYC name-match reminder banner.
///
/// Loading/error/empty are handled by [DataStateBuilder] on the controller's
/// `DataState<RewardsData>`; the real UI reads the loaded data — swap the
/// repository for the real API later without touching the layout.
class RewardsView extends StatefulWidget {
  const RewardsView({super.key});

  @override
  State<RewardsView> createState() => _RewardsViewState();
}

class _RewardsViewState extends State<RewardsView> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = Get.find<RewardsController>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          PinnedGradientAppBar(title: 'rewards.title'.tr),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
              child: _FinanceTabs(
                selectedTab: _selectedTab,
                onChanged: (tab) => setState(() => _selectedTab = tab),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width,
              child: _buildTabContent(c),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(RewardsController controller) {
    if (_selectedTab == 1) return const _BillingTabContent();
    if (_selectedTab == 2) return const _PayoutMethodsTabContent();

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 32.h),
      child: Obx(
        () => DataStateBuilder<RewardsData>(
          state: controller.state,
          onRetry: controller.load,
          skeleton: const _RewardsSkeleton(),
          builder: (data) => _RewardsBody(controller: controller, data: data),
        ),
      ),
    );
  }
}

class _BillingTabContent extends StatelessWidget {
  const _BillingTabContent();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BillingController>();
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 32.h),
      child: Obx(
        () => DataStateBuilder<BillingData>(
          state: controller.state,
          onRetry: controller.load,
          skeleton: const _RewardsSkeleton(),
          builder: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Billing history',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Obx(
                    () => SizedBox(
                      width: 118.w,
                      height: 44.h,
                      child: OutlinedButton.icon(
                        onPressed: controller.isExporting.value
                            ? null
                            : () => _exportCsv(context, controller),
                        icon: controller.isExporting.value
                            ? SizedBox(
                                width: 15.w,
                                height: 15.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.download_rounded, size: 17.w),
                        label: Text(
                          'Export',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h,),
              BillingFilterTabs(
                selected: controller.filter.value,
                onChanged: controller.setFilter,
              ),
              SizedBox(height: 16.h),
              BillingTransactionList(
                transactions: controller.filteredTransactions(data),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportCsv(
    BuildContext context,
    BillingController controller,
  ) async {
    final result = await controller.exportBilling();
    if (!context.mounted) return;
    if (!result.success || result.data == null || result.data!.isEmpty) {
      Get.snackbar(
        'Export failed',
        result.message ?? 'Unable to export billing history.',
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(16.w),
        borderRadius: 14.r,
      );
      return;
    }

    final path = await FilePicker.saveFile(
      dialogTitle: 'Save billing statement',
      fileName: 'billing_statement.csv',
      bytes: Uint8List.fromList(result.data!.codeUnits),
    );
    if (!context.mounted) return;
    Get.snackbar(
      path == null ? 'Export cancelled' : 'Export saved',
      path == null
          ? 'The CSV file was not saved.'
          : 'Billing statement saved successfully.',
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.all(16.w),
      borderRadius: 14.r,
    );
  }
}

class _PayoutMethodsTabContent extends StatelessWidget {
  const _PayoutMethodsTabContent();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PayoutMethodsController>();
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 32.h),
      child: Obx(
        () => DataStateBuilder<List<PayoutMethod>>(
          state: controller.state,
          onRetry: controller.load,
          skeleton: const _RewardsSkeleton(),
          builder: (methods) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Payout methods',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 14.h),
              SizedBox(
                height: 50.h,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddMethodSheet(context, controller),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add method'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              if (methods.isEmpty)
                InfoBanner(
                  variant: InfoBannerVariant.warning,
                  title: 'No payout method saved',
                  body: 'Add a payout method before requesting your reward.',
                )
              else
                for (final method in methods) ...[
                  PayoutMethodCard(method: method),
                  SizedBox(height: 12.h),
                ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMethodSheet(
    BuildContext context,
    PayoutMethodsController controller,
  ) {
    final labelController = TextEditingController();
    final accountController = TextEditingController();
    final ifscController = TextEditingController();
    var type = 'bank';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 42.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    'Add payout method',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Method type'),
                    items: const [
                      DropdownMenuItem(value: 'bank', child: Text('Bank transfer')),
                      DropdownMenuItem(value: 'crypto', child: Text('USDT / Crypto')),
                      DropdownMenuItem(value: 'upi', child: Text('UPI')),
                    ],
                    onChanged: (value) => setSheetState(() => type = value ?? 'bank'),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(labelText: 'Method name'),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: accountController,
                    decoration: const InputDecoration(labelText: 'Account / wallet address'),
                  ),
                  if (type == 'bank') ...[
                    SizedBox(height: 12.h),
                    TextField(
                      controller: ifscController,
                      decoration: const InputDecoration(labelText: 'IFSC / routing code'),
                    ),
                  ],
                  SizedBox(height: 20.h),
                  Obx(
                    () => ElevatedButton(
                      onPressed: controller.isSubmitting.value
                          ? null
                          : () async {
                              final result = await controller.createMethod(
                                type: type,
                                label: labelController.text.trim(),
                                currency: 'USD',
                                details: {
                                  'account_number': accountController.text.trim(),
                                  if (ifscController.text.trim().isNotEmpty)
                                    'ifsc': ifscController.text.trim(),
                                },
                              );
                              if (!sheetContext.mounted) return;
                              if (result.success) {
                                Navigator.of(sheetContext).pop();
                              } else {
                                Get.snackbar('Unable to add method', result.message ?? 'Please try again.');
                              }
                            },
                      child: controller.isSubmitting.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save method'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loaded body.
// ---------------------------------------------------------------------------
class _FinanceTabs extends StatelessWidget {
  const _FinanceTabs({required this.selectedTab, required this.onChanged});

  final int selectedTab;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tabs = <({String label, IconData icon})>[
      (label: 'Rewards', icon: Icons.auto_awesome_rounded),
      (label: 'Billing', icon: Icons.receipt_long_rounded),
      (label: 'Payout methods', icon: Icons.account_balance_wallet_rounded),
    ];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(i),
                borderRadius: BorderRadius.circular(12.r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 4.w),
                  decoration: BoxDecoration(
                    color: i == selectedTab ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tabs[i].icon,
                        size: 18.w,
                        color: i == selectedTab ? scheme.onPrimary : scheme.onSurface.withValues(alpha: 0.62),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        tabs[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w700,
                          color: i == selectedTab ? scheme.onPrimary : scheme.onSurface.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RewardsBody extends StatelessWidget {
  const _RewardsBody({required this.controller, required this.data});
  final RewardsController controller;
  final RewardsData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatGrid(data: data),
        SizedBox(height: 26.h),
        RewardsSectionTitle('rewards.requests'.tr),
        _RequestsCard(controller: controller, data: data),
        SizedBox(height: 18.h),
        _RequestPayoutCta(controller: controller),
        SizedBox(height: 18.h),
        InfoBanner(
          variant: InfoBannerVariant.warning,
          title: 'rewards.name_match_id'.tr,
          body: 'rewards.name_match_id_body'.tr,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer skeleton matching the screen's shape.
// ---------------------------------------------------------------------------
class _RewardsSkeleton extends StatelessWidget {
  const _RewardsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeroSkeleton(height: 120.h),
        SizedBox(height: 26.h),
        const StatGridSkeleton(),
        SizedBox(height: 18.h),
        CardSkeleton(lines: 4, height: 200.h),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 2x2 stat grid — animated stagger
// ---------------------------------------------------------------------------
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.data});
  final RewardsData data;

  @override
  Widget build(BuildContext context) {
    final w = data.withdrawable;
    final p = data.pending;
    final paid = data.paidOut;
    final share = data.yourShare;

    return StaggeredGrid(
      children: [
        StatTile(
          label: 'rewards.withdrawable'.tr,
          value: w.amountUsd,
          tone: StatTileTone.green,
          trailingIcon: Icons.tune_rounded,
        ),
        StatTile(
          label: 'rewards.pending'.tr,
          value: p.amountUsd,
          tone: StatTileTone.amber,
          trailingIcon: Icons.tune_rounded,
        ),
        StatTile(
          label: 'rewards.paid_out'.tr,
          value: paid.amountUsd,
          tone: StatTileTone.purple,
          trailingIcon: Icons.tune_rounded,
        ),
        StatTile(
          label: 'rewards.your_share'.tr,
          value: '${share.percent}%',
          tone: StatTileTone.blue,
          trailingIcon: Icons.tune_rounded,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// "Requests" card — title, requirement rows, blocking-issues banner.
// ---------------------------------------------------------------------------
class _RequestsCard extends StatelessWidget {
  const _RequestsCard({required this.controller, required this.data});
  final RewardsController controller;
  final RewardsData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.page,
      curve: AppMotion.enter,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 18.h),
            child: child,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
        decoration: AppTheme.surfaceCard(scheme, radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 6.h, top: 2.h),
              child: Text(
                'rewards.what_stands'.tr,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 15.5.sp,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Column(
              children: [
                for (var i = 0; i < data.requirements.length; i++)
                  RequirementRow(
                    requirement: data.requirements[i],
                    showDivider: i != data.requirements.length - 1,
                  ),
              ],
            ),
            SizedBox(height: 6.h),
            Builder(builder: (context) {
              final n = controller.blockingCount(data);
              if (n == 0) return const SizedBox.shrink();
              return InfoBanner(
                title: 'rewards.two_things_blocking'.tr.replaceFirst('Two', '$n'),
                body: 'rewards.two_things_blocking_body'.tr,
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CTA
// ---------------------------------------------------------------------------
class _RequestPayoutCta extends StatelessWidget {
  const _RequestPayoutCta({required this.controller});
  final RewardsController controller;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: const Interval(0.25, 1.0, curve: AppMotion.enter),
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 16.h),
            child: child,
          ),
        );
      },
      child: AppGradientButton(
        label: 'rewards.request_payout'.tr,
        icon: Icons.account_balance_wallet_rounded,
        onPressed: () {
          controller.openPayoutSheet();
          _showRequestSheet(context);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet plumbing
// ---------------------------------------------------------------------------
void _showRequestSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (_) => const RequestPayoutSheet(),
  );
}
