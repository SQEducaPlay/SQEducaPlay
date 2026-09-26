import 'package:shared_preferences/shared_preferences.dart';

import 'backend_service.dart';
import 'progresso_service.dart';
import 'user_service.dart';

/// Mantem o encerramento de sessao em uma unica fronteira.
abstract final class SessionService {
  static const _identityKeys = <String>{
    'usuario_id',
    'usuario_nome',
    'usuario_grade',
  };

  static Future<void> logout() async {
    if (BackendService.instance.isInitialized) {
      try {
        await BackendService.instance.client.auth.signOut();
      } catch (_) {
        // A sessao local deve ser encerrada mesmo sem rede ou apos a conta
        // remota ja ter sido removida.
      }
    }

    UserService().clearCurrentUser();
    ProgressoService().setRemoteStudentScope(null);
    final preferences = await SharedPreferences.getInstance();
    for (final key in _identityKeys) {
      await preferences.remove(key);
    }
  }
}
