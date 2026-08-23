import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PasswordUtils {
  static const int saltLength = 16;

  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(
      saltLength,
      (_) => random.nextInt(256),
    );

    return base64UrlEncode(bytes);
  }

  static String hashPassword(String password, {String? salt}) {
    final usedSalt = salt ?? generateSalt();

    final bytes = utf8.encode('$usedSalt:$password');
    final digest = sha256.convert(bytes);

    return '$usedSalt\$${digest.toString()}';
  }

  static bool verifyPassword(String password, String storedHash) {
    try {
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

  static bool isValidPassword(String password) {
    if (password.length < 8) {
      return false;
    }

    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);

    return hasLetter && hasNumber;
  }
}