import 'package:flutter/foundation.dart';

class Logger {
  /// Registra mensagens apenas em modo debug. Em build release isso não faz nada.
  static void d(Object? message) {
    if (kDebugMode) {
      // Importante: debugPrint está disponível via foundation
      // Use print como fallback se necessário
      try {
        // ignore: avoid_print
        debugPrint(message?.toString());
      } catch (_) {
        // ignore: avoid_print
        print(message);
      }
    }
  }
}
