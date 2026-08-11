import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqeducaplay/models/user_model.dart';
import 'package:flutter/foundation.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;
  // Se o banco nativo não puder ser inicializado (web, plataforma sem sqflite),
  // usamos um fallback em memória para permitir funcionalidades básicas.
  bool _dbAvailable = true;
  final List<User> _inMemoryUsers = [];
  int _inMemoryNextId = 100000; // ids gerados para usuários em memória

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

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    try {
      return await openDatabase(
        path,
        version: 2,
        onCreate: _createDB,
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          // Upgrade path: v1 -> v2 add profilePhotoPath column to users
          if (oldVersion < 2) {
            try {
              await db.execute("ALTER TABLE users ADD COLUMN profilePhotoPath TEXT");
            } catch (_) {}
          }
        },
        onOpen: (Database db) async {
          // Garante que exista um usuário admin padrão (compatível mesmo se o DB
          // foi criado em versões antigas ou sem o admin). Busca case-insensitive.
          final admins = await db.query('users', where: 'LOWER(username) = ?', whereArgs: ['keinan']);
          if (admins.isEmpty) {
            await db.insert('users', {
              'username': 'Keinan',
              'password': 'keinan',
              'fullName': 'Professor Keinan',
              'role': 'teacher',
              'createdAt': DateTime.now().toIso8601String(),
            });
          } else if ((admins.first['role'] as String?) != 'teacher') {
            await db.update(
              'users',
              {
                'role': 'teacher',
                'fullName': 'Professor Keinan',
              },
              where: 'LOWER(username) = ?',
              whereArgs: ['keinan'],
            );
          }
        },
      );
    } catch (e) {
      // Provavelmente estamos em uma plataforma sem sqflite (ex: web). Marca
      // o DB como indisponível e mantém um fallback em memória.
      _dbAvailable = false;
      // Seed admin em memória caso ainda não exista
      final existingAdmin = _inMemoryUsers.where((u) => u.username.toLowerCase() == 'keinan').toList();
      if (existingAdmin.isEmpty) {
        _inMemoryUsers.add(User(
          id: _inMemoryNextId++,
          username: 'Keinan',
          password: 'keinan',
          fullName: 'Professor Keinan',
          role: 'teacher',
          createdAt: DateTime.now(),
        ));
      }
      throw Exception('DB not available on this platform: $e');
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

    // (exercícios e status removidos — funcionalidade adiada)

    // Inserir usuário admin padrão
    await db.insert('users', {
      'username': 'Keinan',
      'password': 'keinan',
      'fullName': 'Professor Keinan',
      'role': 'teacher',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // Exercícios: inserir
  // Exercise-related methods removed (feature deferred)

  // Salva uma partida (similar ao DatabaseHelper.salvarPartida)
  Future<int> salvarPartida(Map<String, dynamic> partida) async {
    if (!_dbAvailable) {
      // fallback: não persiste partidas no in-memory (poderíamos guardar em lista se necessário)
      return -1;
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
    if (!_dbAvailable) return [];
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
    if (!_dbAvailable) return [];
    final db = await database;
    return await db.query(
      'partidas',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'data_partida DESC',
    );
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
    final db = await database;
    return await db.query('users',
        columns: ['id', 'username as nome', 'pontuacao_total', 'estrelas_total'],
        orderBy: 'pontuacao_total DESC, estrelas_total DESC',
        limit: limit);
  }

  Future<List<Map<String, dynamic>>> buscarRankingPorMateria(String materia, {int limit = 10}) async {
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
    if (!_dbAvailable) {
      final id = _inMemoryNextId++;
      final u = user.copy(id: id, createdAt: DateTime.now());
      _inMemoryUsers.add(u);
      return u;
    }
    final db = await database;
    final id = await db.insert('users', {
      'username': user.username,
      'password': user.password,
      'fullName': user.fullName,
      'nickname': user.nickname,
      'grade': user.grade,
      'classGroup': user.classGroup,
      'schoolId': user.schoolId,
      'profilePhotoPath': user.profilePhotoPath,
      'role': user.role,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return user.copy(id: id);
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
      columns: ['id', 'username', 'password', 'fullName', 'nickname', 'grade', 'classGroup', 'schoolId', 'role', 'pontuacao_total', 'estrelas_total', 'profilePhotoPath', 'createdAt', 'lastLogin'],
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
        columns: ['id', 'username', 'password', 'fullName', 'nickname', 'grade', 'classGroup', 'schoolId', 'role', 'pontuacao_total', 'estrelas_total', 'profilePhotoPath', 'createdAt', 'lastLogin'],
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

  Future<int> deleteUser(int id) async {
    if (!_dbAvailable) {
      final idx = _inMemoryUsers.indexWhere((u) => u.id == id);
      if (idx >= 0) {
        _inMemoryUsers.removeAt(idx);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
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