/// Error mapped from the API envelope `{ "error": { code, message, details } }`.
class ApiException implements Exception {
  final int? statusCode;
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  const ApiException({
    this.statusCode,
    required this.code,
    required this.message,
    this.details,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isFeatureDisabled => code == 'FEATURE_DISABLED';
  bool get isSocietySuspended => code == 'SOCIETY_SUSPENDED';
  bool get isNetwork => code == 'NETWORK';

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
