enum ActivationErrorReason {
  invalid,
  expired,
  alreadyUsed,
  deviceMismatch,
  rateLimited,
}

sealed class ActivationResult {}

class ActivationSuccess extends ActivationResult {
  final String codeType;
  final String targetId;
  final String? subjectTitle;
  final String? examTitle;

  ActivationSuccess({
    required this.codeType,
    required this.targetId,
    this.subjectTitle,
    this.examTitle,
  });
}

class ActivationFailure extends ActivationResult {
  final ActivationErrorReason reason;
  final DateTime? expiredAt;
  final DateTime? consumedAt;
  final Duration? retryAfter;

  ActivationFailure({
    required this.reason,
    this.expiredAt,
    this.consumedAt,
    this.retryAfter,
  });
}
