import 'package:flutter/material.dart';

import 'kyc_status.dart';

/// Status of a single verification step in the KYC checklist.
enum KycStepStatus { done, pending }

/// One row in the "Verification" checklist (email, identity, address).
class KycVerificationStep {
  const KycVerificationStep({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final String title;
  final String subtitle;
  final KycStepStatus status;

  bool get isDone => status == KycStepStatus.done;
}

/// A labelled row inside the gradient "Personal details" card.
class KycDetailRow {
  const KycDetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;
}

/// A row in the "News alerts" preferences list.
class KycAlertRow {
  const KycAlertRow({required this.label, required this.value});

  final String label;
  final String value;
}

/// Immutable snapshot of the whole Profile & KYC screen.
class KycProfile {
  const KycProfile({
    required this.name,
    required this.since,
    required this.avatarUrl,
    required this.steps,
    required this.details,
    required this.alerts,
  });

  final String name;
  final String since;
  final String avatarUrl;
  final List<KycVerificationStep> steps;
  final List<KycDetailRow> details;
  final List<KycAlertRow> alerts;

  int get doneCount => steps.where((s) => s.isDone).length;
  int get totalCount => steps.length;

  /// Maps the live `GET /profile` envelope `data` into the screen model. Fields
  /// with no API source (avatar, date of birth, identity/address step state,
  /// news-alert prefs) are defaulted sensibly and preserved for the views.
  factory KycProfile.fromJson(Map<String, dynamic> json, {KycStatus? kyc}) {
    final name = (json['name'] as String?)?.trim() ?? '';
    final first = (json['first_name'] as String?)?.trim() ?? '';
    final last = (json['last_name'] as String?)?.trim() ?? '';
    final fullName = name.isNotEmpty
        ? name
        : [first, last].where((s) => s.isNotEmpty).join(' ');
    final email = (json['email'] as String?) ?? '';
    final phone = (json['phone'] as String?) ?? '';
    final country = (json['country_code'] as String?) ?? '';
    final emailVerified = json['email_verified'] as bool? ?? false;

    return KycProfile(
      name: fullName,
      since: country,
      avatarUrl: '',
      steps: [
        KycVerificationStep(
          title: 'Email confirmed',
          subtitle: email,
          status: emailVerified ? KycStepStatus.done : KycStepStatus.pending,
        ),
        KycVerificationStep(
          title: 'Identity document',
          subtitle: 'Passport or national ID',
          status: kyc?.identity == KycDocState.approved
              ? KycStepStatus.done
              : KycStepStatus.pending,
        ),
        KycVerificationStep(
          title: 'Proof of address',
          subtitle: 'Bank statement or bill, under 3 months',
          status: kyc?.address == KycDocState.approved
              ? KycStepStatus.done
              : KycStepStatus.pending,
        ),
      ],
      details: [
        KycDetailRow(
            icon: Icons.person_outline_rounded,
            label: 'Full name',
            value: fullName),
        const KycDetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date of birth',
            value: ''),
        KycDetailRow(
            icon: Icons.public_rounded, label: 'Country', value: country),
        KycDetailRow(
            icon: Icons.smartphone_rounded, label: 'Mobile', value: phone),
        KycDetailRow(
            icon: Icons.mail_outline_rounded, label: 'Email', value: email),
      ],
      alerts: const [
        KycAlertRow(label: 'Impact level', value: 'High only'),
        KycAlertRow(label: 'Currency pairs', value: '5 selected'),
        KycAlertRow(label: 'Alert timing', value: '15 minutes before'),
        KycAlertRow(label: 'Channels', value: 'Push and email'),
        KycAlertRow(label: 'Pause alerts', value: 'Off'),
      ],
    );
  }
}
