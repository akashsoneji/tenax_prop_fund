import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/kyc_profile.dart';
import '../repositories/kyc_repository.dart';
import 'kyc_controller.dart';

/// Drives the Edit Profile screen. Seeds its text fields from the current
/// [KycController] profile (when available) and persists changes through
/// `PUT /profile` via [KycRepository]. On success it refreshes the KYC screen
/// so the updated details show immediately.
class EditProfileController extends GetxController {
  // ignore: prefer_initializing_formals
  EditProfileController(this._repository, {KycProfile? seed}) : _seed = seed;

  final KycRepository _repository;
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
    // The PROPCRM API expects separate first/last names. Split the single
    // full-name field on the first space; everything after it is the surname.
    final parts = fullName.text.trim().split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final res = await _repository.updateProfile({
      'first_name': firstName,
      'last_name': lastName,
      'phone': mobile.text.trim(),
      'country_code': country.text.trim(),
    });
    saving.value = false;
    if (!res.success) return;

    if (Get.isRegistered<KycController>()) {
      await Get.find<KycController>().refreshProfile();
    }
    Get.back();
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
