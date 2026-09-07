/// Data model for the Certificates screen.
///
/// Each certificate is an achievement the trader can unlock. Some show a
/// progress bar (with a 0..1 [progress]); others are simple locked/earned
/// badges. Static demo content for now — swap the controller's seed for a
/// repository call later without touching the model or the view.
library;

/// Whether a certificate has been earned yet.
enum CertificateStatus { locked, earned }

class Certificate {
  const Certificate({
    required this.title,
    required this.description,
    required this.status,
    this.progress,
  });

  final String title;
  final String description;
  final CertificateStatus status;

  /// 0..1 completion. `null` means the card shows no progress bar.
  final double? progress;

  bool get hasProgress => progress != null;

  factory Certificate.fromJson(Map<String, dynamic> json) {
    final earned = json['earned'] as bool? ??
        (json['status'] as String?)?.toLowerCase() == 'earned';
    final rawProgress = json['progress'];
    return Certificate(
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: earned ? CertificateStatus.earned : CertificateStatus.locked,
      progress: rawProgress == null
          ? null
          : (rawProgress as num).toDouble(),
    );
  }
}
