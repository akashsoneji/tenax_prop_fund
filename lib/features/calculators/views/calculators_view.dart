import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/state/data_state.dart';
import '../../../shared/widgets/app_empty_view.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/pinned_gradient_app_bar.dart';
import '../controllers/calculators_controller.dart';
import '../models/calculator_models.dart';
import '../widgets/calc_inputs.dart';
import '../widgets/calc_result_card.dart';
import '../widgets/calc_segmented_tabs.dart';

class CalculatorsView extends GetView<CalculatorsController> {
  const CalculatorsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Obx(() {
        final state = controller.state;
        if (state is DataLoading || state is DataInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is DataFailure<CalculatorsData>) {
          return AppEmptyView(
            messageKey: state.message,
            icon: Icons.error_outline_rounded,
            onRetry: controller.load,
          );
        }
        if (state is DataEmpty) {
          return const AppEmptyView(messageKey: 'calculators.none_available');
        }
        final data = controller.calculators;
        if (data == null || data.tabs.isEmpty) {
          return const AppEmptyView(messageKey: 'calculators.none_available');
        }
        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          slivers: [
            PinnedGradientAppBar(title: 'calculators.title'.tr),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 32.h),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  CalcSegmentedTabs(
                    labels: data.tabs.map((tab) => tab.label).toList(),
                    selectedIndex: controller.selectedTab.value,
                    onSelected: controller.selectTab,
                  ),
                  18.verticalSpace,
                  _CalculatorForm(definition: controller.selectedDefinition!),
                ]),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _CalculatorForm extends StatelessWidget {
  const _CalculatorForm({required this.definition});
  final CalculatorDefinition definition;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CalculatorsController>();
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      final fields = definition.fields;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 16.h),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(color: scheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 18.r,
                  offset: Offset(0, 8.h),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (definition.note.isNotEmpty) ...[
                  Text(
                    definition.note,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  14.verticalSpace,
                ],
                for (final field in fields) ...[
                  if (field.isSelect)
                    CalcSymbolDropdown(
                      value: c.field(field.key).isEmpty
                          ? field.options.first
                          : c.field(field.key),
                      items: field.options,
                      onChanged: (value) => c.setField(field.key, value),
                      label: field.label,
                    )
                  else
                    CalcInputField(
                      label: field.label,
                      value: c.field(field.key),
                      onChanged: (value) => c.setField(field.key, value),
                    ),
                  14.verticalSpace,
                ],
                AppGradientButton(
                  label: 'calculators.calculate'.tr,
                  height: 52.h,
                  onPressed: () => c.setField(
                    '_calculated',
                    DateTime.now().toIso8601String(),
                  ),
                ),
              ],
            ),
          ),
          18.verticalSpace,
          CalcResultCard(
            headline: c.formatResult(),
            subtitle: definition.label,
          ),
          if (c.calculators?.disclaimer.isNotEmpty == true) ...[
            14.verticalSpace,
            CalcNoteBanner(text: c.calculators!.disclaimer),
          ],
        ],
      );
    });
  }
}
