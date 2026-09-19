import 'dart:convert';
import 'dart:math';

import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';

class PasswordUtils {
  static const int saltLength = 16;

  static bool isBcryptHash(String value) {
    return value.startsWith(r'$2a$') ||
        value.startsWith(r'$2b$') ||
        value.startsWith(r'$2y$');
  }

  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(
      saltLength,
      (_) => random.nextInt(256),
    );

    return base64UrlEncode(bytes);
  }

  static String hashPassword(String password, {String? salt}) {
    if (salt == null) {
      return BCrypt.hashpw(password, BCrypt.gensalt());
    }

    final usedSalt = salt;

    final bytes = utf8.encode('$usedSalt:$password');
    final digest = sha256.convert(bytes);

    return '$usedSalt\$${digest.toString()}';
  }

  static bool verifyPassword(String password, String storedHash) {
    try {
      if (isBcryptHash(storedHash)) {
        return BCrypt.checkpw(password, storedHash);
      }

      // Compatibilidade temporária com hashes SHA-256 produzidos por versões
      // anteriores. Novos registros sempre usam bcrypt.
      final parts = storedHash.split('\$');

      if (parts.length != 2) {
        return false;
      }

      final salt = parts[0];
      final expectedHash = hashPassword(
        password,
        salt: salt,
      );

      return expectedHash == storedHash;
    } catch (_) {
      return false;
    }

  }

  static bool needsRehash(String storedHash) => !isBcryptHash(storedHash);

  static bool isLegacySha256Hash(String value) {
    final parts = value.split('\$');
    return parts.length == 2 &&
        parts[1].length == 64 &&
        RegExp(r'^[a-f0-9]{64}$').hasMatch(parts[1]);
  }

  static bool isValidPassword(String password) {
    if (password.length < 8) {
      return false;
    }

    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);

    return hasLetter && hasNumber;
  }
}