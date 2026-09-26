import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../database/app_database.dart';
import '../models/user_model.dart';
import 'backend_service.dart';
import 'password_service.dart';

abstract final class RemoteSyncService {
  static SupabaseClient get _client => BackendService.instance.client;

  static String createClientSessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  static Future<List<Map<String, dynamic>>> listChildren() async {
    final guardianId = _client.auth.currentUser?.id;
    if (guardianId == null) {
      throw StateError('A sessão do responsável expirou.');
    }
    final rows = await _client
        .from('student_profiles')
        .select('id, username, full_name, nickname, grade, status')
        .eq('guardian_id', guardianId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<List<Map<String, dynamic>>> listActiveSchools() async {
    final rows = await _client
        .from('schools')
        .select('id, name')
        .eq('active', true)
        .order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<String> createStudent({
    required String username,
    required String fullName,
    String? nickname,
    required String grade,
    required String consentVersion,
    String? schoolId,
  }) async {
    final result = await _client.rpc(
      'create_student_profile',
      params: {
        'p_username': username,
        'p_full_name': fullName,
        'p_nickname': nickname,
        'p_grade': grade,
        'p_school_id': schoolId,
        'p_consent_version': consentVersion,
      },
    );
    return result as String;
  }

  static Future<User> activateStudent(Map<String, dynamic> child) async {
    final id = child['id'] as String;
    final status = child['status'] as String? ?? 'pending';
    final localUser = await AppDatabase.instance.getOrCreateRemoteStudent(
      remoteStudentId: id,
      username: child['username'] as String,
      fullName: child['full_name'] as String,
      nickname: child['nickname'] as String?,
      grade: child['grade'] as String,
      isApproved: status == 'active',
    );
    await syncPendingSessions(id);
    await _downloadQuizHistory(id);
    return localUser;
  }

  static Future<void> syncPendingSessions(String remoteStudentId) async {
    final pending = await AppDatabase.instance.getPendingRemoteQuizSessions(
      remoteStudentId,
    );
    for (final session in pending) {
      final clientSessionId = session['client_session_id'] as String?;
      if (clientSessionId == null) {
        throw StateError(
          'A partida pendente nao possui identificador de sincronizacao.',
        );
      }
      final remoteSessionId = await _client.rpc(
        'record_quiz_session',
        params: {
          'p_student_id': remoteStudentId,
          'p_client_session_id': clientSessionId,
          'p_subject': session['materia'],
          'p_grade': session['ano'],
          'p_topic': session['topico'],
          'p_score': session['pontuacao'],
          'p_stars': session['estrelas'],
          'p_correct_answers': session['acertos'],
          'p_total_questions': session['total_perguntas'],
          'p_duration_seconds': session['tempo_segundos'],
          'p_completed_at': session['data_partida'],
          'p_attempts': session['attempts'],
        },
      );
      if (remoteSessionId is! String) {
        throw StateError(
          'O servidor retornou um identificador de partida invalido.',
        );
      }
      await AppDatabase.instance.markRemoteQuizSessionSynced(
        clientSessionId,
        remoteSessionId: remoteSessionId,
      );
    }
  }

  static Future<int> migrateLocalStudentHistory({
    required User sourceUser,
    required String sourcePassword,
    required User remoteStudent,
    required String consentVersion,
  }) async {
    if (sourceUser.id == null ||
        sourceUser.role != 'student' ||
        sourceUser.remoteStudentId != null ||
        !PasswordService.verifyPassword(sourcePassword, sourceUser.password)) {
      throw ArgumentError('A conta local ou a senha nao foi validada.');
    }
    final remoteStudentId = remoteStudent.remoteStudentId;
    final targetUserId = remoteStudent.id;
    if (remoteStudentId == null || targetUserId == null) {
      throw StateError(
        'O perfil online ainda nao esta preparado neste aparelho.',
      );
    }

    final localSessions = await AppDatabase.instance.buscarPartidasUsuario(
      sourceUser.id!,
    );
    final importableCount = localSessions
        .where((session) => session['remote_student_id'] == null)
        .length;
    if (importableCount == 0) return 0;

    await _client.rpc(
      'record_history_migration_consent',
      params: {
        'p_student_id': remoteStudentId,
        'p_consent_version': consentVersion,
      },
    );
    final clientSessionIds = List.generate(
      importableCount,
      (_) => createClientSessionId(),
    );
    final attached = await AppDatabase.instance
        .attachLocalStudentHistoryToRemote(
          sourceUserId: sourceUser.id!,
          targetUserId: targetUserId,
          remoteStudentId: remoteStudentId,
          clientSessionIds: clientSessionIds,
        );
    await syncPendingSessions(remoteStudentId);
    return attached;
  }

  static Future<void> _downloadQuizHistory(String remoteStudentId) async {
    const pageSize = 1000;
    for (var offset = 0; ; offset += pageSize) {
      final sessions = await _client
          .from('quiz_sessions')
          .select(
            'id, student_id, client_session_id, subject, grade, topic, score, stars, '
            'correct_answers, total_questions, duration_seconds, completed_at',
          )
          .eq('student_id', remoteStudentId)
          .order('completed_at')
          .order('id')
          .range(offset, offset + pageSize - 1);

      for (final row in sessions) {
        final session = Map<String, dynamic>.from(row);
        final attempts = await _client
            .from('question_attempts')
            .select(
              'question, selected_answer, correct_answer, is_correct, '
              'question_order, created_at',
            )
            .eq('quiz_session_id', session['id'])
            .order('question_order')
            .limit(100);
        await AppDatabase.instance.importRemoteQuizSession(
          session: session,
          attempts: List<Map<String, dynamic>>.from(attempts),
        );
      }
      if (sessions.length < pageSize) break;
    }
  }
}
