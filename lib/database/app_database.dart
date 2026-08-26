import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqeducaplay/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
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
      CREATE TABLE IF NOT EXISTS daily_mission_rewards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        reward_date TEXT NOT NULL,
        stars INTEGER NOT NULL,
        UNIQUE(user_id, reward_date),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Correção P0-03: convites de uso único para criação de conta de
    // educador. Sem um código válido e não usado, a tela de primeiro
    // acesso do educador não deve permitir criar a conta.
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
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    try {
      return await openDatabase(
        path,
        version: 10,
        onCreate: _createDB,
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          // Upgrade path: v1 -> v2 add profilePhotoPath column to users
          if (oldVersion < 2) {
            try {
              await db.execute("ALTER TABLE users ADD COLUMN profilePhotoPath TEXT");
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
              await db.execute('ALTER TABLE users ADD COLUMN guardianName TEXT');
              await db.execute('ALTER TABLE users ADD COLUMN consentAt TEXT');
              await db.execute('ALTER TABLE users ADD COLUMN consentVersion TEXT');
            } catch (_) {}
          }
          if (oldVersion < 9) {
            await _ensureRequiredTables(db);
          }
          if (oldVersion < 10) {
            await _ensureRequiredTables(db);
          }
        },
        onOpen: (Database db) async {
          await _ensureRequiredTables(db);
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
        pontuacao_total INTEGER DEFAULT 0,
        estrelas_total INTEGER DEFAULT 0,
        profilePhotoPath $textNullable,
        guardianName $textNullable,
        consentAt TEXT,
        consentVersion $textNullable,
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
        FOREIGN KEY (usuario_id) REFERENCES users (id)
      )
    ''');

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
        code TEXT NOT NULL UNIQUE,
        schoolId $textType,
        createdByUsername $textNullable,
        createdAt $textType,
        expiresAt $textType,
        usedAt TEXT,
        usedByUserId INTEGER,
        FOREIGN KEY (usedByUserId) REFERENCES users (id)
      )
    ''');

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

    // Atualizar progresso por matéria
    try {
      await updateUserProgress(
        partida['usuario_id'] as int,
        partida['materia'] as String,
        partida['ano'] as String,
        partida['topico'] as String? ?? '',
      );
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
        (reward) => reward['user_id'] == userId && reward['reward_date'] == rewardDate,
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
          'resposta_selecionada': tentativa['resposta_selecionada'] as String? ?? '',
          'resposta_correta': tentativa['resposta_correta'] as String? ?? '',
          'acertou': (tentativa['acertou'] == true) ? 1 : 0,
          'ordem_pergunta': tentativa['ordem_pergunta'] as int? ?? i,
          'data_tentativa': tentativa['data_tentativa'] as String? ?? DateTime.now().toIso8601String(),
        });
      }
      return;
    }

    final db = await database;
    final batch = db.batch();
    for (var i = 0; i < tentativas.length; i++) {
      final tentativa = tentativas[i];
      batch.insert(
        'quiz_question_attempts',
        {
          'partida_id': partidaId,
          'usuario_id': usuarioId,
          'materia': materia,
          'ano': ano,
          'topico': topico,
          'pergunta': tentativa['pergunta'] as String? ?? '',
          'resposta_selecionada': tentativa['resposta_selecionada'] as String? ?? '',
          'resposta_correta': tentativa['resposta_correta'] as String? ?? '',
          'acertou': (tentativa['acertou'] == true) ? 1 : 0,
          'ordem_pergunta': tentativa['ordem_pergunta'] as int? ?? i,
          'data_tentativa': tentativa['data_tentativa'] as String? ?? DateTime.now().toIso8601String(),
        },
      );
    }
    await batch.commit(noResult: true);
  }

  Future<Map<String, int>> _getUserTotalsFromPartidas(int userId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        COALESCE(SUM(pontuacao), 0) AS pontuacao_total,
        COALESCE(SUM(estrelas), 0) AS estrelas_total
      FROM partidas
      WHERE usuario_id = ?
    ''', [userId]);

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
    await db.update(
      'users',
      totals,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<List<Map<String, dynamic>>> buscarUltimasPartidas(int usuarioId, {int limit = 10}) async {
    if (!_dbAvailable) {
      final partidas = _inMemoryPartidas
          .where((partida) => partida['usuario_id'] == usuarioId)
          .toList()
        ..sort((a, b) => (b['data_partida'] as String? ?? '')
            .compareTo(a['data_partida'] as String? ?? ''));
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

  Future<List<Map<String, dynamic>>> buscarPartidasUsuario(int usuarioId) async {
    if (!_dbAvailable) {
      final partidas = _inMemoryPartidas
          .where((partida) => partida['usuario_id'] == usuarioId)
          .toList()
        ..sort((a, b) => (b['data_partida'] as String? ?? '')
            .compareTo(a['data_partida'] as String? ?? ''));
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
      final rows = _inMemoryQuestionAttempts.where((row) {
        if ((row['usuario_id'] as int?) != usuarioId) return false;
        if (somenteErros && (row['acertou'] as int?) != 0) return false;
        return true;
      }).toList()
        ..sort((a, b) => (b['data_tentativa'] as String).compareTo(a['data_tentativa'] as String));
      return rows.take(limit).map((row) => Map<String, dynamic>.from(row)).toList();
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
      final rows = _inMemoryQuestionAttempts.where((row) => (row['ano'] as String? ?? '') == ano).toList()
        ..sort((a, b) => (b['data_tentativa'] as String).compareTo(a['data_tentativa'] as String));
      return rows.take(limit).map((row) => Map<String, dynamic>.from(row)).toList();
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

  Future<List<Map<String, dynamic>>> buscarTentativasErrosPorAno(String ano, {int limit = 50}) async {
    if (!_dbAvailable) {
      final rows = _inMemoryQuestionAttempts.where((row) => (row['ano'] as String? ?? '') == ano && (row['acertou'] as int?) == 0).toList();
      final grouped = <String, Map<String, dynamic>>{};
      for (final row in rows) {
        final pergunta = row['pergunta'] as String? ?? '';
        final entry = grouped.putIfAbsent(pergunta, () => {
          'pergunta': pergunta,
          'total_erros': 0,
          'materia': row['materia'],
          'topico': row['topico'],
        });
        entry['total_erros'] = (entry['total_erros'] as int) + 1;
      }
      final result = grouped.values.toList()
        ..sort((a, b) => (b['total_erros'] as int).compareTo(a['total_erros'] as int));
      return result.take(limit).toList();
    }

    final db = await database;
    return await db.rawQuery('''
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
    ''', [ano, limit]);
  }

  Future<Map<String, dynamic>> buscarEstatisticasUsuario(int usuarioId) async {
    final db = await database;
    final usuario = await getUser(usuarioId);

    final partidasAgg = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_partidas,
        SUM(acertos) as total_acertos,
        SUM(total_perguntas) as total_perguntas,
        AVG(pontuacao) as media_pontuacao
      FROM partidas
      WHERE usuario_id = ?
    ''', [usuarioId]);

    // Agrega progresso por matéria/ano a partir do histórico de partidas
    final progressoAgg = await db.rawQuery('''
      SELECT
        materia as materia,
        ano as ano,
        SUM(acertos) as total_acertos,
        SUM(total_perguntas) as total_perguntas,
        MAX(pontuacao) as melhor_pontuacao
      FROM partidas
      WHERE usuario_id = ?
      GROUP BY materia, ano
    ''', [usuarioId]);

    // Normaliza para o formato esperado pela UI
    final progressoPorMateria = progressoAgg.map((row) => {
      'materia': row['materia'] as String? ?? '-',
      'ano': row['ano'] as String? ?? '',
      'total_acertos': (row['total_acertos'] as int?) ?? 0,
      'total_perguntas': (row['total_perguntas'] as int?) ?? 0,
      'melhor_pontuacao': (row['melhor_pontuacao'] as int?) ?? 0,
    }).toList();

    // Normaliza o resultado da agregação para garantir tipos não-nulos
    final rawAgg = partidasAgg.isNotEmpty ? partidasAgg.first : <String, Object?>{};
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

  Future<List<Map<String, dynamic>>> buscarTodoProgressoUsuario(int usuarioId) async {
    final db = await database;
    return await db.query(
      'user_progress',
      where: 'userId = ?',
      whereArgs: [usuarioId],
      orderBy: 'subject, grade',
    );
  }

  Future<List<Map<String, dynamic>>> buscarRankingGeral({int limit = 10}) async {
    if (!_dbAvailable) {
      final ranking = <Map<String, dynamic>>[];
      for (final user in _inMemoryUsers.where((item) => item.role == 'student')) {
        final partidas = _inMemoryPartidas.where((partida) => partida['usuario_id'] == user.id);
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
            'estrelas_total': estrelas + _inMemoryDailyMissionRewards
              .where((reward) => reward['user_id'] == user.id)
              .fold<int>(0, (total, reward) => total + (reward['stars'] as int)),
          });
        }
      }
      ranking.sort((a, b) {
        final pontos = (b['pontuacao_total'] as int).compareTo(a['pontuacao_total'] as int);
        return pontos != 0
            ? pontos
            : (b['estrelas_total'] as int).compareTo(a['estrelas_total'] as int);
      });
      return ranking.take(limit).toList();
    }

    final db = await database;
    return await db.rawQuery('''
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
    ''', [limit]);
  }

  Future<List<Map<String, dynamic>>> buscarRankingPorMateria(String materia, {int limit = 10}) async {
    if (!_dbAvailable) {
      final ranking = <Map<String, dynamic>>[];
      for (final user in _inMemoryUsers.where((item) => item.role == 'student')) {
        final partidas = _inMemoryPartidas.where(
          (partida) => partida['usuario_id'] == user.id && partida['materia'] == materia,
        ).toList();
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
        final pontos = (b['pontuacao_materia'] as int)
            .compareTo(a['pontuacao_materia'] as int);
        return pontos != 0
            ? pontos
            : (b['estrelas_materia'] as int)
                .compareTo(a['estrelas_materia'] as int);
      });
      return ranking.take(limit).toList();
    }

    final db = await database;
    return await db.rawQuery('''
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
    ''', [materia, limit]);
  }

  // CRUD Operations para Usuários
  Future<User> createUser(User user) async {
    final hashedPassword = PasswordService.hashIfNeeded(user.password);
    if (!_dbAvailable) {
      final id = _inMemoryNextId++;
      final u = user.copy(id: id, password: hashedPassword, createdAt: DateTime.now());
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
      'profilePhotoPath': user.profilePhotoPath,
      'guardianName': user.guardianName,
      'consentAt': user.consentAt?.toIso8601String(),
      'consentVersion': user.consentVersion,
      'role': user.role,
      'pontuacao_total': 0,
      'estrelas_total': 0,
      'createdAt': createdAt.toIso8601String(),
    });
    return user.copy(id: id, password: hashedPassword, createdAt: createdAt);
  }

  Future<TeacherAssignment> createTeacherAssignment(TeacherAssignment assignment) async {
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
    final id = await db.insert('teacher_assignments', assignment.toMap()..remove('id'));
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
      return _inMemoryTeacherAssignments.where((item) => item.teacherId == teacherId).toList();
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

  // ---------------------------------------------------------------------
  // Convites de educador (P0-03): a criação de conta de educador só é
  // permitida mediante um código de uso único, emitido por um
  // administrador para UMA escola específica.
  // ---------------------------------------------------------------------

  Future<TeacherInvite> createTeacherInvite({
    required String code,
    required String schoolId,
    String? createdByUsername,
    Duration validFor = const Duration(days: 14),
  }) async {
    final now = DateTime.now();
    final invite = TeacherInvite(
      code: code,
      schoolId: schoolId,
      createdByUsername: createdByUsername,
      createdAt: now,
      expiresAt: now.add(validFor),
    );

    if (!_dbAvailable) {
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
    await _ensureRequiredTables(db);
    final id = await db.insert('teacher_invites', invite.toMap()..remove('id'));
    return TeacherInvite(
      id: id,
      code: invite.code,
      schoolId: invite.schoolId,
      createdByUsername: invite.createdByUsername,
      createdAt: invite.createdAt,
      expiresAt: invite.expiresAt,
    );
  }

  Future<TeacherInvite?> getTeacherInviteByCode(String code) async {
    final normalized = code.trim();
    if (normalized.isEmpty) return null;

    if (!_dbAvailable) {
      try {
        return _inMemoryTeacherInvites.firstWhere((invite) => invite.code == normalized);
      } catch (_) {
        return null;
      }
    }

    final db = await database;
    final result = await db.query(
      'teacher_invites',
      where: 'code = ?',
      whereArgs: [normalized],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return TeacherInvite.fromMap(result.first);
  }

  Future<List<TeacherInvite>> listTeacherInvites({String? schoolId}) async {
    if (!_dbAvailable) {
      return _inMemoryTeacherInvites
          .where((invite) => schoolId == null || invite.schoolId == schoolId)
          .toList();
    }

    final db = await database;
    final result = await db.query(
      'teacher_invites',
      where: schoolId != null ? 'schoolId = ?' : null,
      whereArgs: schoolId != null ? [schoolId] : null,
      orderBy: 'createdAt DESC',
    );
    return result.map(TeacherInvite.fromMap).toList();
  }

  /// Cria a conta de educador e consome o convite em uma única operação
  /// atômica: se o convite não existir, já tiver sido usado, estiver
  /// expirado, for de outra escola, ou o nome de usuário já existir,
  /// nada é gravado. Lança [ArgumentError] com uma mensagem adequada para
  /// exibir ao usuário.
  Future<User> createTeacherFromInvite({
    required String inviteCode,
    required User teacher,
    required List<TeacherAssignment> assignments,
  }) async {
    if (assignments.isEmpty) {
      throw ArgumentError('Adicione pelo menos uma turma.');
    }

    final normalizedCode = inviteCode.trim();
    if (normalizedCode.isEmpty) {
      throw ArgumentError('Informe o código de convite fornecido pela escola.');
    }

    final hashedPassword = PasswordService.hashIfNeeded(teacher.password);
    final now = DateTime.now();

    if (!_dbAvailable) {
      final inviteIdx = _inMemoryTeacherInvites.indexWhere((i) => i.code == normalizedCode);
      if (inviteIdx < 0) {
        throw ArgumentError('Código de convite inválido.');
      }
      final invite = _inMemoryTeacherInvites[inviteIdx];
      if (!invite.isValidAt(now)) {
        throw ArgumentError(invite.isUsed
            ? 'Este código de convite já foi utilizado.'
            : 'Este código de convite expirou. Solicite um novo à escola.');
      }
      if (invite.schoolId != teacher.schoolId) {
        throw ArgumentError('Este código de convite não é válido para a escola selecionada.');
      }
      if (_inMemoryUsers.any((u) => u.username.toLowerCase() == teacher.username.toLowerCase())) {
        throw ArgumentError('Este nome de usuário já existe.');
      }

      final id = _inMemoryNextId++;
      final created = teacher.copy(id: id, password: hashedPassword, createdAt: now);
      _inMemoryUsers.add(created);
      for (final assignment in assignments) {
        _inMemoryTeacherAssignments.add(TeacherAssignment(
          id: _inMemoryNextTeacherAssignmentId++,
          teacherId: id,
          schoolId: assignment.schoolId,
          grade: assignment.grade,
          classGroup: assignment.classGroup,
          shift: assignment.shift,
          schedule: assignment.schedule,
        ));
      }
      _inMemoryTeacherInvites[inviteIdx] = TeacherInvite(
        id: invite.id,
        code: invite.code,
        schoolId: invite.schoolId,
        createdByUsername: invite.createdByUsername,
        createdAt: invite.createdAt,
        expiresAt: invite.expiresAt,
        usedAt: now,
        usedByUserId: id,
      );
      return created;
    }

    final db = await database;
    await _ensureRequiredTables(db);

    return db.transaction<User>((txn) async {
      final inviteRows = await txn.query(
        'teacher_invites',
        where: 'code = ?',
        whereArgs: [normalizedCode],
        limit: 1,
      );
      if (inviteRows.isEmpty) {
        throw ArgumentError('Código de convite inválido.');
      }
      final invite = TeacherInvite.fromMap(inviteRows.first);
      if (!invite.isValidAt(now)) {
        throw ArgumentError(invite.isUsed
            ? 'Este código de convite já foi utilizado.'
            : 'Este código de convite expirou. Solicite um novo à escola.');
      }
      if (invite.schoolId != teacher.schoolId) {
        throw ArgumentError('Este código de convite não é válido para a escola selecionada.');
      }

      final existingUser = await txn.query(
        'users',
        where: 'username = ?',
        whereArgs: [teacher.username],
        limit: 1,
      );
      if (existingUser.isNotEmpty) {
        throw ArgumentError('Este nome de usuário já existe.');
      }

      final userId = await txn.insert('users', {
        'username': teacher.username,
        'password': hashedPassword,
        'fullName': teacher.fullName,
        'nickname': teacher.nickname,
        'grade': teacher.grade,
        'classGroup': teacher.classGroup,
        'schoolId': teacher.schoolId,
        'profilePhotoPath': teacher.profilePhotoPath,
        'guardianName': teacher.guardianName,
        'consentAt': teacher.consentAt?.toIso8601String(),
        'consentVersion': teacher.consentVersion,
        'role': teacher.role,
        'pontuacao_total': 0,
        'estrelas_total': 0,
        'createdAt': now.toIso8601String(),
      });

      for (final assignment in assignments) {
        await txn.insert('teacher_assignments', {
          'teacherId': userId,
          'schoolId': assignment.schoolId,
          'grade': assignment.grade,
          'classGroup': assignment.classGroup,
          'shift': assignment.shift,
          'schedule': assignment.schedule,
        });
      }

      final updatedRows = await txn.update(
        'teacher_invites',
        {'usedAt': now.toIso8601String(), 'usedByUserId': userId},
        where: 'id = ? AND usedAt IS NULL',
        whereArgs: [invite.id],
      );
      if (updatedRows != 1) {
        // Alguém consumiu o mesmo convite entre a leitura e a gravação
        // (corrida entre dois cadastros simultâneos). Aborta a transação
        // inteira para não deixar duas contas criadas com um convite só.
        throw ArgumentError('Este código de convite já foi utilizado.');
      }

      return teacher.copy(id: userId, password: hashedPassword, createdAt: now);
    });
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
      columns: ['id', 'username', 'password', 'fullName', 'nickname', 'grade', 'classGroup', 'schoolId', 'role', 'pontuacao_total', 'estrelas_total', 'profilePhotoPath', 'guardianName', 'consentAt', 'consentVersion', 'createdAt', 'lastLogin'],
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
        return _inMemoryUsers.firstWhere((u) => u.username.toLowerCase() == username.toLowerCase());
      } catch (_) {
        return null;
      }
    }
    try {
      final db = await database;
      final maps = await db.query(
        'users',
        columns: ['id', 'username', 'password', 'fullName', 'nickname', 'grade', 'classGroup', 'schoolId', 'role', 'pontuacao_total', 'estrelas_total', 'profilePhotoPath', 'guardianName', 'consentAt', 'consentVersion', 'createdAt', 'lastLogin'],
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
        return _inMemoryUsers.firstWhere((u) => u.username.toLowerCase() == username.toLowerCase());
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
    return db.update(
      'users',
      map,
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Apaga a conta e TODOS os dados associados ao usuário de forma atômica.
  ///
  /// Tabelas limpas: partidas, quiz_question_attempts, user_progress,
  /// user_stats, user_achievements, user_rankings, daily_mission_rewards,
  /// teacher_assignments e, por último, users.
  /// Também apaga o arquivo de foto de perfil, se existir.
  ///
  /// Retorna 1 se o usuário foi encontrado e removido, 0 caso contrário.
  Future<int> deleteUser(int id) async {
    if (!_dbAvailable) {
      final idx = _inMemoryUsers.indexWhere((u) => u.id == id);
      if (idx < 0) return 0;
      // Limpa dados relacionados em memória.
      _inMemoryPartidas.removeWhere((r) => r['usuario_id'] == id);
      _inMemoryQuestionAttempts.removeWhere((r) => r['usuario_id'] == id);
      _inMemoryDailyMissionRewards.removeWhere((r) => r['user_id'] == id);
      _inMemoryTeacherAssignments.removeWhere((r) => r.teacherId == id);
      _inMemoryUsers.removeAt(idx);
      return 1;
    }

    final db = await database;

    // Busca caminho da foto antes de apagar o registro.
    String? photoPath;
    try {
      final rows = await db.query('users', columns: ['profilePhotoPath'], where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isNotEmpty) photoPath = rows.first['profilePhotoPath'] as String?;
    } catch (_) {}

    int deleted = 0;
    await db.transaction((txn) async {
      // Habilita chaves estrangeiras dentro da transação.
      await txn.execute('PRAGMA foreign_keys = ON');

      // Apaga em cascata todos os dados do usuário.
      for (final table in [
        'quiz_question_attempts',
        'partidas',
        'user_progress',
        'user_stats',
        'user_achievements',
        'user_rankings',
        'daily_mission_rewards',
        'teacher_assignments',
      ]) {
        try {
          final col = (table == 'daily_mission_rewards') ? 'user_id' : 'userId';
          // partidas e quiz_question_attempts usam usuario_id
          final colFinal = (table == 'partidas' || table == 'quiz_question_attempts') ? 'usuario_id' : col;
          await txn.delete(table, where: '$colFinal = ?', whereArgs: [id]);
        } catch (_) {}
      }

      deleted = await txn.delete('users', where: 'id = ?', whereArgs: [id]);
    });

    // Apaga arquivo de foto fora da transação (operação de I/O).
    if (photoPath != null && photoPath.isNotEmpty) {
      try {
        final file = File(photoPath);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }

    return deleted;
  }

  /// Apaga a conta do usuário atual e limpa SharedPreferences.
  /// Retorna true se a exclusão foi bem-sucedida.
  Future<bool> deleteCurrentUserAccount(int userId) async {
    final deleted = await deleteUser(userId);
    if (deleted > 0) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('usuario_id');
        await prefs.remove('usuario_nome');
        await prefs.remove('usuario_grade');
      } catch (_) {}
    }
    return deleted > 0;
  }

  // Métodos para Estatísticas
  Future<void> updateUserStats(int userId, String subject, String topic, bool wasCorrect) async {
    final db = await database;
    await db.insert(
      'user_stats',
      {
        'userId': userId,
        'subject': subject,
        'topic': topic,
        'correctAnswers': wasCorrect ? 1 : 0,
        'totalQuestions': 1,
        'lastPlayed': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
      'accuracy': totalQuestions > 0 ? (correctAnswers / totalQuestions * 100).toStringAsFixed(1) : '0',
    };
  }

  // Métodos para Progresso
  Future<void> updateUserProgress(int userId, String subject, String grade, String topic) async {
    final db = await database;
    await db.insert(
      'user_progress',
      {
        'userId': userId,
        'subject': subject,
        'grade': grade,
        'topic': topic,
        'completed': 1,
        'completedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Persistir conquista desbloqueada
  Future<void> saveUserAchievement(int userId, String tipo, int pontos, DateTime dataDesbloqueio) async {
    if (!_dbAvailable) return;
    final db = await database;
    await db.insert(
      'user_achievements',
      {
        'userId': userId,
        'tipo': tipo,
        'pontos': pontos,
        'data_desbloqueio': dataDesbloqueio.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveUserRankingPosition(int userId, int position, DateTime updatedAt) async {
    if (!_dbAvailable) return;
    final db = await database;
    await db.insert(
      'user_rankings',
      {
        'userId': userId,
        'position': position,
        'updatedAt': updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

    return {
      'totalTopicsCompleted': results.length,
    };
  }

  // Método para fechar o banco de dados
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
