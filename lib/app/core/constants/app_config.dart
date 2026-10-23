/// Build-time configuration. Override with:
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
abstract class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
  static const String apiV1 = '$apiBaseUrl/api/v1';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
