import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  PasswordHasher._();

  /// Salts and hashes a password using SHA-256
  static String hash(String password, {String salt = 'llis_pcso_secret_salt_2026'}) {
    final bytes = utf8.encode('$salt:$password');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies if plaintext password matches hash
  static bool verify(String password, String hashValue, {String salt = 'llis_pcso_secret_salt_2026'}) {
    return hash(password, salt: salt) == hashValue;
  }
}
