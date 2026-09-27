import 'dart:math';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqeducaplay/models/user_model.dart';
import 'package:flutter/foundation.dart';
import '../services/password_service.dart';
import '../models/teacher_assignment_model.dart';
import '../models/teacher_invite_model.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;
  // Se o banco nativo não puder ser inicializado (web, plataforma sem sqflite),
  // usamos um fallback em memória para permitir funcionalidades básicas.
  bool _dbAvailable = true;
  final List<User> _inMemoryUsers = [];
  int _inMemoryNextId = 100000; // ids gerados para usuários em memória
  final List<Map<String, dynamic>> _inMemoryPartidas = [];
  int _inMemoryNextPartidaId = 1;
  final List<Map<String, dynamic>> _inMemoryDailyMissionRewards = [];
  int _inMemoryNextDailyMissionRewardId = 1;
  final List<Map<String, dynamic>> _inMemoryQuestionAttempts = [];
  int _inMemoryNextAttemptId = 1;
  final List<TeacherAssignment> _inMemoryTeacherAssignments = [];
  int _inMemoryNextTeacherAssignmentId = 1;
  final List<TeacherInvite> _inMemoryTeacherInvites = [];
  int _inMemoryNextTeacherInviteId = 1;

  // Detectar se estamos no web: se sim, marcar DB como indisponível para evitar
  // chamadas a sqflite (que não existe no ambiente web) e usar o fallback em memória.
  AppDatabase._init() {
    _dbAvailable = !kIsWeb;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sqeducaplay.db');
    return _database!;
  }

  Future<void> _ensureRequiredTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        pontos INTEGER NOT NULL DEFAULT 0,
        data_desbloqueio TEXT NOT NULL,
        UNIQUE(userId, tipo),
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_rankings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        position INTEGER NOT NULL,
        updatedAt TEXT NOT NULL,
        UNIQUE(userId),
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS teacher_assignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        teacherId INTEGER NOT NULL,
        schoolId TEXT NOT NULL,
        grade TEXT NOT NULL,
        classGroup TEXT NOT NULL,
        shift TEXT NOT NULL,
        schedule TEXT,
        FOREIGN KEY (teacherId) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS teacher_invites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        schoolId TEXT NOT NULL,
        createdByUsername TEXT,
        createdAt TEXT NOT NULL,
        expiresAt TEXT NOT NULL,
        usedAt TEXT,
        usedByUserId INTEGER,
        FOREIGN KEY (usedByUserId) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_mission_rewards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        reward_date TEXT NOT NULL,
        stars INTEGER NOT NULL,
        UNIQUE(user_id, reward_date),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
  }

  Future<void> _ensureProgressIndex(Database db) async {
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS user_progress_unique_topic
      ON user_progress (userId, subject, grade, topic)
    ''');
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    try {
      return await openDatabase(
        path,
        version: 13,
        onConfigure: (Database db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _createDB,
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          // Upgrade path: v1 -> v2 add profilePhotoPath column to users
          if (oldVersion < 2) {
            try {
              await db.execute(
                "ALTER TABLE users ADD COLUMN profilePhotoPath TEXT",
              );
            } catch (_) {}
          }
          if (oldVersion < 3) {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS quiz_question_attempts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                partida_id INTEGER NOT NULL,
                usuario_id INTEGER NOT NULL,
                materia TEXT NOT NULL,
                ano TEXT NOT NULL,
                topico TEXT,
                pergunta TEXT NOT NULL,
                resposta_selecionada TEXT NOT NULL,
                resposta_correta TEXT NOT NULL,
                acertou INTEGER NOT NULL DEFAULT 0,
                ordem_pergunta INTEGER NOT NULL DEFAULT 0,
                data_tentativa TEXT NOT NULL,
                FOREIGN KEY (usuario_id) REFERENCES users (id),
                FOREIGN KEY (partida_id) REFERENCES partidas (id)
              )
            ''');
          }
          if (oldVersion < 4) {
            await _migratePlainTextPasswords(db);
          }
          if (oldVersion < 5) {
            await _ensureRequiredTables(db);
          }
          if (oldVersion < 6) {
            await _ensureRequiredTables(db);
          }
          if (oldVersion < 7) {
            await _ensureRequiredTables(db);
          }
          if (oldVersion < 8) {
            try {
              await db.execute(
                'ALTER TABLE users ADD COLUMN guardianName TEXT',
              );
              await db.execute('ALTER TABLE users ADD COLUMN consentAt TEXT');
              await db.execute(
                'ALTER TABLE users ADD COLUMN consentVersion TEXT',
              );
            } catch (_) {}
          }
          if (oldVersion < 9) {
            await _ensureRequiredTables(db);
          }
          if (oldVersion < 10) {
            // Bancos antigos podiam conter mais de uma linha para o mesmo
            // topico. Mantemos o registro mais recente antes de impor a
            // unicidade usada pelo ConflictAlgorithm.replace.
            await db.execute('''
              DELETE FROM user_progress
              WHERE id NOT IN (
                SELECT MAX(id)
                FROM user_progress
                GROUP BY userId, subject, grade, topic
              )
            ''');
            await _ensureRequiredTables(db);
            await _ensureProgressIndex(db);
          }
          if (oldVersion < 11) {
            await db.execute(
              'ALTER TABLE users ADD COLUMN isApproved INTEGER NOT NULL DEFAULT 1',
            );
          }
          if (oldVersion < 12) {
            await db.execute(
              'ALTER TABLE users ADD COLUMN remoteStudentId TEXT',
            );
            await db.execute(
              'CREATE UNIQUE INDEX IF NOT EXISTS users_remote_student_id '
              'ON users (remoteStudentId) WHERE remoteStudentId IS NOT NULL',
            );
          }
          if (oldVersion < 13) {
            await db.execute(
              'ALTER TABLE partidas ADD COLUMN remote_student_id TEXT',
            );
            await db.execute(
              'ALTER TABLE partidas ADD COLUMN client_session_id TEXT',
            );
            await db.execute(
              'ALTER TABLE partidas ADD COLUMN remote_session_id TEXT',
            );
            await db.execute(
              'ALTER TABLE partidas ADD COLUMN remote_synced INTEGER NOT NULL DEFAULT 1',
            );
            await db.execute(
              'CREATE UNIQUE INDEX IF NOT EXISTS partidas_client_session_id '
              'ON partidas (client_session_id) WHERE client_session_id IS NOT NULL',
            );
            await db.execute(
              'CREATE UNIQUE INDEX IF NOT EXISTS partidas_remote_session_id '
              'ON partidas (remote_session_id) WHERE remote_session_id IS NOT NULL',
            );
          }
        },
        onOpen: (Database db) async {
          await _ensureRequiredTables(db);
          await _ensureProgressIndex(db);
        },
      );
    } catch (e) {
      // Provavelmente estamos em uma plataforma sem sqflite (ex: web). Marca
      // o DB como indisponível e mantém um fallback em memória.
      _dbAvailable = false;
      throw Exception('DB not available on this platform: $e');
    }
  }

  Future<void> _migratePlainTextPasswords(Database db) async {
    try {
      final users = await db.query('users');
      for (final user in users) {
        final rawPassword = (user['password'] as String?) ?? '';
        if (rawPassword.isEmpty) continue;

        if (!PasswordService.isHashed(rawPassword)) {
          final hashed = PasswordService.hashPassword(rawPassword);
          await db.update(
            'users',
            {'password': hashed},
            where: 'id = ?',
            whereArgs: [user['id']],
          );
        }
      }
    } catch (_) {
      // Ignora falhas de migração em bancos legados e mantém compatibilidade.
    }
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const integerType = 'INTEGER';

    // Tabela de usuários (adicionamos pontuação/estrelas para compatibilidade)
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        username $textType UNIQUE,
        password $textType,
        fullName $textType,
        nickname $textNullable,
        grade $textNullable,
        classGroup $textNullable,
        schoolId $textNullable,
        role $textType,
        isApproved INTEGER NOT NULL DEFAULT 1,
        pontuacao_total INTEGER DEFAULT 0,
        estrelas_total INTEGER DEFAULT 0,
        profilePhotoPath $textNullable,
        guardianName $textNullable,
        consentAt TEXT,
        consentVersion $textNullable,
        remoteStudentId $textNullable UNIQUE,
        createdAt TEXT NOT NULL,
        lastLogin TEXT
      )
    ''');

    // Tabela de estatísticas
    await db.execute('''
      CREATE TABLE user_stats (
        id $idType,
        userId INTEGER NOT NULL,
        subject TEXT NOT NULL,
        topic TEXT NOT NULL,
        correctAnswers $integerType DEFAULT 0,
        totalQuestions $integerType DEFAULT 0,
        lastPlayed TEXT,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Tabela de partidas (histórico)
    await db.execute('''
      CREATE TABLE partidas (
        id $idType,
        usuario_id INTEGER NOT NULL,
        materia TEXT NOT NULL,
        ano TEXT NOT NULL,
        topico TEXT,
        pontuacao INTEGER NOT NULL,
        estrelas INTEGER NOT NULL,
        acertos INTEGER NOT NULL,
        total_perguntas INTEGER NOT NULL,
        tempo_segundos INTEGER,
        data_partida TEXT NOT NULL,
        remote_student_id TEXT,
        client_session_id TEXT,
        remote_session_id TEXT,
        remote_synced INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (usuario_id) REFERENCES users (id)
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX partidas_client_session_id '
      'ON partidas (client_session_id) WHERE client_session_id IS NOT NULL',
    );
    await db.execute(
      'CREATE UNIQUE INDEX partidas_remote_session_id '
      'ON partidas (remote_session_id) WHERE remote_session_id IS NOT NULL',
    );

    // Tabela de progresso
    await db.execute('''
      CREATE TABLE user_progress (
        id $idType,
        userId INTEGER NOT NULL,
        subject TEXT NOT NULL,
        grade TEXT NOT NULL,
        topic TEXT NOT NULL,
        completed BOOLEAN NOT NULL DEFAULT 0,
        completedAt TEXT,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_mission_rewards (
        id $idType,
        user_id INTEGER NOT NULL,
        reward_date $textType,
        stars INTEGER NOT NULL,
        UNIQUE(user_id, reward_date),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Tabela para conquistas desbloqueadas por usuário
    await db.execute('''
      CREATE TABLE user_achievements (
        id $idType,
        userId INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        pontos INTEGER NOT NULL DEFAULT 0,
        data_desbloqueio TEXT NOT NULL,
        UNIQUE(userId, tipo),
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Tabela para armazenar última posição conhecida do usuário no ranking
    await db.execute('''
      CREATE TABLE user_rankings (
        id $idType,
        userId INTEGER NOT NULL,
        position INTEGER NOT NULL,
        updatedAt TEXT NOT NULL,
        UNIQUE(userId),
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE quiz_question_attempts (
        id $idType,
        partida_id INTEGER NOT NULL,
        usuario_id INTEGER NOT NULL,
        materia TEXT NOT NULL,
        ano TEXT NOT NULL,
        topico TEXT,
        pergunta TEXT NOT NULL,
        resposta_selecionada TEXT NOT NULL,
        resposta_correta TEXT NOT NULL,
        acertou INTEGER NOT NULL DEFAULT 0,
        ordem_pergunta INTEGER NOT NULL DEFAULT 0,
        data_tentativa TEXT NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES users (id),
        FOREIGN KEY (partida_id) REFERENCES partidas (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE teacher_assignments (
        id $idType,
        teacherId INTEGER NOT NULL,
        schoolId $textType,
        grade $textType,
        classGroup $textType,
        shift $textType,
        schedule $textNullable,
        FOREIGN KEY (teacherId) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE teacher_invites (
        id $idType,
        code $textType UNIQUE,
        schoolId $textType,
        createdByUsername $textNullable,
        createdAt $textType,
        expiresAt $textType,
        usedAt $textNullable,
        usedByUserId $integerType,
        FOREIGN KEY (usedByUserId) REFERENCES users (id)
      )
    ''');

    await _ensureProgressIndex(db);

    // (exercícios e status removidos — funcionalidade adiada)
  }

  // Exercícios: inserir
  // Exercise-related methods removed (feature deferred)

  // Salva uma partida (similar ao DatabaseHelper.salvarPartida)
  Future<int> salvarPartida(Map<String, dynamic> partida) async {
    if (!_dbAvailable) {
      final partidaId = _inMemoryNextPartidaId++;
      final stored = Map<String, dynamic>.from(partida)..['id'] = partidaId;
      _inMemoryPartidas.add(stored);
      return stored['id'] as int;
    }
    final db = await database;
    final partidaId = await db.insert('partidas', partida);

    // Recalcula os totais a partir do histórico para evitar drift entre
    // `partidas` e os campos agregados em `users`.
    try {
      await recalculateAndPersistUserTotals(partida['usuario_id'] as int);
    } catch (_) {}

    // Um topico so e concluido com dominio minimo de 70%.
    try {
      final correct = partida['acertos'] as int? ?? 0;
      final total = partida['total_perguntas'] as int? ?? 0;
      if (total > 0 && correct / total >= 0.70) {
        await updateUserProgress(
          partida['usuario_id'] as int,
          partida['materia'] as String,
          partida['ano'] as String,
          partida['topico'] as String? ?? '',
        );
      }
    } catch (_) {}

    return partidaId;
  }

  Future<bool> claimDailyMissionReward({
    required int userId,
    required DateTime date,
    int stars = 10,
  }) async {
    final rewardDate = date.toIso8601String().substring(0, 10);
    if (!_dbAvailable) {
      final alreadyClaimed = _inMemoryDailyMissionRewards.any(
        (reward) =>
            reward['user_id'] == userId && reward['reward_date'] == rewardDate,
      );
      if (alreadyClaimed) return false;
      _inMemoryDailyMissionRewards.add({
        'id': _inMemoryNextDailyMissionRewardId++,
        'user_id': userId,
        'reward_date': rewardDate,
        'stars': stars,
      });
      return true;
    }

    final db = await database;
    try {
      await db.insert('daily_mission_rewards', {
        'user_id': userId,
        'reward_date': rewardDate,
        'stars': stars,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<int> getDailyMissionStars(int userId) async {
    if (!_dbAvailable) {
      return _inMemoryDailyMissionRewards
          .where((reward) => reward['user_id'] == userId)
          .fold<int>(0, (total, reward) => total + (reward['stars'] as int));
    }

    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(stars), 0) AS total FROM daily_mission_rewards WHERE user_id = ?',
      [userId],
    );
    return (rows.first['total'] as int?) ?? 0;
  }

  Future<void> salvarTentativasPartida({
    required int usuarioId,
    required int partidaId,
    required String materia,
    required String ano,
    String? topico,
    required List<Map<String, dynamic>> tentativas,
  }) async {
    if (tentativas.isEmpty) return;

    if (!_dbAvailable) {
      for (var i = 0; i < tentativas.length; i++) {
        final tentativa = Map<String, dynamic>.from(tentativas[i]);
        _inMemoryQuestionAttempts.add({
          'id': _inMemoryNextAttemptId++,
          'partida_id': partidaId,
          'usuario_id': usuarioId,
          'materia': materia,
          'ano': ano,
          'topico': topico,
          'pergunta': tentativa['pergunta'] as String? ?? '',
          'resposta_selecionada':
              tentativa['resposta_selecionada'] as String? ?? '',
          'resposta_correta': tentativa['resposta_correta'] as String? ?? '',
          'acertou': (tentativa['acertou'] == true) ? 1 : 0,
          'ordem_pergunta': tentativa['ordem_pergunta'] as int? ?? i,
          'data_tentativa':
              tentativa['data_tentativa'] as String? ??
              DateTime.now().toIso8601String(),
        });
      }
      return;
    }

    final db = await database;
    final batch = db.batch();
    for (var i = 0; i < tentativas.length; i++) {
      final tentativa = tentativas[i];
      batch.insert('quiz_question_attempts', {
        'partida_id': partidaId,
        'usuario_id': usuarioId,
        'materia': materia,
        'ano': ano,
        'topico': topico,
        'pergunta': tentativa['pergunta'] as String? ?? '',
        'resposta_selecionada':
            tentativa['resposta_selecionada'] as String? ?? '',
        'resposta_correta': tentativa['resposta_correta'] as String? ?? '',
        'acertou': (tentativa['acertou'] == true) ? 1 : 0,
        'ordem_pergunta': tentativa['ordem_pergunta'] as int? ?? i,
        'data_tentativa':
            tentativa['data_tentativa'] as String? ??
            DateTime.now().toIso8601String(),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getPendingRemoteQuizSessions(
    String remoteStudentId,
  ) async {
    final pending = <Map<String, dynamic>>[];
    if (!_dbAvailable) {
      for (final partida in _inMemoryPartidas.where(
        (row) =>
            row['remote_student_id'] == remoteStudentId &&
            row['remote_synced'] == 0,
      )) {
        final partidaId = partida['id'];
        final attempts = _inMemoryQuestionAttempts
            .where((row) => row['partida_id'] == partidaId)
            .map(
              (row) => {
                'question': row['pergunta'],
                'selected_answer': row['resposta_selecionada'],
                'correct_answer': row['resposta_correta'],
                'is_correct': row['acertou'] == 1,
                'question_order': row['ordem_pergunta'],
              },
            )
            .toList();
        pending.add({...partida, 'attempts': attempts});
      }
      return pending;
    }

    final db = await database;
    final rows = await db.query(
      'partidas',
      where: 'remote_student_id = ? AND remote_synced = 0',
      whereArgs: [remoteStudentId],
      orderBy: 'id',
    );
    for (final row in rows) {
      final attempts = await db.query(
        'quiz_question_attempts',
        columns: [
          'pergunta',
          'resposta_selecionada',
          'resposta_correta',
          'acertou',
          'ordem_pergunta',
        ],
        where: 'partida_id = ?',
        whereArgs: [row['id']],
        orderBy: 'ordem_pergunta',
      );
      pending.add({
        ...row,
        'attempts': attempts
            .map(
              (attempt) => {
                'question': attempt['pergunta'],
                'selected_answer': attempt['resposta_selecionada'],
                'correct_answer': attempt['resposta_correta'],
                'is_correct': attempt['acertou'] == 1,
                'question_order': attempt['ordem_pergunta'],
              },
            )
            .toList(),
      });
    }
    return pending;
  }

  Future<void> markRemoteQuizSessionSynced(
    String clientSessionId, {
    required String remoteSessionId,
  }) async {
    if (!_dbAvailable) {
      for (final row in _inMemoryPartidas) {
        if (row['client_session_id'] == clientSessionId) {
          row['remote_synced'] = 1;
          row['remote_session_id'] = remoteSessionId;
        }
      }
      return;
    }
    final db = await database;
    await db.update(
      'partidas',
      {'remote_synced': 1, 'remote_session_id': remoteSessionId},
      where: 'client_session_id = ?',
      whereArgs: [clientSessionId],
    );
  }

  Future<void> importRemoteQuizSession({
    required Map<String, dynamic> session,
    required List<Map<String, dynamic>> attempts,
  }) async {
    final remoteSessionId = session['id'] as String;
    if (!_dbAvailable) {
      if (_inMemoryPartidas.any(
        (row) => row['remote_session_id'] == remoteSessionId,
      )) {
        return;
      }
    } else {
      final db = await database;
      final existing = await db.query(
        'partidas',
        columns: ['id'],
        where: 'remote_session_id = ?',
        whereArgs: [remoteSessionId],
        limit: 1,
      );
      if (existing.isNotEmpty) return;
    }

    final remoteStudentId = session['student_id'] as String?;
    if (remoteStudentId == null) return;
    final student = await _findLocalRemoteStudent(remoteStudentId);
    if (student?.id == null) return;

    final completedAt =
        session['completed_at'] as String? ?? DateTime.now().toIso8601String();
    final partidaId = await salvarPartida({
      'usuario_id': student!.id!,
      'materia': session['subject'] as String? ?? '',
      'ano': session['grade'] as String? ?? '',
      'topico': session['topic'],
      'pontuacao': session['score'] as int? ?? 0,
      'estrelas': session['stars'] as int? ?? 0,
      'acertos': session['correct_answers'] as int? ?? 0,
      'total_perguntas': session['total_questions'] as int? ?? 0,
      'tempo_segundos': session['duration_seconds'],
      'data_partida': completedAt,
      'remote_student_id': remoteStudentId,
      'client_session_id': session['client_session_id'],
      'remote_session_id': remoteSessionId,
      'remote_synced': 1,
    });

    if (attempts.isEmpty) return;
    await salvarTentativasPartida(
      usuarioId: student.id!,
      partidaId: partidaId,
      materia: session['subject'] as String? ?? '',
      ano: session['grade'] as String? ?? '',
      topico: session['topic'] as String?,
      tentativas: attempts
          .map(
            (attempt) => {
              'pergunta': attempt['question'],
              'resposta_selecionada': attempt['selected_answer'],
              'resposta_correta': attempt['correct_answer'],
              'acertou': attempt['is_correct'] == true,
              'ordem_pergunta': attempt['question_order'],
              'data_tentativa': attempt['created_at'] ?? completedAt,
            },
          )
          .toList(),
    );
  }

  Future<User?> _findLocalRemoteStudent(String remoteStudentId) async {
    if (!_dbAvailable) {
      for (final user in _inMemoryUsers) {
        if (user.remoteStudentId == remoteStudentId) return user;
      }
      return null;
    }
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'remoteStudentId = ?',
      whereArgs: [remoteStudentId],
      limit: 1,
    );
    return rows.isEmpty ? null : User.fromMap(rows.first);
  }

  Future<int> attachLocalStudentHistoryToRemote({
    required int sourceUserId,
    required int targetUserId,
    required String remoteStudentId,
    required List<String> clientSessionIds,
  }) async {
    if (!_dbAvailable) {
      final sourceSessions = _inMemoryPartidas
          .where(
            (row) =>
                row['usuario_id'] == sourceUserId &&
                row['remote_student_id'] == null,
          )
          .toList();
      if (sourceSessions.length != clientSessionIds.length) {
        throw StateError('O historico local mudou durante a migracao.');
      }
      for (var i = 0; i < sourceSessions.length; i++) {
        final session = sourceSessions[i];
        final partidaId = session['id'];
        session
          ..['usuario_id'] = targetUserId
          ..['remote_student_id'] = remoteStudentId
          ..['client_session_id'] = clientSessionIds[i]
          ..['remote_synced'] = 0;
        for (final attempt in _inMemoryQuestionAttempts.where(
          (row) => row['partida_id'] == partidaId,
        )) {
          attempt['usuario_id'] = targetUserId;
        }
      }
      return sourceSessions.length;
    }

    final db = await database;
    return db.transaction((transaction) async {
      final sourceSessions = await transaction.query(
        'partidas',
        columns: ['id'],
        where: 'usuario_id = ? AND remote_student_id IS NULL',
        whereArgs: [sourceUserId],
        orderBy: 'id',
      );
      if (sourceSessions.length != clientSessionIds.length) {
        throw StateError('O historico local mudou durante a migracao.');
      }

      for (var i = 0; i < sourceSessions.length; i++) {
        final partidaId = sourceSessions[i]['id'] as int;
        await transaction.update(
          'partidas',
          {
            'usuario_id': targetUserId,
            'remote_student_id': remoteStudentId,
            'client_session_id': clientSessionIds[i],
            'remote_synced': 0,
          },
          where: 'id = ?',
          whereArgs: [partidaId],
        );
        await transaction.update(
          'quiz_question_attempts',
          {'usuario_id': targetUserId},
          where: 'partida_id = ?',
          whereArgs: [partidaId],
        );
      }
      return sourceSessions.length;
    });
  }

  Future<Map<String, int>> _getUserTotalsFromPartidas(int userId) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(pontuacao), 0) AS pontuacao_total,
        COALESCE(SUM(estrelas), 0) AS estrelas_total
      FROM partidas
      WHERE usuario_id = ?
    ''',
      [userId],
    );

    final row = rows.isNotEmpty ? rows.first : <String, Object?>{};
    return {
      'pontuacao_total': (row['pontuacao_total'] as int?) ?? 0,
      'estrelas_total': (row['estrelas_total'] as int?) ?? 0,
    };
  }

  Future<void> recalculateAndPersistUserTotals(int userId) async {
    if (!_dbAvailable) return;
    final db = await database;
    final totals = await _getUserTotalsFromPartidas(userId);
    await db.update('users', totals, where: 'id = ?', whereArgs: [userId]);
  }

  Future<List<Map<String, dynamic>>> buscarUltimasPartidas(
    int usuarioId, {
    int limit = 10,
  }) async {
    if (!_dbAvailable) {
      final partidas =
          _inMemoryPartidas
              .where((partida) => partida['usuario_id'] == usuarioId)
              .toList()
            ..sort(
              (a, b) => (b['data_partida'] as String? ?? '').compareTo(
                a['data_partida'] as String? ?? '',
              ),
            );
      return partidas.take(limit).map(Map<String, dynamic>.from).toList();
    }
    final db = await database;
    return await db.query(
      'partidas',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'data_partida DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> buscarPartidasUsuario(
    int usuarioId,
  ) async {
    if (!_dbAvailable) {
      final partidas =
          _inMemoryPartidas
              .where((partida) => partida['usuario_id'] == usuarioId)
              .toList()
            ..sort(
              (a, b) => (b['data_partida'] as String? ?? '').compareTo(
                a['data_partida'] as String? ?? '',
              ),
            );
      return partidas.map(Map<String, dynamic>.from).toList();
    }
    final db = await database;
    return await db.query(
      'partidas',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'data_partida DESC',
    );
  }

  Future<List<Map<String, dynamic>>> buscarTentativasUsuario(
    int usuarioId, {
    bool somenteErros = false,
    int limit = 100,
  }) async {
    if (!_dbAvailable) {
      final rows =
          _inMemoryQuestionAttempts.where((row) {
            if ((row['usuario_id'] as int?) != usuarioId) return false;
            if (somenteErros && (row['acertou'] as int?) != 0) return false;
            return true;
          }).toList()..sort(
            (a, b) => (b['data_tentativa'] as String).compareTo(
              a['data_tentativa'] as String,
            ),
          );
      return rows
          .take(limit)
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }

    final db = await database;
    return await db.query(
      'quiz_question_attempts',
      where: 'usuario_id = ?${somenteErros ? ' AND acertou = 0' : ''}',
      whereArgs: [usuarioId],
      orderBy: 'data_tentativa DESC, ordem_pergunta ASC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> buscarTentativasPorAno(
    String ano, {
    int limit = 200,
  }) async {
    if (!_dbAvailable) {
      final rows =
          _inMemoryQuestionAttempts
              .where((row) => (row['ano'] as String? ?? '') == ano)
              .toList()
            ..sort(
              (a, b) => (b['data_tentativa'] as String).compareTo(
                a['data_tentativa'] as String,
              ),
            );
      return rows
          .take(limit)
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }

    final db = await database;
    return await db.query(
      'quiz_question_attempts',
      where: 'ano = ?',
      whereArgs: [ano],
      orderBy: 'data_tentativa DESC, ordem_pergunta ASC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> buscarTentativasErrosPorAno(
    String ano, {
    int limit = 50,
  }) async {
    if (!_dbAvailable) {
      final rows = _inMemoryQuestionAttempts
          .where(
            (row) =>
                (row['ano'] as String? ?? '') == ano &&
                (row['acertou'] as int?) == 0,
          )
          .toList();
      final grouped = <String, Map<String, dynamic>>{};
      for (final row in rows) {
        final pergunta = row['pergunta'] as String? ?? '';
        final entry = grouped.putIfAbsent(
          pergunta,
          () => {
            'pergunta': pergunta,
            'total_erros': 0,
            'materia': row['materia'],
            'topico': row['topico'],
          },
        );
        entry['total_erros'] = (entry['total_erros'] as int) + 1;
      }
      final result = grouped.values.toList()
        ..sort(
          (a, b) =>
              (b['total_erros'] as int).compareTo(a['total_erros'] as int),
        );
      return result.take(limit).toList();
    }

    final db = await database;
    return await db.rawQuery(
      '''
      SELECT
        pergunta,
        materia,
        topico,
        COUNT(*) AS total_erros
      FROM quiz_question_attempts
      WHERE ano = ? AND acertou = 0
      GROUP BY pergunta, materia, topico
      ORDER BY total_erros DESC, pergunta ASC
      LIMIT ?
    ''',
      [ano, limit],
    );
  }

  Future<Map<String, dynamic>> buscarEstatisticasUsuario(int usuarioId) async {
    final db = await database;
    final usuario = await getUser(usuarioId);

    final partidasAgg = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as total_partidas,
        SUM(acertos) as total_acertos,
        SUM(total_perguntas) as total_perguntas,
        AVG(pontuacao) as media_pontuacao
      FROM partidas
      WHERE usuario_id = ?
    ''',
      [usuarioId],
    );

    // Agrega progresso por matéria/ano a partir do histórico de partidas
    final progressoAgg = await db.rawQuery(
      '''
      SELECT
        materia as materia,
        ano as ano,
        SUM(acertos) as total_acertos,
        SUM(total_perguntas) as total_perguntas,
        MAX(pontuacao) as melhor_pontuacao
      FROM partidas
      WHERE usuario_id = ?
      GROUP BY materia, ano
    ''',
      [usuarioId],
    );

    // Normaliza para o formato esperado pela UI
    final progressoPorMateria = progressoAgg
        .map(
          (row) => {
            'materia': row['materia'] as String? ?? '-',
            'ano': row['ano'] as String? ?? '',
            'total_acertos': (row['total_acertos'] as int?) ?? 0,
            'total_perguntas': (row['total_perguntas'] as int?) ?? 0,
            'melhor_pontuacao': (row['melhor_pontuacao'] as int?) ?? 0,
          },
        )
        .toList();

    // Normaliza o resultado da agregação para garantir tipos não-nulos
    final rawAgg = partidasAgg.isNotEmpty
        ? partidasAgg.first
        : <String, Object?>{};
    final totalPartidas = (rawAgg['total_partidas'] as int?) ?? 0;
    final totalAcertos = (rawAgg['total_acertos'] as int?) ?? 0;
    final totalPerguntas = (rawAgg['total_perguntas'] as int?) ?? 0;

    double mediaPontuacao = 0.0;
    final mediaRaw = rawAgg['media_pontuacao'];
    if (mediaRaw is num) {
      mediaPontuacao = mediaRaw.toDouble();
    } else if (mediaRaw is String) {
      mediaPontuacao = double.tryParse(mediaRaw) ?? 0.0;
    }

    return {
      'usuario': usuario?.toMap(),
      'estatisticas_gerais': {
        'total_partidas': totalPartidas,
        'total_acertos': totalAcertos,
        'total_perguntas': totalPerguntas,
        'media_pontuacao': mediaPontuacao,
      },
      'progresso_por_materia': progressoPorMateria,
    };
  }

  Future<List<Map<String, dynamic>>> buscarTodoProgressoUsuario(
    int usuarioId,
  ) async {
    final db = await database;
    return await db.query(
      'user_progress',
      where: 'userId = ?',
      whereArgs: [usuarioId],
      orderBy: 'subject, grade',
    );
  }

  Future<List<Map<String, dynamic>>> buscarRankingGeral({
    int limit = 10,
  }) async {
    if (!_dbAvailable) {
      final ranking = <Map<String, dynamic>>[];
      for (final user in _inMemoryUsers.where(
        (item) => item.role == 'student',
      )) {
        final partidas = _inMemoryPartidas.where(
          (partida) => partida['usuario_id'] == user.id,
        );
        final pontuacao = partidas.fold<int>(
          0,
          (total, partida) => total + ((partida['pontuacao'] as int?) ?? 0),
        );
        final estrelas = partidas.fold<int>(
          0,
          (total, partida) => total + ((partida['estrelas'] as int?) ?? 0),
        );
        if (pontuacao > 0 || estrelas > 0 || partidas.isNotEmpty) {
          ranking.add({
            'id': user.id,
            'nome': user.username,
            'pontuacao_total': pontuacao,
            'estrelas_total':
                estrelas +
                _inMemoryDailyMissionRewards
                    .where((reward) => reward['user_id'] == user.id)
                    .fold<int>(
                      0,
                      (total, reward) => total + (reward['stars'] as int),
                    ),
          });
        }
      }
      ranking.sort((a, b) {
        final pontos = (b['pontuacao_total'] as int).compareTo(
          a['pontuacao_total'] as int,
        );
        return pontos != 0
            ? pontos
            : (b['estrelas_total'] as int).compareTo(
                a['estrelas_total'] as int,
              );
      });
      return ranking.take(limit).toList();
    }

    final db = await database;
    return await db.rawQuery(
      '''
      SELECT
        u.id,
        u.username as nome,
        u.pontuacao_total,
        u.estrelas_total + COALESCE((
          SELECT SUM(r.stars)
          FROM daily_mission_rewards r
          WHERE r.user_id = u.id
        ), 0) AS estrelas_total
      FROM users u
      WHERE u.role = 'student'
        AND (
          u.pontuacao_total > 0
          OR u.estrelas_total > 0
          OR EXISTS (
            SELECT 1
            FROM daily_mission_rewards r
            WHERE r.user_id = u.id
          )
          OR EXISTS (
            SELECT 1
            FROM partidas p
            WHERE p.usuario_id = u.id
          )
        )
      ORDER BY u.pontuacao_total DESC, u.estrelas_total DESC
      LIMIT ?
    ''',
      [limit],
    );
  }

  Future<List<Map<String, dynamic>>> buscarRankingPorMateria(
    String materia, {
    int limit = 10,
  }) async {
    if (!_dbAvailable) {
      final ranking = <Map<String, dynamic>>[];
      for (final user in _inMemoryUsers.where(
        (item) => item.role == 'student',
      )) {
        final partidas = _inMemoryPartidas
            .where(
              (partida) =>
                  partida['usuario_id'] == user.id &&
                  partida['materia'] == materia,
            )
            .toList();
        if (partidas.isEmpty) continue;
        final pontuacao = partidas.fold<int>(
          0,
          (total, partida) => total + ((partida['pontuacao'] as int?) ?? 0),
        );
        final estrelas = partidas.fold<int>(
          0,
          (total, partida) => total + ((partida['estrelas'] as int?) ?? 0),
        );
        final acertos = partidas.fold<int>(
          0,
          (total, partida) => total + ((partida['acertos'] as int?) ?? 0),
        );
        ranking.add({
          'id': user.id,
          'nome': user.username,
          'nome_user': user.username,
          'pontuacao_materia': pontuacao,
          'estrelas_materia': estrelas,
          'total_acertos': acertos,
          'total_partidas': partidas.length,
        });
      }
      ranking.sort((a, b) {
        final pontos = (b['pontuacao_materia'] as int).compareTo(
          a['pontuacao_materia'] as int,
        );
        return pontos != 0
            ? pontos
            : (b['estrelas_materia'] as int).compareTo(
                a['estrelas_materia'] as int,
              );
      });
      return ranking.take(limit).toList();
    }

    final db = await database;
    return await db.rawQuery(
      '''
      SELECT 
        u.id,
        u.username as nome,
        u.username as nome_user,
        SUM(p.pontuacao) as pontuacao_materia,
        SUM(p.estrelas) as estrelas_materia,
        SUM(p.acertos) as total_acertos,
        COUNT(p.id) as total_partidas
      FROM users u
      INNER JOIN partidas p ON u.id = p.usuario_id
      WHERE p.materia = ?
      GROUP BY u.id, u.username
      ORDER BY pontuacao_materia DESC, estrelas_materia DESC
      LIMIT ?
    ''',
      [materia, limit],
    );
  }

  // CRUD Operations para Usuários
  Future<User> createUser(User user) async {
    final hashedPassword = PasswordService.hashIfNeeded(user.password);
    if (!_dbAvailable) {
      final id = _inMemoryNextId++;
      final u = user.copy(
        id: id,
        password: hashedPassword,
        createdAt: DateTime.now(),
      );
      _inMemoryUsers.add(u);
      return u;
    }
    final db = await database;
    final createdAt = DateTime.now();
    final id = await db.insert('users', {
      'username': user.username,
      'password': hashedPassword,
      'fullName': user.fullName,
      'nickname': user.nickname,
      'grade': user.grade,
      'classGroup': user.classGroup,
      'schoolId': user.schoolId,
      'isApproved': user.isApproved ? 1 : 0,
      'profilePhotoPath': user.profilePhotoPath,
      'guardianName': user.guardianName,
      'consentAt': user.consentAt?.toIso8601String(),
      'consentVersion': user.consentVersion,
      'remoteStudentId': user.remoteStudentId,
      'role': user.role,
      'pontuacao_total': 0,
      'estrelas_total': 0,
      'createdAt': createdAt.toIso8601String(),
    });
    return user.copy(id: id, password: hashedPassword, createdAt: createdAt);
  }

  Future<User> getOrCreateRemoteStudent({
    required String remoteStudentId,
    required String username,
    required String fullName,
    String? nickname,
    required String grade,
    required bool isApproved,
  }) async {
    User refresh(User user) => user.copy(
      username: username,
      fullName: fullName,
      nickname: nickname,
      grade: grade,
      isApproved: isApproved,
    );

    if (!_dbAvailable) {
      for (final user in _inMemoryUsers) {
        if (user.remoteStudentId == remoteStudentId) {
          final updated = refresh(user);
          await updateUser(updated);
          return updated;
        }
      }
    } else {
      final db = await database;
      final rows = await db.query(
        'users',
        where: 'remoteStudentId = ?',
        whereArgs: [remoteStudentId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final updated = refresh(User.fromMap(rows.first));
        await updateUser(updated);
        return updated;
      }
    }

    final suffix = remoteStudentId.replaceAll('-', '');
    final existingUsername = await getUserByUsername(username);
    final localUsername = existingUsername == null
        ? username
        : '_remote_${suffix.substring(0, min(20, suffix.length))}';
    final randomPassword = List.generate(
      32,
      (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return createUser(
      User(
        username: localUsername,
        password: randomPassword,
        fullName: fullName,
        nickname: nickname,
        grade: grade,
        role: 'student',
        isApproved: isApproved,
        remoteStudentId: remoteStudentId,
      ),
    );
  }

  Future<void> ensureDevelopmentAdmin({
    required String username,
    required String password,
  }) async {
    final existing = await getUserByUsername(username);
    if (existing != null) return;

    await createUser(
      User(
        username: username,
        password: password,
        fullName: 'Administrador de desenvolvimento',
        role: 'admin',
      ),
    );
  }

  Future<TeacherAssignment> createTeacherAssignment(
    TeacherAssignment assignment,
  ) async {
    if (!_dbAvailable) {
      final created = TeacherAssignment(
        id: _inMemoryNextTeacherAssignmentId++,
        teacherId: assignment.teacherId,
        schoolId: assignment.schoolId,
        grade: assignment.grade,
        classGroup: assignment.classGroup,
        shift: assignment.shift,
        schedule: assignment.schedule,
      );
      _inMemoryTeacherAssignments.add(created);
      return created;
    }

    final db = await database;
    await _ensureRequiredTables(db);
    final id = await db.insert(
      'teacher_assignments',
      assignment.toMap()..remove('id'),
    );
    return TeacherAssignment(
      id: id,
      teacherId: assignment.teacherId,
      schoolId: assignment.schoolId,
      grade: assignment.grade,
      classGroup: assignment.classGroup,
      shift: assignment.shift,
      schedule: assignment.schedule,
    );
  }

  Future<List<TeacherAssignment>> getTeacherAssignments(int teacherId) async {
    if (!_dbAvailable) {
      return _inMemoryTeacherAssignments
          .where((item) => item.teacherId == teacherId)
          .toList();
    }

    final db = await database;
    final maps = await db.query(
      'teacher_assignments',
      where: 'teacherId = ?',
      whereArgs: [teacherId],
      orderBy: 'grade ASC, classGroup ASC',
    );
    return maps.map(TeacherAssignment.fromMap).toList();
  }

  TeacherInvite? _findTeacherInviteByCodeInMemory(String code) {
    for (final invite in _inMemoryTeacherInvites) {
      if (invite.code == code) {
        return invite;
      }
    }
    return null;
  }

  Future<TeacherInvite> createTeacherInvite({
    required String code,
    required String schoolId,
    String? createdByUsername,
    Duration validFor = const Duration(days: 14),
  }) async {
    if (code.trim().isEmpty) {
      throw ArgumentError('Código de convite obrigatório.');
    }
    if (schoolId.trim().isEmpty) {
      throw ArgumentError('Escola do convite obrigatória.');
    }

    final now = DateTime.now();
    final invite = TeacherInvite(
      code: code.trim(),
      schoolId: schoolId.trim(),
      createdByUsername: createdByUsername,
      createdAt: now,
      expiresAt: now.add(validFor),
    );

    if (!_dbAvailable) {
      final exists = _inMemoryTeacherInvites.any(
        (item) => item.code == invite.code,
      );
      if (exists) {
        throw ArgumentError('Código de convite já existente.');
      }
      final created = TeacherInvite(
        id: _inMemoryNextTeacherInviteId++,
        code: invite.code,
        schoolId: invite.schoolId,
        createdByUsername: invite.createdByUsername,
        createdAt: invite.createdAt,
        expiresAt: invite.expiresAt,
      );
      _inMemoryTeacherInvites.add(created);
      return created;
    }

    final db = await database;
    try {
      final id = await db.insert(
        'teacher_invites',
        invite.toMap()..remove('id'),
      );
      return invite.copyWith(id: id);
    } catch (_) {
      throw ArgumentError('Código de convite já existente.');
    }
  }

  Future<List<TeacherInvite>> listTeacherInvites({String? schoolId}) async {
    if (!_dbAvailable) {
      final invites = List<TeacherInvite>.from(_inMemoryTeacherInvites);
      if (schoolId == null || schoolId.trim().isEmpty) return invites;
      return invites.where((item) => item.schoolId == schoolId).toList();
    }

    final db = await database;
    final rows = schoolId == null || schoolId.trim().isEmpty
        ? await db.query('teacher_invites', orderBy: 'createdAt DESC')
        : await db.query(
            'teacher_invites',
            where: 'schoolId = ?',
            whereArgs: [schoolId],
            orderBy: 'createdAt DESC',
          );

    return rows.map(TeacherInvite.fromMap).toList();
  }

  Future<TeacherInvite?> getTeacherInviteByCode(String code) async {
    final normalized = code.trim();
    if (normalized.isEmpty) return null;

    if (!_dbAvailable) {
      return _findTeacherInviteByCodeInMemory(normalized);
    }

    final db = await database;
    final rows = await db.query(
      'teacher_invites',
      where: 'code = ?',
      whereArgs: [normalized],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TeacherInvite.fromMap(rows.first);
  }

  Future<User> createTeacherFromInvite({
    required String inviteCode,
    required User teacher,
    required List<TeacherAssignment> assignments,
  }) async {
    final normalizedCode = inviteCode.trim();
    if (normalizedCode.isEmpty) {
      throw ArgumentError('Informe o código de convite.');
    }
    if (teacher.username.trim().isEmpty) {
      throw ArgumentError('Nome de usuário obrigatório.');
    }
    if (teacher.password.trim().isEmpty) {
      throw ArgumentError('Senha obrigatória.');
    }
    if (assignments.isEmpty) {
      throw ArgumentError('Adicione pelo menos uma turma.');
    }

    final invite = await getTeacherInviteByCode(normalizedCode);
    if (invite == null) {
      throw ArgumentError('Código de convite inexistente.');
    }
    if (invite.isUsed) {
      throw ArgumentError('Este código de convite já foi usado.');
    }
    if (invite.isExpiredAt(DateTime.now())) {
      throw ArgumentError('Este código de convite expirou.');
    }

    final expectedSchoolId = invite.schoolId;
    final schoolMismatch = assignments.any(
      (assignment) => assignment.schoolId != expectedSchoolId,
    );
    if (schoolMismatch ||
        (teacher.schoolId != null && teacher.schoolId != expectedSchoolId)) {
      throw ArgumentError('O convite não corresponde à escola informada.');
    }

    final duplicateUser = await getUserByUsername(teacher.username);
    if (duplicateUser != null) {
      throw ArgumentError('Nome de usuário já está em uso.');
    }

    final createdTeacher = await createUser(
      teacher.copy(role: 'teacher', schoolId: expectedSchoolId),
    );

    final createdAssignments = <TeacherAssignment>[];
    for (final assignment in assignments) {
      createdAssignments.add(
        await createTeacherAssignment(
          assignment.copyWith(teacherId: createdTeacher.id ?? 0),
        ),
      );
    }

    final updatedInvite = invite.copyWith(
      usedAt: DateTime.now(),
      usedByUserId: createdTeacher.id,
    );
    await _saveTeacherInvite(updatedInvite);

    if (createdTeacher.id == null) {
      return createdTeacher;
    }

    for (final assignment in createdAssignments) {
      if (assignment.id == null) {
        continue;
      }
    }

    return createdTeacher;
  }

  Future<void> _saveTeacherInvite(TeacherInvite invite) async {
    if (!_dbAvailable) {
      final index = _inMemoryTeacherInvites.indexWhere(
        (item) => item.id == invite.id || item.code == invite.code,
      );
      if (index >= 0) {
        _inMemoryTeacherInvites[index] = invite;
      }
      return;
    }

    final db = await database;
    await db.update(
      'teacher_invites',
      invite.toMap(),
      where: 'code = ?',
      whereArgs: [invite.code],
    );
  }

  Future<bool> hasTeacherAccount() async {
    if (!_dbAvailable) {
      return _inMemoryUsers.any((u) => u.role == 'teacher');
    }

    try {
      final db = await database;
      final result = await db.query(
        'users',
        columns: ['id'],
        where: 'role = ?',
        whereArgs: ['teacher'],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (_) {
      _dbAvailable = false;
      return _inMemoryUsers.any((u) => u.role == 'teacher');
    }
  }

  Future<User?> getUser(int id) async {
    if (!_dbAvailable) {
      try {
        return _inMemoryUsers.firstWhere((u) => u.id == id);
      } catch (_) {
        return null;
      }
    }
    final db = await database;
    final maps = await db.query(
      'users',
      columns: [
        'id',
        'username',
        'password',
        'fullName',
        'nickname',
        'grade',
        'classGroup',
        'schoolId',
        'role',
        'isApproved',
        'pontuacao_total',
        'estrelas_total',
        'profilePhotoPath',
        'guardianName',
        'consentAt',
        'consentVersion',
        'remoteStudentId',
        'createdAt',
        'lastLogin',
      ],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByUsername(String username) async {
    if (!_dbAvailable) {
      try {
        return _inMemoryUsers.firstWhere(
          (u) => u.username.toLowerCase() == username.toLowerCase(),
        );
      } catch (_) {
        return null;
      }
    }
    try {
      final db = await database;
      final maps = await db.query(
        'users',
        columns: [
          'id',
          'username',
          'password',
          'fullName',
          'nickname',
          'grade',
          'classGroup',
          'schoolId',
          'role',
          'isApproved',
          'pontuacao_total',
          'estrelas_total',
          'profilePhotoPath',
          'guardianName',
          'consentAt',
          'consentVersion',
          'remoteStudentId',
          'createdAt',
          'lastLogin',
        ],
        // Busca case-insensitive por username
        where: 'LOWER(username) = ?',
        whereArgs: [username.toLowerCase()],
      );

      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      // Marcar como indisponível e fallback em memória
      _dbAvailable = false;
      try {
        return _inMemoryUsers.firstWhere(
          (u) => u.username.toLowerCase() == username.toLowerCase(),
        );
      } catch (_) {
        return null;
      }
    }
  }

  Future<List<User>> getAllUsers() async {
    if (!_dbAvailable) {
      return List<User>.from(_inMemoryUsers);
    }
    try {
      final db = await database;
      final result = await db.query('users', orderBy: 'createdAt DESC');
      return result.map((json) => User.fromMap(json)).toList();
    } catch (e) {
      _dbAvailable = false;
      return List<User>.from(_inMemoryUsers);
    }
  }

  Future<List<User>> getLocalStudentsWithUnlinkedHistory() async {
    final users = (await getAllUsers())
        .where((user) => user.role == 'student' && user.remoteStudentId == null)
        .toList();
    final studentsWithHistory = <User>[];
    for (final user in users) {
      if (user.id == null) continue;
      final sessions = await buscarPartidasUsuario(user.id!);
      if (sessions.any((session) => session['remote_student_id'] == null)) {
        studentsWithHistory.add(user);
      }
    }
    return studentsWithHistory;
  }

  Future<int> updateUser(User user) async {
    if (!_dbAvailable) {
      final idx = _inMemoryUsers.indexWhere((u) => u.id == user.id);
      if (idx >= 0) {
        _inMemoryUsers[idx] = user;
        return 1;
      }
      return 0;
    }
    final db = await database;
    final map = user.toMap();
    // Ensure nullable profilePhotoPath maps to DB column name
    return db.update('users', map, where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> deleteUser(int id) async {
    if (!_dbAvailable) {
      final idx = _inMemoryUsers.indexWhere((u) => u.id == id);
      if (idx >= 0) {
        _inMemoryUsers.removeAt(idx);
        _inMemoryQuestionAttempts.removeWhere((row) => row['usuario_id'] == id);
        _inMemoryPartidas.removeWhere((row) => row['usuario_id'] == id);
        _inMemoryDailyMissionRewards.removeWhere((row) => row['user_id'] == id);
        _inMemoryTeacherAssignments.removeWhere((row) => row.teacherId == id);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return db.transaction((transaction) async {
      // A ordem tambem funciona para bancos legados sem ON DELETE CASCADE.
      await transaction.delete(
        'quiz_question_attempts',
        where: 'usuario_id = ?',
        whereArgs: [id],
      );
      for (final table in <String>[
        'user_stats',
        'user_progress',
        'user_achievements',
        'user_rankings',
      ]) {
        await transaction.delete(table, where: 'userId = ?', whereArgs: [id]);
      }
      await transaction.delete(
        'daily_mission_rewards',
        where: 'user_id = ?',
        whereArgs: [id],
      );
      await transaction.delete(
        'teacher_assignments',
        where: 'teacherId = ?',
        whereArgs: [id],
      );
      await transaction.delete(
        'teacher_invites',
        where: 'usedByUserId = ?',
        whereArgs: [id],
      );
      await transaction.delete(
        'partidas',
        where: 'usuario_id = ?',
        whereArgs: [id],
      );
      return transaction.delete('users', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Exportacao local para o titular/responsavel. O hash de senha nunca sai
  /// do armazenamento interno.
  Future<Map<String, dynamic>> exportUserData(int id) async {
    if (!_dbAvailable) {
      User? user;
      for (final item in _inMemoryUsers) {
        if (item.id == id) {
          user = item;
          break;
        }
      }
      if (user == null) return const <String, dynamic>{};
      final profile = Map<String, dynamic>.from(user.toMap())
        ..remove('password');
      return {
        'profile': profile,
        'partidas': _inMemoryPartidas
            .where((row) => row['usuario_id'] == id)
            .toList(),
        'questionAttempts': _inMemoryQuestionAttempts
            .where((row) => row['usuario_id'] == id)
            .toList(),
        'dailyMissionRewards': _inMemoryDailyMissionRewards
            .where((row) => row['user_id'] == id)
            .toList(),
      };
    }

    final db = await database;
    final users = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (users.isEmpty) return const <String, dynamic>{};
    final profile = Map<String, dynamic>.from(users.first)..remove('password');
    return {
      'profile': profile,
      'stats': await db.query(
        'user_stats',
        where: 'userId = ?',
        whereArgs: [id],
      ),
      'progress': await db.query(
        'user_progress',
        where: 'userId = ?',
        whereArgs: [id],
      ),
      'achievements': await db.query(
        'user_achievements',
        where: 'userId = ?',
        whereArgs: [id],
      ),
      'ranking': await db.query(
        'user_rankings',
        where: 'userId = ?',
        whereArgs: [id],
      ),
      'partidas': await db.query(
        'partidas',
        where: 'usuario_id = ?',
        whereArgs: [id],
      ),
      'questionAttempts': await db.query(
        'quiz_question_attempts',
        where: 'usuario_id = ?',
        whereArgs: [id],
      ),
      'dailyMissionRewards': await db.query(
        'daily_mission_rewards',
        where: 'user_id = ?',
        whereArgs: [id],
      ),
      'teacherAssignments': await db.query(
        'teacher_assignments',
        where: 'teacherId = ?',
        whereArgs: [id],
      ),
    };
  }

  // Métodos para Estatísticas
  Future<void> updateUserStats(
    int userId,
    String subject,
    String topic,
    bool wasCorrect,
  ) async {
    final db = await database;
    await db.insert('user_stats', {
      'userId': userId,
      'subject': subject,
      'topic': topic,
      'correctAnswers': wasCorrect ? 1 : 0,
      'totalQuestions': 1,
      'lastPlayed': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>> getUserStats(int userId) async {
    final db = await database;
    final results = await db.query(
      'user_stats',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    int totalQuestions = 0;
    int correctAnswers = 0;
    for (var row in results) {
      totalQuestions += (row['totalQuestions'] as int?) ?? 0;
      correctAnswers += (row['correctAnswers'] as int?) ?? 0;
    }

    return {
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'accuracy': totalQuestions > 0
          ? (correctAnswers / totalQuestions * 100).toStringAsFixed(1)
          : '0',
    };
  }

  // Métodos para Progresso
  Future<void> updateUserProgress(
    int userId,
    String subject,
    String grade,
    String topic,
  ) async {
    final db = await database;
    await db.insert('user_progress', {
      'userId': userId,
      'subject': subject,
      'grade': grade,
      'topic': topic,
      'completed': 1,
      'completedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Persistir conquista desbloqueada
  Future<void> saveUserAchievement(
    int userId,
    String tipo,
    int pontos,
    DateTime dataDesbloqueio,
  ) async {
    if (!_dbAvailable) return;
    final db = await database;
    await db.insert('user_achievements', {
      'userId': userId,
      'tipo': tipo,
      'pontos': pontos,
      'data_desbloqueio': dataDesbloqueio.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveUserRankingPosition(
    int userId,
    int position,
    DateTime updatedAt,
  ) async {
    if (!_dbAvailable) return;
    final db = await database;
    await db.insert('user_rankings', {
      'userId': userId,
      'position': position,
      'updatedAt': updatedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int?> getLastRankingPosition(int userId) async {
    if (!_dbAvailable) return null;
    final db = await database;
    final rows = await db.query(
      'user_rankings',
      columns: ['position'],
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['position'] as int?;
  }

  Future<List<Map<String, dynamic>>> buscarConquistasUsuario(int userId) async {
    if (!_dbAvailable) return [];
    final db = await database;
    return await db.query(
      'user_achievements',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'data_desbloqueio DESC',
    );
  }

  Future<Map<String, int>> getUserProgress(int userId) async {
    final db = await database;
    final results = await db.query(
      'user_progress',
      where: 'userId = ? AND completed = 1',
      whereArgs: [userId],
    );

    return {'totalTopicsCompleted': results.length};
  }

  // Método para fechar o banco de dados
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
