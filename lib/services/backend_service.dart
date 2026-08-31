import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/backend_config.dart';

/// Inicializa o backend sem impedir o uso local do aplicativo de demonstracao.
class BackendService {
  BackendService._();

  static final BackendService instance = BackendService._();

  bool _initialized = false;

  bool get isConfigured => BackendConfig.isConfigured;
  bool get isInitialized => _initialized;

  SupabaseClient get client {
    if (!_initialized) {
      throw StateError('Backend Supabase nao inicializado.');
    }
    return Supabase.instance.client;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    if (!isConfigured) {
      if (BackendConfig.isRequired) {
        throw StateError(
          'Backend obrigatorio, mas SUPABASE_URL ou '
          'SUPABASE_PUBLISHABLE_KEY nao foi informado.',
        );
      }
      if (kDebugMode) {
        debugPrint(
          'SQEducaPlay: modo local de demonstracao; backend nao configurado.',
        );
      }
      return;
    }

    try {
      await Supabase.initialize(
        url: BackendConfig.supabaseUrl,
        publishableKey: BackendConfig.supabasePublishableKey,
        debug: kDebugMode,
      );
      _initialized = true;
    } catch (error, stackTrace) {
      // Nesta fase o aplicativo ainda possui armazenamento local. A falha de
      // rede nao deve bloquear atividades offline, mas precisa ser observavel.
      debugPrint('Falha ao inicializar o backend: $error\n$stackTrace');
      if (BackendConfig.isRequired) rethrow;
    }
  }
}
