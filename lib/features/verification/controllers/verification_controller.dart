import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/app_toast.dart';
import '../../kyc/repositories/kyc_repository.dart';
import '../models/verification_models.dart';

/// Drives the whole "Verify your account" journey: the overview, the paged
/// stepper, personal-details form, phone OTP, and document proofs.
///
/// All [TextEditingController]s are owned here and disposed in [onClose] so the
/// form survives navigation between steps without leaking. Async actions (OTP
/// send/verify) are guarded with `busy` flags so a double-tap cannot fire two
/// in-flight requests (race-condition safe).
class VerificationController extends GetxController {
  VerificationController(this._repository);

  final KycRepository _repository;

  final uploadingDocs = false.obs;
  final savingPersonal = false.obs;

  // --- Step model -----------------------------------------------------------
  final steps = <VerificationStep>[
    const VerificationStep(
      index: 1,
      title: 'verification.step_personal_details',
      benefits: [
        'verification.benefit_deposit_limit',
        'verification.benefit_limited_methods',
        'verification.benefit_live_demo',
      ],
      status: VerificationStatus.completed,
    ),
    const VerificationStep(
      index: 2,
      title: 'verification.step_id_verification',
      benefits: [
        'verification.benefit_unlimited_deposits',
        'verification.benefit_global_local_payments',
        'verification.benefit_withdrawals',
      ],
    ),
    const VerificationStep(
      index: 3,
      title: 'verification.step_bank_verification',
      benefits: [
        'verification.benefit_unlimited_deposits',
        'verification.benefit_global_local_payments',
        'verification.benefit_withdrawals',
      ],
    ),
  ].obs;

  /// Zero-based index of the step being viewed in the paged stepper.
  final currentStep = 0.obs;

  // --- Personal details form ------------------------------------------------
  final firstName = TextEditingController(text: 'John');
  final lastName = TextEditingController(text: 'Simmons');
  final email = TextEditingController(text: 'johnsimmons123@gmail.com');
  final phone = TextEditingController(text: '+91 8745961230');
  final address = TextEditingController();

  final Rxn<String> city = Rxn<String>();
  final Rxn<String> state = Rxn<String>();

  final cities = const [
    VerificationOption('mumbai', 'Mumbai'),
    VerificationOption('delhi', 'Delhi'),
    VerificationOption('bengaluru', 'Bengaluru'),
  ];
  final states = const [
    VerificationOption('mh', 'Maharashtra'),
    VerificationOption('dl', 'Delhi'),
    VerificationOption('ka', 'Karnataka'),
  ];

  /// Whether the phone number has passed OTP verification (drives the green
  /// check that replaces the "Send OTP" link in the design).
  final phoneVerified = false.obs;
  final sendingOtp = false.obs;
  final verifyingOtp = false.obs;

  // --- Document proofs ------------------------------------------------------
  final idFront = const ProofSlot(kind: ProofKind.idFront).obs;
  final idBack = const ProofSlot(kind: ProofKind.idBack).obs;
  final addressFront = const ProofSlot(kind: ProofKind.addressFront).obs;
  final addressBack = const ProofSlot(kind: ProofKind.addressBack).obs;

  // --- Navigation within the stepper ---------------------------------------
  bool get isFirstStep => currentStep.value == 0;
  bool get isLastStep => currentStep.value == steps.length - 1;

  /// True once every step is marked completed (drives final submit / exit).
  bool get allComplete =>
      steps.every((s) => s.status == VerificationStatus.completed);

  void nextStep() {
    if (!isLastStep) currentStep.value++;
  }

  void previousStep() {
    if (!isFirstStep) currentStep.value--;
  }

  /// Marks the step currently in view as completed and, unless it is the last
  /// one, advances to the next. Called when a sub-screen's form is saved so the
  /// stepper progresses one step at a time. Returns true when the whole journey
  /// is finished.
  bool completeCurrentStep() {
    final i = currentStep.value;
    steps[i] = steps[i].copyWith(status: VerificationStatus.completed);
    steps.refresh();
    if (!isLastStep) {
      currentStep.value++;
      return false;
    }
    return true;
  }

  // --- OTP (race-condition guarded) -----------------------------------------
  Future<void> sendOtp() async {
    if (sendingOtp.value || phoneVerified.value) return;
    sendingOtp.value = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));
    } finally {
      sendingOtp.value = false;
    }
  }

  Future<bool> verifyOtp(String code) async {
    if (verifyingOtp.value) return false;
    verifyingOtp.value = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      phoneVerified.value = true;
      return true;
    } finally {
      verifyingOtp.value = false;
    }
  }

  // --- Proof mutation -------------------------------------------------------
  /// Opens the gallery/file picker and stores the chosen image path in the
  /// matching slot. No-op if the user cancels.
  Future<void> pickProof(ProofKind kind) async {
    final picked = await FilePicker.pickFile(type: FileType.image);
    final path = picked?.path;
    if (path == null) return;
    final name = path.split('/').last;
    final slot = ProofSlot(kind: kind, fileName: name, filePath: path);
    switch (kind) {
      case ProofKind.idFront:
        idFront.value = slot;
      case ProofKind.idBack:
        idBack.value = slot;
      case ProofKind.addressFront:
        addressFront.value = slot;
      case ProofKind.addressBack:
        addressBack.value = slot;
      case ProofKind.bankProof:
        break;
    }
  }

  /// Uploads identity + address proofs in one `POST /kyc/documents` request —
  /// the API requires both fronts together. Returns true on success.
  Future<bool> uploadDocuments() async {
    if (uploadingDocs.value) return false;
    final idPath = idFront.value.filePath;
    final addressPath = addressFront.value.filePath;
    if (idPath == null || addressPath == null) {
      AppToast.error('kyc.docs_both_required'.tr);
      return false;
    }
    final idBackPath = idBack.value.filePath;
    final addressBackPath = addressBack.value.filePath;
    uploadingDocs.value = true;
    final res = await _repository.uploadDocuments(
      idDocument: File(idPath),
      idDocumentBack: idBackPath == null ? null : File(idBackPath),
      proofOfAddress: File(addressPath),
      proofOfAddressBack:
          addressBackPath == null ? null : File(addressBackPath),
    );
    uploadingDocs.value = false;
    return res.success;
  }

  /// Persists the personal-details form via `PUT /profile`. Returns true on
  /// success so the caller can advance the stepper.
  Future<bool> savePersonalDetails() async {
    if (savingPersonal.value) return false;
    savingPersonal.value = true;
    final res = await _repository.updateProfile({
      'first_name': firstName.text.trim(),
      'last_name': lastName.text.trim(),
      'phone': phone.text.trim(),
      if (city.value != null) 'city': city.value,
      if (state.value != null) 'state': state.value,
      'address': address.text.trim(),
    });
    savingPersonal.value = false;
    return res.success;
  }

  @override
  void onClose() {
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    phone.dispose();
    address.dispose();
    super.onClose();
  }
}
