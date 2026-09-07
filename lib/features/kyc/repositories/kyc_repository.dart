import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/kyc_profile.dart';

/// Single source of truth for the Profile & KYC screen. Currently returns
/// static demo data (no live API call). The controller and view do not change —
/// they still consume an `ApiResponse<KycProfile>`.
class KycRepository {
  KycRepository(this._api);

  // ignore: unused_field
  final ApiClient _api;

  Future<ApiResponse<KycProfile>> getProfile() {
    return Future.value(ApiResponse.success(_demoProfile));
  }

  static const KycProfile _demoProfile = KycProfile(
    name: 'Akash Mehta',
    since: 'IN',
    avatarUrl: '',
    steps: [
      KycVerificationStep(
        title: 'Email confirmed',
        subtitle: 'akash.mehta@example.com',
        status: KycStepStatus.done,
      ),
      KycVerificationStep(
        title: 'Identity document',
        subtitle: 'Passport or national ID',
        status: KycStepStatus.done,
      ),
      KycVerificationStep(
        title: 'Proof of address',
        subtitle: 'Bank statement or bill, under 3 months',
        status: KycStepStatus.pending,
      ),
    ],
    details: [
      KycDetailRow(
        icon: Icons.person_outline_rounded,
        label: 'Full name',
        value: 'Akash Mehta',
      ),
      KycDetailRow(
        icon: Icons.calendar_today_outlined,
        label: 'Date of birth',
        value: '14 Aug 1994',
      ),
      KycDetailRow(
        icon: Icons.public_rounded,
        label: 'Country',
        value: 'India',
      ),
      KycDetailRow(
        icon: Icons.smartphone_rounded,
        label: 'Mobile',
        value: '+91 90000 00001',
      ),
      KycDetailRow(
        icon: Icons.mail_outline_rounded,
        label: 'Email',
        value: 'akash.mehta@example.com',
      ),
    ],
    alerts: [
      KycAlertRow(label: 'Impact level', value: 'High only'),
      KycAlertRow(label: 'Currency pairs', value: '5 selected'),
      KycAlertRow(label: 'Alert timing', value: '15 minutes before'),
      KycAlertRow(label: 'Channels', value: 'Push and email'),
      KycAlertRow(label: 'Pause alerts', value: 'Off'),
    ],
  );
}
