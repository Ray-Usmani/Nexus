import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _auth = LocalAuthentication();

  Future<bool> canUseBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (e, stack) {
      debugPrint('Biometric check failed: $e');
      debugPrint('$stack');
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'Unlock SpendWise'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e, stack) {
      debugPrint('Biometric auth failed: $e');
      debugPrint('$stack');
      return false;
    }
  }
}
