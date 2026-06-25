/// API configuration — no secrets here. Set at build time:
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:6969 --dart-define=APP_SECRET=your_secret
///
/// Android emulator: use http://10.0.2.2:6969 (maps to host localhost).
/// Physical device: use your PC's LAN IP, e.g. http://192.168.1.5:6969
/// iOS simulator: http://127.0.0.1:6969
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
