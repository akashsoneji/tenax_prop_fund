import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_gradient_button.dart';
import '../../../shared/widgets/app_labeled_field.dart';
import '../controllers/payout_methods_controller.dart';
import '../models/method_type.dart';
import '../models/payout_method.dart';
import '../../../shared/theme/app_text.dart';

/// Bottom sheet to add or edit a payout method. Loads the admin-configured
/// rails (`GET /finance/method-types`), then renders the dynamic field form for
/// the chosen rail and calls create/update on the controller.
///
/// Pass [existing] to edit; leave null to add.
class AddPayoutMethodSheet extends StatefulWidget {
  const AddPayoutMethodSheet({super.key, this.existing});

  final PayoutMethod? existing;

  /// Opens the sheet and returns true when a method was saved.
  static Future<bool?> show(BuildContext context, {PayoutMethod? existing}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPayoutMethodSheet(existing: existing),
    );
  }

  @override
  State<AddPayoutMethodSheet> createState() => _AddPayoutMethodSheetState();
}

class _AddPayoutMethodSheetState extends State<AddPayoutMethodSheet> {
  final _controller = Get.find<PayoutMethodsController>();
  final _labelText = TextEditingController();
  final _fieldControllers = <String, TextEditingController>{};

  MethodType? _selected;
  bool _submitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _labelText.text = widget.existing?.name ?? '';
    _controller.loadMethodTypes().then((_) {
      if (!mounted) return;
      setState(() {
        final types = _controller.methodTypes;
        if (types.isEmpty) return;
        _selected = _isEdit
            ? types.firstWhereOrNull((t) => t.value == widget.existing!.type) ??
                  types.first
            : types.first;
        _syncFieldControllers();
      });
    });
  }

  void _syncFieldControllers() {
    _fieldControllers.clear();
    for (final f in _selected?.fields ?? const <MethodTypeField>[]) {
      final initial = widget.existing?.details[f.key]?.toString() ?? '';
      _fieldControllers[f.key] = TextEditingController(text: initial)
        ..addListener(_onInputChanged);
    }
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _labelText.dispose();
    for (final c in _fieldControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.brightness == Brightness.dark
                ? AppColors.sheetDark
                : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 22.h),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 38.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 14.h),
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                Text(
                  _isEdit
                      ? 'payout_methods.edit_method'.tr
                      : 'rewards.add_payout_method'.tr,
                  style: AppText.base(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                18.verticalSpace,
                Obx(() {
                  if (_controller.isLoadingMethodTypes.value &&
                      _controller.methodTypes.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 30.h),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (_controller.methodTypes.isEmpty) {
                    return _EmptyTypes(scheme: scheme);
                  }
                  return _Form(
                    types: _controller.methodTypes,
                    selected: _selected,
                    onTypeChanged: (t) => setState(() {
                      _selected = t;
                      _syncFieldControllers();
                    }),
                    labelText: _labelText,
                    fieldControllers: _fieldControllers,
                  );
                }),
                22.verticalSpace,
                Obx(
                  () => AppGradientButton(
                    label: 'rewards.save_method'.tr,
                    icon: Icons.check_rounded,
                    loading: _submitting || _controller.isSubmitting.value,
                    onPressed: _canSubmit ? _submit : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _canSubmit =>
      _selected != null &&
      _selected!.fields
          .where((f) => f.required)
          .every(
            (f) => _fieldControllers[f.key]?.text.trim().isNotEmpty == true,
          );

  Future<void> _submit() async {
    final type = _selected;
    if (type == null) return;
    setState(() => _submitting = true);
    final typedLabel = _labelText.text.trim();
    final label = typedLabel.isEmpty ? type.label : typedLabel;
    final details = <String, dynamic>{
      for (final f in type.fields)
        f.key: _fieldControllers[f.key]?.text.trim() ?? '',
    };
    final result = _isEdit
        ? await _controller.updateMethod(
            id: widget.existing!.id,
            type: type.value,
            label: label,
            currency: type.currency ?? widget.existing!.currency,
            details: details,
          )
        : await _controller.createMethod(
            type: type.value,
            label: label,
            currency: type.currency ?? 'USD',
            details: details,
          );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result.success) {
      Navigator.of(context).pop(true);
      Get.snackbar(
        'payout_methods.saved'.tr,
        'payout_methods.saved_body'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } else {
      Get.snackbar(
        'payout_methods.save_failed'.tr,
        result.message ?? 'payout_methods.save_failed_body'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.types,
    required this.selected,
    required this.onTypeChanged,
    required this.labelText,
    required this.fieldControllers,
  });

  final List<MethodType> types;
  final MethodType? selected;
  final ValueChanged<MethodType> onTypeChanged;
  final TextEditingController labelText;
  final Map<String, TextEditingController> fieldControllers;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TypeDropdown(
          types: types,
          selected: selected,
          onChanged: onTypeChanged,
          scheme: scheme,
        ),
        14.verticalSpace,
        AppLabeledField(
          controller: labelText,
          label: 'payout_methods.label'.tr,
          hint: 'payout_methods.label_hint'.tr,
        ),
        for (final f in selected?.fields ?? const <MethodTypeField>[]) ...[
          14.verticalSpace,
          AppLabeledField(
            controller: fieldControllers[f.key]!,
            label: f.required
                ? '${f.label} *'
                : '${f.label} (${'common.optional'.tr})',
            hint: f.placeholder,
            keyboardType: f.type == 'number'
                ? const TextInputType.numberWithOptions(decimal: true)
                : f.type == 'email'
                ? TextInputType.emailAddress
                : TextInputType.text,
          ),
        ],
      ],
    );
  }
}

class _TypeDropdown extends StatelessWidget {
  const _TypeDropdown({
    required this.types,
    required this.selected,
    required this.onChanged,
    required this.scheme,
  });

  final List<MethodType> types;
  final MethodType? selected;
  final ValueChanged<MethodType> onChanged;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'rewards.method_type'.tr,
            style: AppText.base(
              fontSize: 12.5.sp,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<MethodType>(
              value: selected,
              isExpanded: true,
              icon: const Icon(Icons.expand_more_rounded),
              items: [
                for (final t in types)
                  DropdownMenuItem(
                    value: t,
                    child: Text(
                      t.label,
                      style: AppText.base(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
              ],
              onChanged: (t) {
                if (t != null) onChanged(t);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTypes extends StatelessWidget {
  const _EmptyTypes({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Text(
        'payout_methods.no_types'.tr,
        textAlign: TextAlign.center,
        style: AppText.base(
          fontSize: 13.sp,
          color: scheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
