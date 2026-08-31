import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../models/user_model.dart';
import 'backend_service.dart';
import 'progresso_service.dart';
import 'session_service.dart';
import 'user_service.dart';

/// Fronteira unica para os direitos de acesso/exportacao e exclusao da LGPD.
abstract final class AccountDataService {
  static Future<String> exportAsJson(User user) async {
    final remote = await _exportRemoteData();
    if (user.id == null) {
      final profile = Map<String, dynamic>.from(user.toMap())
        ..remove('password');
      return const JsonEncoder.withIndent('  ').convert({
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'source': 'local-session',
        'data': {
          'local': {'profile': profile},
          'institutional': remote,
        },
      });
    }

    final data = await AppDatabase.instance.exportUserData(user.id!);
    return const JsonEncoder.withIndent('  ').convert({
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'source': 'local-device',
      'data': {'local': data, 'institutional': remote},
    });
  }

  static Future<Map<String, dynamic>?> _exportRemoteData() async {
    final backend = BackendService.instance;
    final authUser = backend.isInitialized
        ? backend.client.auth.currentUser
        : null;
    if (authUser == null) return null;

    final profile = await backend.client
        .from('profiles')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();
    final memberships = await backend.client
        .from('school_memberships')
        .select('school_id, role, status, login_alias, created_at')
        .eq('user_id', authUser.id);
    final enrollments = await backend.client
        .from('student_enrollments')
        .select('classroom_id, active, created_at')
        .eq('student_id', authUser.id);
    final sessions = await backend.client
        .from('quiz_sessions')
        .select()
        .eq('student_id', authUser.id);
    final sessionIds = sessions
        .map((session) => session['id'] as String)
        .toList(growable: false);
    final attempts = sessionIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await backend.client
              .from('question_attempts')
              .select()
              .inFilter('quiz_session_id', sessionIds);
    final progress = await backend.client
        .from('student_progress')
        .select()
        .eq('student_id', authUser.id);
    final consents = await backend.client
        .from('consent_records')
        .select()
        .eq('student_id', authUser.id);

    return {
      'auth': {'id': authUser.id, 'email': authUser.email},
      'profile': profile,
      'memberships': memberships,
      'enrollments': enrollments,
      'quizSessions': sessions,
      'questionAttempts': attempts,
      'progress': progress,
      'consentRecords': consents,
    };
  }

  static Future<void> deleteAccount(User user) async {
    if (BackendService.instance.isInitialized &&
        BackendService.instance.client.auth.currentUser != null) {
      final response = await BackendService.instance.client.functions.invoke(
        'delete-account',
      );
      if (response.status < 200 || response.status >= 300) {
        throw StateError('O servidor nao confirmou a exclusao da conta.');
      }
    }

    if (user.id != null) {
      final deleted = await AppDatabase.instance.deleteUser(user.id!);
      if (deleted != 1) {
        throw StateError('A conta local nao foi encontrada para exclusao.');
      }
    }

    await _deleteManagedProfilePhoto(user.profilePhotoPath);
    await _removeUserPreferences(user.username);
    ProgressoService().removeUserData(user.username);
    UserService().removeUser(user.username);
    await SessionService.logout();
  }

  static Future<void> _removeUserPreferences(String username) async {
    final preferences = await SharedPreferences.getInstance();
    final exactKeys = <String>{
      'usuario_id',
      'usuario_nome',
      'usuario_grade',
      'avatar_$username',
      'celebration.$username',
    };
    final prefixes = <String>[
      'daily_mission_claimed_${username}_',
      'topico_em_andamento_${username}_',
      'quiz_progress_${username}_',
    ];

    for (final key in preferences.getKeys().toList()) {
      if (exactKeys.contains(key) || prefixes.any(key.startsWith)) {
        await preferences.remove(key);
      }
    }
  }

  static Future<void> _deleteManagedProfilePhoto(String? photoPath) async {
    if (photoPath == null || photoPath.trim().isEmpty) return;
    final file = File(photoPath);
    if (!await file.exists()) return;

    final roots = <Directory>[
      await getApplicationDocumentsDirectory(),
      await getApplicationSupportDirectory(),
      await getTemporaryDirectory(),
    ];
    final normalizedFile = path.normalize(file.absolute.path);
    final isManaged = roots.any((root) {
      final normalizedRoot = path.normalize(root.absolute.path);
      return path.isWithin(normalizedRoot, normalizedFile);
    });
    if (isManaged) await file.delete();
  }
}
