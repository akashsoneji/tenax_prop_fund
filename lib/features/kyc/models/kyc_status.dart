/// Verification state for a single KYC document slot, returned by `GET /kyc`.
enum KycDocState { notSubmitted, pending, approved, rejected }

KycDocState kycDocStateFromString(String? raw) {
  switch (raw?.toLowerCase().trim()) {
    case 'pending':
    case 'submitted':
    case 'in_review':
    case 'under_review':
      return KycDocState.pending;
    case 'approved':
    case 'verified':
    case 'accepted':
      return KycDocState.approved;
    case 'rejected':
    case 'declined':
      return KycDocState.rejected;
    default:
      return KycDocState.notSubmitted;
  }
}

/// The four document slots the TenaxProp API accepts on `POST /kyc/documents`.
enum KycDocSlot { idDocument, idDocumentBack, proofOfAddress, proofOfAddressBack }

extension KycDocSlotField on KycDocSlot {
  /// The multipart field name expected by `POST /kyc/documents`.
  String get field {
    switch (this) {
      case KycDocSlot.idDocument:
        return 'id_document';
      case KycDocSlot.idDocumentBack:
        return 'id_document_back';
      case KycDocSlot.proofOfAddress:
        return 'proof_of_address';
      case KycDocSlot.proofOfAddressBack:
        return 'proof_of_address_back';
    }
  }
}

/// Snapshot of the user's KYC verification, parsed from the `GET /kyc`
/// envelope's `data`. Parsing is deliberately tolerant: the backend may expose
/// either a flat status map or a `documents` list keyed by document type.
class KycStatus {
  const KycStatus({
    required this.identity,
    required this.address,
    this.overall,
  });

  final KycDocState identity;
  final KycDocState address;

  /// Overall verification state when the API reports one at the top level.
  final KycDocState? overall;

  bool get isVerified =>
      overall == KycDocState.approved ||
      (identity == KycDocState.approved && address == KycDocState.approved);

  static const empty = KycStatus(
    identity: KycDocState.notSubmitted,
    address: KycDocState.notSubmitted,
  );

  factory KycStatus.fromJson(dynamic data) {
    if (data is! Map<String, dynamic>) return empty;

    final overall = data['status'] ?? data['kyc_status'] ?? data['state'];

    // Shape A: a `documents` list, each entry carrying `type` + `status`.
    final docs = data['documents'];
    if (docs is List) {
      KycDocState identity = KycDocState.notSubmitted;
      KycDocState address = KycDocState.notSubmitted;
      for (final entry in docs) {
        if (entry is! Map) continue;
        final type = (entry['type'] ?? entry['document_type'] ?? '')
            .toString()
            .toLowerCase();
        final state = kycDocStateFromString(entry['status']?.toString());
        if (type.contains('id') || type.contains('identity')) {
          identity = state;
        } else if (type.contains('address')) {
          address = state;
        }
      }
      return KycStatus(
        identity: identity,
        address: address,
        overall: overall == null
            ? null
            : kycDocStateFromString(overall.toString()),
      );
    }

    // Shape B: flat per-document status fields.
    return KycStatus(
      identity: kycDocStateFromString(
        (data['id_document'] ?? data['identity'] ?? data['identity_status'])
            ?.toString(),
      ),
      address: kycDocStateFromString(
        (data['proof_of_address'] ?? data['address'] ?? data['address_status'])
            ?.toString(),
      ),
      overall:
          overall == null ? null : kycDocStateFromString(overall.toString()),
    );
  }
}
