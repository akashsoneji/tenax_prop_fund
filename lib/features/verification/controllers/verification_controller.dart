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
      title: 'Personal Details',
      benefits: [
        'Deposit up to \$2000 within 14 days',
        'Limited deposit methods',
        'Live & demo trading',
      ],
      status: VerificationStatus.completed,
    ),
    const VerificationStep(
      index: 2,
      title: 'ID Verification',
      benefits: [
        'Unlimited deposits',
        'Global and local payments',
        'Withdrawals',
      ],
    ),
    const VerificationStep(
      index: 3,
      title: 'Bank Verification',
      benefits: [
        'Unlimited deposits',
        'Global and local payments',
        'Withdrawals',
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

  /// Uploads the selected ID and address proofs to the PROPCRM API (one request
  /// per document type). Returns true when every attempted upload succeeded.
  Future<bool> uploadDocuments() async {
    if (uploadingDocs.value) return false;
    final idPath = idFront.value.filePath;
    final addressPath = addressFront.value.filePath;
    if (idPath == null && addressPath == null) {
      AppToast.error('kyc.docs_select_first'.tr);
      return false;
    }
    uploadingDocs.value = true;
    var ok = true;
    if (idPath != null) {
      final res = await _repository.uploadDocument(
        documentType: 'id_proof',
        front: File(idPath),
        back: idBack.value.filePath == null
            ? null
            : File(idBack.value.filePath!),
      );
      ok = res.success;
    }
    if (ok && addressPath != null) {
      final res = await _repository.uploadDocument(
        documentType: 'address_proof',
        front: File(addressPath),
        back: addressBack.value.filePath == null
            ? null
            : File(addressBack.value.filePath!),
      );
      ok = res.success;
    }
    uploadingDocs.value = false;
    return ok;
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
