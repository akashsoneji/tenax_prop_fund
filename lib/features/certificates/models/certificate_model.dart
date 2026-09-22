/// Data models for the Certificates feature.
///
/// Mirrors `GET /growth/certificates` (list + `earned_count`) and
/// `GET /growth/certificates/{id}/download` (the rendered document the viewer
/// loads into its WebView). Parsing only — no logic beyond `fromJson`.
library;

class Certificate {
  const Certificate({
    required this.id,
    required this.slug,
    required this.name,
    required this.blurb,
    required this.criteria,
    required this.type,
    required this.earned,
    this.downloadUrl,
  });

  final int id;
  final String slug;
  final String name;
  final String blurb;
  final List<String> criteria;
  final String type;
  final bool earned;

  /// Absolute portal URL for the printable page. The app fetches the document
  /// through `ApiEndpoints.certificateDownload(id)` instead, so this is only
  /// kept as the backend's own reference.
  final String? downloadUrl;

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: (json['id'] as num?)?.toInt() ?? 0,
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      blurb: json['blurb'] as String? ?? '',
      criteria: (json['criteria'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      type: json['type'] as String? ?? '',
      earned: json['earned'] as bool? ?? false,
      downloadUrl: json['download_url'] as String?,
    );
  }
}

/// The Certificates screen payload: the list plus the server's earned tally.
class CertificatesData {
  const CertificatesData({
    required this.certificates,
    required this.earnedCount,
  });

  final List<Certificate> certificates;
  final int earnedCount;

  factory CertificatesData.fromJson(Map<String, dynamic> json) {
    final list = (json['certificates'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(Certificate.fromJson)
            .toList() ??
        const <Certificate>[];
    return CertificatesData(
      certificates: list,
      earnedCount: (json['earned_count'] as num?)?.toInt() ??
          list.where((c) => c.earned).length,
    );
  }
}

/// A single rendered certificate document. [html] is a complete standalone
/// page the viewer hands to the WebView as initial data.
class CertificateDocument {
  const CertificateDocument({
    required this.name,
    required this.holder,
    required this.verificationCode,
    required this.format,
    required this.html,
    this.issuedAt,
  });

  final String name;
  final String holder;
  final String verificationCode;
  final String format;
  final String html;
  final DateTime? issuedAt;

  factory CertificateDocument.fromJson(Map<String, dynamic> json) {
    return CertificateDocument(
      name: json['name'] as String? ?? '',
      holder: json['holder'] as String? ?? '',
      verificationCode: json['verification_code'] as String? ?? '',
      format: json['format'] as String? ?? 'html',
      html: json['html'] as String? ?? '',
      issuedAt: DateTime.tryParse(json['issued_at'] as String? ?? ''),
    );
  }
}
