import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// API configuration — set at build time for release:
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:6969 --dart-define=APP_SECRET=your_secret
///
/// Android emulator: http://10.0.2.2:6969 (maps to host localhost).
/// Physical device (same Wi‑Fi): http://<your-pc-lan-ip>:6969
/// Physical device (USB): run `adb reverse tcp:6969 tcp:6969` then use http://127.0.0.1:6969
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

  static String? _runtimeBaseUrl;
  static String? _runtimeAppSecret;

  /// Overrides from in-app Settings (takes priority over dart-define).
  static void applyRuntime({String? baseUrl, String? appSecret}) {
    final trimmedUrl = baseUrl?.trim();
    final trimmedSecret = appSecret?.trim();
    _runtimeBaseUrl = (trimmedUrl != null && trimmedUrl.isNotEmpty) ? trimmedUrl : null;
    _runtimeAppSecret = (trimmedSecret != null && trimmedSecret.isNotEmpty) ? trimmedSecret : null;
  }

  static String get effectiveBaseUrl {
    if (_runtimeBaseUrl != null && _runtimeBaseUrl!.isNotEmpty) return _runtimeBaseUrl!;
    if (baseUrl.isNotEmpty) return baseUrl;
    if (kDebugMode) {
      if (Platform.isAndroid) return 'http://10.0.2.2:6969';
      return 'http://127.0.0.1:6969';
    }
    return '';
  }

  static String get effectiveAppSecret {
    if (_runtimeAppSecret != null && _runtimeAppSecret!.isNotEmpty) return _runtimeAppSecret!;
    return appSecret;
  }

  static bool get isConfigured => effectiveBaseUrl.isNotEmpty;

  /// True when dart-define points at the emulator alias on a real device.
  static bool get likelyWrongHostForPhysicalDevice =>
      kDebugMode &&
      Platform.isAndroid &&
      (effectiveBaseUrl.contains('10.0.2.2') || effectiveBaseUrl.contains('localhost'));
}
