import 'package:shared_preferences/shared_preferences.dart';

class CelebrationService {
  static final CelebrationService _instance = CelebrationService._internal();
  factory CelebrationService() => _instance;
  CelebrationService._internal();

  // Chave: username -> set de chaves de conquistas reconhecidas
  // Persistimos somente timestamps das últimas conquistas vistas
  Future<Set<String>> _loadAcknowledged(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('celebration.$username') ?? const <String>[];
    return list.toSet();
  }

  Future<void> _saveAcknowledged(String username, Set<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('celebration.$username', keys.toList());
  }

  Future<List<String>> getNewlyUnlockedKeys(String username, Iterable<String> unlockedKeys) async {
    final ack = await _loadAcknowledged(username);
    final newOnes = unlockedKeys.where((k) => !ack.contains(k)).toList();
    return newOnes;
  }

  Future<void> acknowledge(String username, Iterable<String> keys) async {
    final ack = await _loadAcknowledged(username);
    ack.addAll(keys);
    await _saveAcknowledged(username, ack);
  }
}
