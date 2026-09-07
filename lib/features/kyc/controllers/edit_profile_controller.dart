import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/kyc_profile.dart';

/// Drives the Edit Profile screen. Seeds its text fields from the current
/// [KycController] profile (when available) and hands the edited values back on
/// save. Purely local/demo state — no backend call yet.
class EditProfileController extends GetxController {
  // ignore: prefer_initializing_formals
  EditProfileController({KycProfile? seed}) : _seed = seed;

  final KycProfile? _seed;

  late final TextEditingController fullName;
  late final TextEditingController email;
  late final TextEditingController mobile;
  late final TextEditingController country;
  late final TextEditingController dateOfBirth;

  final saving = false.obs;

  @override
  void onInit() {
    super.onInit();
    fullName = TextEditingController(text: _seed?.name ?? '');
    email = TextEditingController(text: _detail('Email'));
    mobile = TextEditingController(text: _detail('Mobile'));
    country = TextEditingController(text: _detail('Country'));
    dateOfBirth = TextEditingController(text: _detail('Date of birth'));
  }

  String _detail(String label) {
    final rows = _seed?.details ?? const <KycDetailRow>[];
    for (final r in rows) {
      if (r.label == label) return r.value;
    }
    return '';
  }

  Future<void> save() async {
    if (saving.value) return;
    saving.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 700));
    saving.value = false;
    Get.back();
    Get.snackbar(
      'edit_profile.saved_title'.tr,
      'edit_profile.saved_body'.tr,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
    );
  }

  @override
  void onClose() {
    fullName.dispose();
    email.dispose();
    mobile.dispose();
    country.dispose();
    dateOfBirth.dispose();
    super.onClose();
  }
}
