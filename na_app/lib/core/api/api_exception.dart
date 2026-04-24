class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;

  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  factory ApiException.fromMap(Map<String, dynamic> map) {
    return ApiException(
      statusCode: map['statusCode'] as int? ?? 0,
      code: map['code'] as String? ?? 'UNKNOWN',
      message: map['message'] as String? ?? 'An unexpected error occurred.',
    );
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isRateLimited => statusCode == 429;
  bool get isGone => statusCode == 410;
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
