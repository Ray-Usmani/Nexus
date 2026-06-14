/// API configuration — no secrets here. Set at build time:
/// flutter run --dart-define=API_BASE_URL=https://your-app.onrender.com
class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const appSecret = String.fromEnvironment(
    'APP_SECRET',
    defaultValue: '',
  );

  static bool get isConfigured => baseUrl.isNotEmpty;
}
