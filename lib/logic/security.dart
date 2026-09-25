import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';

/// Verrouillage de l'application : code PIN + empreinte digitale.
///
/// Le sel et l'empreinte du PIN sont dans le stockage sécurisé du système
/// (Keystore / Keychain). Les drapeaux « PIN actif » et « empreinte active »
/// sont dupliqués dans la box `settings` pour décider de l'écran d'accueil
/// sans appel asynchrone. Sans box `settings` (tests), rien n'est verrouillé.
// ponytail: PIN de 6 chiffres haché en SHA-256 salé, protégé par le stockage
// sécurisé ; pour résister à une extraction hors-ligne, passer à PBKDF2/argon2.
class Security {
  static const pinLength = 6;
  static const _storage = FlutterSecureStorage();
  static final _auth = LocalAuthentication();

  static Box<String>? get _settings =>
      Hive.isBoxOpen('settings') ? Hive.box<String>('settings') : null;

  static bool get pinEnabled => _settings?.get('pin_enabled') == '1';
  static bool get biometricEnabled =>
      pinEnabled && _settings?.get('biometric') == '1';

  static String _hash(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  static Future<void> setPin(String pin) async {
    final random = Random.secure();
    final salt =
        base64UrlEncode(List<int>.generate(16, (_) => random.nextInt(256)));
    await _storage.write(key: 'pin_salt', value: salt);
    await _storage.write(key: 'pin_hash', value: _hash(salt, pin));
    await _settings?.put('pin_enabled', '1');
  }

  static Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: 'pin_salt');
    final hash = await _storage.read(key: 'pin_hash');
    if (salt == null || hash == null) {
      // Stockage sécurisé vidé (réinstallation, réinitialisation du
      // système) : impossible de vérifier, on lève le verrou plutôt que de
      // bloquer définitivement l'utilisateur hors de ses données.
      await removePin();
      return true;
    }
    return _hash(salt, pin) == hash;
  }

  static Future<void> removePin() async {
    await _storage.delete(key: 'pin_salt');
    await _storage.delete(key: 'pin_hash');
    await _settings?.delete('pin_enabled');
    await _settings?.delete('biometric');
  }

  static Future<bool> biometricAvailable() async {
    try {
      return await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticateBiometric(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<void> setBiometric(bool enabled) async {
    await _settings?.put('biometric', enabled ? '1' : '0');
  }
}
