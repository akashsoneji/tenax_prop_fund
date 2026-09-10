/// Completion state of a single verification step (Personal / ID / Bank).
enum VerificationStatus { completed, incomplete }

extension VerificationStatusX on VerificationStatus {
  bool get isCompleted => this == VerificationStatus.completed;
}

/// One step in the "Verify your account" journey. Drives both the overview
/// list and the paged stepper header.
class VerificationStep {
  const VerificationStep({
    required this.index,
    required this.title,
    required this.benefits,
    this.status = VerificationStatus.incomplete,
  });

  /// 1-based step number shown as "01", "02", "03".
  final int index;
  final String title;
  final List<String> benefits;
  final VerificationStatus status;

  String get numberLabel => index.toString().padLeft(2, '0');

  VerificationStep copyWith({VerificationStatus? status}) => VerificationStep(
        index: index,
        title: title,
        benefits: benefits,
        status: status ?? this.status,
      );
}

/// A labelled option for the account-type / currency / IBAN dropdowns.
class VerificationOption {
  const VerificationOption(this.value, this.label);
  final String value;
  final String label;
}

/// Kinds of document upload slots used across the flow.
enum ProofKind { idFront, idBack, addressFront, addressBack, bankProof }

/// Immutable snapshot of an upload slot (design shows a filled gradient tile
/// when populated and a faint tile when empty).
class ProofSlot {
  const ProofSlot({required this.kind, this.fileName, this.filePath});
  final ProofKind kind;
  final String? fileName;

  /// Absolute path of the picked file (null until the user selects one).
  final String? filePath;

  bool get isFilled => filePath != null || fileName != null;
}
