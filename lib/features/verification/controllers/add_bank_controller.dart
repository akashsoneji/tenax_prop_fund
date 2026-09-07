import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/verification_models.dart';

/// Drives the "Add bank" screen. Owns its form controllers and disposes them
/// in [onClose]. The OTP send is guarded by [sendingOtp] so a rapid double-tap
/// cannot launch two requests.
class AddBankController extends GetxController {
  final accountHolder = TextEditingController(text: 'John Simmons');
  final beneficiaryBank = TextEditingController(text: 'David');
  final accountNumber = TextEditingController();
  final confirmAccountNumber = TextEditingController();
  final swiftCode = TextEditingController();

  final Rxn<String> accountType = Rxn<String>('bank');
  final Rxn<String> currency = Rxn<String>('eur');
  final Rxn<String> ibanType = Rxn<String>();
  final Rxn<String> code = Rxn<String>();

  final proof = const ProofSlot(kind: ProofKind.bankProof).obs;
  final sendingOtp = false.obs;

  final accountTypes = const [
    VerificationOption('bank', 'Bank'),
    VerificationOption('wallet', 'E-wallet'),
  ];
  final currencies = const [
    VerificationOption('eur', 'Euro'),
    VerificationOption('usd', 'US Dollar'),
    VerificationOption('gbp', 'British Pound'),
  ];
  final ibanTypes = const [
    VerificationOption('iban', 'IBAN'),
    VerificationOption('ifsc', 'IFSC'),
  ];

  bool get accountNumbersMatch =>
      accountNumber.text.isNotEmpty &&
      accountNumber.text == confirmAccountNumber.text;

  void pickProof() {
    proof.value = const ProofSlot(kind: ProofKind.bankProof, fileName: 'proof.jpg');
  }

  Future<void> sendOtp() async {
    if (sendingOtp.value) return;
    sendingOtp.value = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));
    } finally {
      sendingOtp.value = false;
    }
  }

  @override
  void onClose() {
    accountHolder.dispose();
    beneficiaryBank.dispose();
    accountNumber.dispose();
    confirmAccountNumber.dispose();
    swiftCode.dispose();
    super.onClose();
  }
}
