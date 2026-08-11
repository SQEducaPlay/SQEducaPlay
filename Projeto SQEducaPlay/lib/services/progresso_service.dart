import '../database/app_database.dart';
import '../models/progresso_model.dart';
import '../models/conquista_model.dart';

class ProgressoService {
  static final ProgressoService _instance = ProgressoService._internal();
  factory ProgressoService() => _instance;
  ProgressoService._internal();

  final Map<String, ProgressoAluno> _progressos = {};
  final Map<String, Map<TipoConquista, Conquista>> _conquistasPorUsuario = {};

  Future<void> carregarDoBanco() async {
    _progressos.clear();
    _conquistasPorUsuario.clear();

    final usuarios = await AppDatabase.instance.getAllUsers();
    for (final usuario in usuarios) {
      if (usuario.id == null || usuario.role != 'student') {
        continue;
      }

      // Mantém `users.pontuacao_total` e `users.estrelas_total` sincronizados
      // com o histórico real salvo em `partidas`.
      try {
        await AppDatabase.instance.recalculateAndPersistUserTotals(usuario.id!);
      } catch (_) {}

      final partidas = await AppDatabase.instance.buscarPartidasUsuario(usuario.id!);
      final progresso = ProgressoAluno(username: usuario.username);
      final teveQuizRapido = _popularProgressoComPartidas(progresso, partidas);

      // Inicializa conquistas e aplica conquistas persistidas do DB
      _progressos[usuario.username] = progresso;
      _conquistasPorUsuario[usuario.username] = {
        for (final conquista in Conquista.todasConquistas()) conquista.tipo: conquista,
      };

      try {
        final saved = await AppDatabase.instance.buscarConquistasUsuario(usuario.id!);
        for (final row in saved) {
          final tipoStr = row['tipo'] as String? ?? '';
          final dataStr = row['data_desbloqueio'] as String?;
          TipoConquista? tipo;
          try {
            tipo = TipoConquista.values.firstWhere((t) => t.toString() == tipoStr);
          } catch (_) {
            tipo = null;
          }
          if (tipo != null) {
            final conquista = _conquistasPorUsuario[usuario.username]![tipo]!;
            final data = dataStr != null ? DateTime.tryParse(dataStr) : null;
            _conquistasPorUsuario[usuario.username]![tipo] = conquista.copyWith(
              desbloqueada: true,
              dataDesbloqueio: data ?? DateTime.now(),
            );
            // credita os pontos da conquista ao progresso
            progresso.pontuacaoTotal += conquista.pontos;
          }
        }
      } catch (_) {}

      await _reconstruirConquistas(usuario.username, progresso, partidas, teveQuizRapido: teveQuizRapido);
    }

    // Após reconstruir progresso para todos os usuários, calcula ranking e
    // verifica conquistas relacionadas a posição no ranking (top10, subir10posicoes).
    final ranking = getRanking();
    for (var i = 0; i < ranking.length; i++) {
      final p = ranking[i];
      final currentPos = i + 1;
      try {
        final user = await AppDatabase.instance.getUserByUsername(p.username);
        if (user != null && user.id != null) {
          final lastPos = await AppDatabase.instance.getLastRankingPosition(user.id!);

          // desbloqueia top10
          if (currentPos <= 10) {
            await _desbloquearSeNecessario(p.username, TipoConquista.top10);
          }
              // desbloqueia top3
              if (currentPos <= 3) {
                await _desbloquearSeNecessario(p.username, TipoConquista.top3);
              }

          // verifica subida de 10 posições
          if (lastPos != null && (lastPos - currentPos) >= 10) {
            await _desbloquearSeNecessario(p.username, TipoConquista.subir10posicoes);
          }
              if (lastPos != null && (lastPos - currentPos) >= 15) {
                await _desbloquearSeNecessario(p.username, TipoConquista.subir15posicoes);
              }
              if (lastPos != null && (lastPos - currentPos) >= 20) {
                await _desbloquearSeNecessario(p.username, TipoConquista.subir20posicoes);
              }
              if (lastPos != null && (currentPos - lastPos) >= 15) {
                // caiu e depois recuperou 15 posições (recuperar15posicoes)
                await _desbloquearSeNecessario(p.username, TipoConquista.recuperar15posicoes);
              }

          // salva nova posição
          await AppDatabase.instance.saveUserRankingPosition(user.id!, currentPos, DateTime.now());
        }
      } catch (_) {}
    }
  }

  ProgressoAluno getProgresso(String username) {
    return _progressos.putIfAbsent(
      username,
      () => ProgressoAluno(username: username),
    );
  }

  Map<TipoConquista, Conquista> getConquistas(String username) {
    if (!_conquistasPorUsuario.containsKey(username)) {
      _conquistasPorUsuario[username] = {};
      for (var conquista in Conquista.todasConquistas()) {
        _conquistasPorUsuario[username]![conquista.tipo] = conquista;
      }
    }
    return _conquistasPorUsuario[username]!;
  }

  Future<void> registrarResultadoQuiz({
    required String username,
    required String materia,
    required int pontos,
    required int estrelas,
    required int acertos,
    required int erros,
    required bool perfeito,
    required int tempoSegundos,
  }) {
    final progresso = getProgresso(username);
    progresso.registrarQuizCompleto(
      materia: materia,
      pontos: pontos,
      estrelas: estrelas,
      acertos: acertos,
      erros: erros,
      perfeito: perfeito,
      tempoSegundos: tempoSegundos,
    );

    // Verifica conquistas
    return _verificarConquistas(username, tempoSegundos, perfeito);
  }

  bool _popularProgressoComPartidas(ProgressoAluno progresso, List<Map<String, dynamic>> partidas) {
    if (partidas.isEmpty) {
      return false;
    }

    final hoje = DateTime.now();
    DateTime? ultimaData;
    int quizHoje = 0;
    bool teveQuizRapido = false;

    for (final partida in partidas) {
      final materia = partida['materia'] as String? ?? 'Sem matéria';
      final pontos = (partida['pontuacao'] as int?) ?? 0;
      final estrelas = (partida['estrelas'] as int?) ?? 0;
      final acertos = (partida['acertos'] as int?) ?? 0;
      final totalPerguntas = (partida['total_perguntas'] as int?) ?? 0;
      final tempoSegundos = (partida['tempo_segundos'] as int?) ?? 999999;
      final dataStr = partida['data_partida'] as String?;
      final data = dataStr != null ? DateTime.tryParse(dataStr) : null;

      // contabiliza quizzes rápidos/ultra
      if (tempoSegundos < 120) progresso.quizRapidosTotal++;
      if (tempoSegundos < 60) progresso.ultraRapidosTotal++;
      progresso.pontuacaoTotal += pontos;
      progresso.estrelasTotal += estrelas;
      progresso.quizesCompletados++;
      if (totalPerguntas > 0 && acertos >= totalPerguntas) {
        progresso.quizesPerfeitos++;
      }

      progresso.quizesPorMateria[materia] = (progresso.quizesPorMateria[materia] ?? 0) + 1;
      progresso.acertosPorMateria[materia] = (progresso.acertosPorMateria[materia] ?? 0) + acertos;
      progresso.pontosPorMateria[materia] = (progresso.pontosPorMateria[materia] ?? 0) + pontos;
      final erros = (totalPerguntas - acertos).clamp(0, totalPerguntas).toInt();
      progresso.errosPorMateria[materia] = (progresso.errosPorMateria[materia] ?? 0) + erros;

      if (data != null) {
        if (ultimaData == null || data.isAfter(ultimaData)) {
          ultimaData = data;
        }
        if (data.year == hoje.year && data.month == hoje.month && data.day == hoje.day) {
          quizHoje++;
        }
      }

      if (tempoSegundos < 120) {
        teveQuizRapido = true;
      }
    }

    progresso.ultimoQuizData = ultimaData;
    progresso.quizesHoje = quizHoje;
    // calcula perfectsToday e consecutivePerfects a partir do histórico
    int perfectsHoje = 0;
    final partidasComData = partidas
        .map((p) {
          final dataStr = p['data_partida'] as String?;
          final data = dataStr != null ? DateTime.tryParse(dataStr) : null;
          return {'partida': p, 'data': data};
        })
        .where((e) => e['data'] != null)
        .toList()
      ..sort((a, b) => (a['data'] as DateTime).compareTo(b['data'] as DateTime));

    int streak = 0;
    for (final entry in partidasComData) {
      final p = entry['partida'] as Map<String, dynamic>;
      final data = entry['data'] as DateTime;
      final totalPerguntas = (p['total_perguntas'] as int?) ?? 0;
      final acertos = (p['acertos'] as int?) ?? 0;
      if (totalPerguntas > 0 && acertos >= totalPerguntas) {
        if (_isSameDate(data, hoje)) perfectsHoje++;
        streak++;
      } else {
        streak = 0;
      }
    }
    progresso.perfectsToday = perfectsHoje;
    progresso.consecutivePerfects = streak;
    return teveQuizRapido;
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _reconstruirConquistas(String username, ProgressoAluno progresso, List<Map<String, dynamic>> partidas, {required bool teveQuizRapido}) async {
    final conquistas = getConquistas(username);

    void desbloquearSeNecessario(TipoConquista tipo) {
      final conquista = conquistas[tipo];
      if (conquista == null || conquista.desbloqueada) {
        return;
      }
      conquistas[tipo] = conquista.copyWith(
        desbloqueada: true,
        dataDesbloqueio: DateTime.now(),
      );
      progresso.desbloquearConquista(tipo.toString());
      progresso.pontuacaoTotal += conquista.pontos;
    }

    if (progresso.quizesCompletados >= 1) {
      await _desbloquearSeNecessario(username, TipoConquista.primeiraVitoria);
    }
    if (progresso.pontuacaoTotal >= 50) {
      await _desbloquearSeNecessario(username, TipoConquista.cinquentaPontos);
    }
    if (progresso.pontuacaoTotal >= 100) {
      await _desbloquearSeNecessario(username, TipoConquista.cemPontos);
    }
    if (progresso.quizesPerfeitos >= 5) {
      await _desbloquearSeNecessario(username, TipoConquista.cincoQuizesPerfeitos);
    }

    const materiasAtivas = ['Matemática', 'Português'];
    final materiasComQuiz = progresso.quizesPorMateria.keys
        .where((materia) => materiasAtivas.contains(materia))
        .toSet()
        .length;
    if (materiasComQuiz >= materiasAtivas.length) {
      desbloquearSeNecessario(TipoConquista.todasMaterias);
    }

    if (progresso.estrelasTotal >= 50) {
      await _desbloquearSeNecessario(username, TipoConquista.cinquentaEstrelas);
    }
    if (progresso.quizesCompletados >= 10) {
      await _desbloquearSeNecessario(username, TipoConquista.dezQuizes);
    }

    progresso.quizesPorMateria.forEach((materia, quantidade) {
      if (quantidade >= 10) {
        if (materia == 'Matemática') {
          desbloquearSeNecessario(TipoConquista.especialistaMat);
        } else if (materia == 'Português') {
          desbloquearSeNecessario(TipoConquista.especialistaPort);
        }
      }
    });

    if (progresso.quizesHoje >= 5) {
      // calcula dias consecutivos a partir das datas das partidas
      final dateSet = <DateTime>{};
      for (final partida in partidas) {
        final dataStr = partida['data_partida'] as String?;
        final data = dataStr != null ? DateTime.tryParse(dataStr) : null;
        if (data != null) {
          dateSet.add(DateTime(data.year, data.month, data.day));
        }
      }
      if (dateSet.isNotEmpty) {
        final dates = dateSet.toList()..sort((a, b) => b.compareTo(a));
        int streak = 0;
        DateTime cursor = dates.first;
        for (var d in dates) {
          if (d.year == cursor.year && d.month == cursor.month && d.day == cursor.day) {
            streak++;
            cursor = DateTime(cursor.year, cursor.month, cursor.day).subtract(const Duration(days: 1));
          } else if (d.isBefore(cursor)) {
            break;
          }
        }
        progresso.diasConsecutivos = streak;
      } else {
        progresso.diasConsecutivos = 0;
      }
      await _desbloquearSeNecessario(username, TipoConquista.persistente);
    }

    if (teveQuizRapido) {
      await _desbloquearSeNecessario(username, TipoConquista.velocista);
    }

    // Novas regras de conquistas
    // Especialistas 20/quizes e 2000 pontos por matéria
    if ((progresso.quizesPorMateria['Matemática'] ?? 0) >= 20) await _desbloquearSeNecessario(username, TipoConquista.especialista20Mat);
    if ((progresso.quizesPorMateria['Português'] ?? 0) >= 20) await _desbloquearSeNecessario(username, TipoConquista.especialista20Port);
    if ((progresso.pontosPorMateria['Matemática'] ?? 0) >= 2000) await _desbloquearSeNecessario(username, TipoConquista.pontos2000Mat);
    if ((progresso.pontosPorMateria['Português'] ?? 0) >= 2000) await _desbloquearSeNecessario(username, TipoConquista.pontos2000Port);

    // Conquista rara: 100% de acertos e <30s em qualquer partida histórica
    for (final partida in partidas) {
      final totalPerguntas = (partida['total_perguntas'] as int?) ?? 0;
      final acertos = (partida['acertos'] as int?) ?? 0;
      final tempoSegundos = (partida['tempo_segundos'] as int?) ?? 999999;
      if (totalPerguntas > 0 && acertos >= totalPerguntas && tempoSegundos < 30) {
        await _desbloquearSeNecessario(username, TipoConquista.raro100_30);
        break;
      }
    }
    if (progresso.diasConsecutivos >= 3) await _desbloquearSeNecessario(username, TipoConquista.tresDiasConsecutivos);
    if (progresso.diasConsecutivos >= 7) await _desbloquearSeNecessario(username, TipoConquista.seteDiasConsecutivos);
    if (progresso.diasConsecutivos >= 30) await _desbloquearSeNecessario(username, TipoConquista.trintaDiasConsecutivos);
    if (progresso.diasConsecutivos >= 90) await _desbloquearSeNecessario(username, TipoConquista.noventaDiasConsecutivos);
    if (progresso.quizesPerfeitos >= 10) await _desbloquearSeNecessario(username, TipoConquista.dezQuizesPerfeitos);
    if (progresso.quizesPerfeitos >= 25) await _desbloquearSeNecessario(username, TipoConquista.vinteCincoQuizesPerfeitos);
    if (progresso.ultraRapidosTotal >= 1) await _desbloquearSeNecessario(username, TipoConquista.ultravelocista);
    if (progresso.quizRapidosTotal >= 5) await _desbloquearSeNecessario(username, TipoConquista.velocistaAvancado);
    if (progresso.quizesCompletados >= 10 && progresso.taxaAcertoGeral >= 90) await _desbloquearSeNecessario(username, TipoConquista.accuracy90_10);
    if (progresso.quizesCompletados >= 5 && progresso.taxaAcertoGeral >= 95) await _desbloquearSeNecessario(username, TipoConquista.accuracy95_5);
    if (progresso.quizesCompletados >= 3) {
      // verifica se existem 3 partidas seguidas no mesmo dia: já contamos quizesHoje, mas maratona3 exige sequencia imediata
      if (progresso.quizesHoje >= 3) await _desbloquearSeNecessario(username, TipoConquista.maratona3);
    }
    if (progresso.quizesCompletados >= 50) await _desbloquearSeNecessario(username, TipoConquista.cinquentaQuizesTotal);

    // Especialistas 50/quizes por matéria
    if ((progresso.quizesPorMateria['Matemática'] ?? 0) >= 50) await _desbloquearSeNecessario(username, TipoConquista.especialista50Mat);
    if ((progresso.quizesPorMateria['Português'] ?? 0) >= 50) await _desbloquearSeNecessario(username, TipoConquista.especialista50Port);

    // Mestre de precisão: 95%+ em 50+ quizzes
    if (progresso.quizesCompletados >= 50 && progresso.taxaAcertoGeral >= 95) {
      await _desbloquearSeNecessario(username, TipoConquista.mestrePrecisao);
    }

    // Melhoria contínua: média de pontos por quiz nos últimos 30 dias >= 120% da média do período anterior (30-60 dias)
    try {
      final now = DateTime.now();
      final startLast30 = now.subtract(const Duration(days: 30));
      final startPrev30 = now.subtract(const Duration(days: 60));
      int sumLast = 0, cntLast = 0, sumPrev = 0, cntPrev = 0;
      for (final p in partidas) {
        final dataStr = p['data_partida'] as String?;
        final data = dataStr != null ? DateTime.tryParse(dataStr) : null;
        if (data == null) continue;
        final pontos = (p['pontuacao'] as int?) ?? 0;
        if (data.isAfter(startLast30)) {
          sumLast += pontos;
          cntLast++;
        } else if (data.isAfter(startPrev30) && data.isBefore(startLast30)) {
          sumPrev += pontos;
          cntPrev++;
        }
      }
      if (cntPrev > 0 && cntLast > 0) {
        final avgPrev = sumPrev / cntPrev;
        final avgLast = sumLast / cntLast;
        if (avgPrev > 0 && avgLast >= avgPrev * 1.2) {
          await _desbloquearSeNecessario(username, TipoConquista.melhoriaContinua);
        }
      }
    } catch (_) {}

    // Flash 10s histórico
    for (final p in partidas) {
      final tempoSegundos = (p['tempo_segundos'] as int?) ?? 999999;
      if (tempoSegundos < 10) {
        await _desbloquearSeNecessario(username, TipoConquista.flash10);
        break;
      }
    }

    // Tripla perfeição e maratona perfeita
    if (progresso.consecutivePerfects >= 3) await _desbloquearSeNecessario(username, TipoConquista.triplaPerfeicao);
    if (progresso.perfectsToday >= 5) await _desbloquearSeNecessario(username, TipoConquista.maratonaPerfeita);

    // Explorador de tópicos: exige pelo menos 1 quiz em cada matéria conhecida (ajustável)
    const knownMaterias = ['Matemática', 'Português', 'Ciências'];
    final temTodas = knownMaterias.every((m) => (progresso.quizesPorMateria[m] ?? 0) > 0);
    if (temTodas) await _desbloquearSeNecessario(username, TipoConquista.exploradorTopicos);

    // Colecionador 50% e Completionist
    final todas = Conquista.todasConquistas();
    final total = todas.length;
    final unlocked = getConquistas(username).values.where((c) => c.desbloqueada).length;
    if (unlocked >= (total / 2).ceil()) await _desbloquearSeNecessario(username, TipoConquista.colecionador50);
    if (unlocked == total) await _desbloquearSeNecessario(username, TipoConquista.completionist);

    // Comeback: tinha atividade >30 dias atrás e agora 3+ quizzes recentes (últimos 7 dias)
    try {
      final now = DateTime.now();
      final oldThreshold = now.subtract(const Duration(days: 30));
      final recentThreshold = now.subtract(const Duration(days: 7));
      final hadOld = partidas.any((p) {
        final dataStr = p['data_partida'] as String?;
        final data = dataStr != null ? DateTime.tryParse(dataStr) : null;
        return data != null && data.isBefore(oldThreshold);
      });
      final recentCount = partidas.where((p) {
        final dataStr = p['data_partida'] as String?;
        final data = dataStr != null ? DateTime.tryParse(dataStr) : null;
        return data != null && data.isAfter(recentThreshold);
      }).length;
      if (hadOld && recentCount >= 3) await _desbloquearSeNecessario(username, TipoConquista.comeback30dias);
    } catch (_) {}
  }

  Future<void> _verificarConquistas(String username, int tempoSegundos, bool perfeito) async {
    final progresso = getProgresso(username);
    final conquistas = getConquistas(username);

    // Primeira Vitória
    if (progresso.quizesCompletados >= 1 &&
        !conquistas[TipoConquista.primeiraVitoria]!.desbloqueada) {
      await _desbloquearConquista(username, TipoConquista.primeiraVitoria);
    }

    // 50 Pontos
    if (progresso.pontuacaoTotal >= 50 &&
        !conquistas[TipoConquista.cinquentaPontos]!.desbloqueada) {
      await _desbloquearConquista(username, TipoConquista.cinquentaPontos);
    }

    // 100 Pontos
    if (progresso.pontuacaoTotal >= 100 &&
        !conquistas[TipoConquista.cemPontos]!.desbloqueada) {
      _desbloquearConquista(username, TipoConquista.cemPontos);
    }

    // 5 Quizes Perfeitos
    if (progresso.quizesPerfeitos >= 5 &&
        !conquistas[TipoConquista.cincoQuizesPerfeitos]!.desbloqueada) {
      await _desbloquearConquista(username, TipoConquista.cincoQuizesPerfeitos);
    }

    // Todas as Matérias (ajustado para considerar somente matérias ativas)
    // Hoje o app suporta apenas Português e Matemática — desbloqueia quando o
    // aluno completar quizes em todas as matérias ativas.
    const List<String> materiasAtivas = ['Matemática', 'Português'];
    final materiasComQuiz = progresso.quizesPorMateria.keys
        .where((m) => materiasAtivas.contains(m))
        .toSet()
        .length;
    if (materiasComQuiz >= materiasAtivas.length &&
        !conquistas[TipoConquista.todasMaterias]!.desbloqueada) {
      _desbloquearConquista(username, TipoConquista.todasMaterias);
    }

    // 50 Estrelas
    if (progresso.estrelasTotal >= 50 &&
        !conquistas[TipoConquista.cinquentaEstrelas]!.desbloqueada) {
      await _desbloquearConquista(username, TipoConquista.cinquentaEstrelas);
    }

    // 10 Quizes
    if (progresso.quizesCompletados >= 10 &&
        !conquistas[TipoConquista.dezQuizes]!.desbloqueada) {
      await _desbloquearConquista(username, TipoConquista.dezQuizes);
    }

    // Especialistas por matéria (considera apenas matérias ativas)
    progresso.quizesPorMateria.forEach((materia, quantidade) {
      if (quantidade >= 10) {
        TipoConquista? tipo;
        if (materia == 'Matemática') tipo = TipoConquista.especialistaMat;
        if (materia == 'Português') tipo = TipoConquista.especialistaPort;

        if (tipo != null && !conquistas[tipo]!.desbloqueada) {
          _desbloquearConquista(username, tipo);
        }
      }
    });

    // Velocista (menos de 2 minutos = 120 segundos)
    if (tempoSegundos < 120 &&
        !conquistas[TipoConquista.velocista]!.desbloqueada) {
      await _desbloquearConquista(username, TipoConquista.velocista);
    }

    // Raro: 100% e <30s no quiz atual
    if (perfeito && tempoSegundos < 30 && !conquistas[TipoConquista.raro100_30]!.desbloqueada) {
      await _desbloquearConquista(username, TipoConquista.raro100_30);
    }

    // Flash 10s runtime
    if (tempoSegundos < 10 && !conquistas[TipoConquista.flash10]!.desbloqueada) {
      await _desbloquearConquista(username, TipoConquista.flash10);
    }

    // Tripla perfeição e maratona perfeita runtime
    if (progresso.consecutivePerfects >= 3 && !conquistas[TipoConquista.triplaPerfeicao]!.desbloqueada) {
      await _desbloquearConquista(username, TipoConquista.triplaPerfeicao);
    }
    if (progresso.perfectsToday >= 5 && !conquistas[TipoConquista.maratonaPerfeita]!.desbloqueada) {
      await _desbloquearConquista(username, TipoConquista.maratonaPerfeita);
    }

    // Checagens adicionais em runtime
    if (progresso.diasConsecutivos >= 3 && !conquistas[TipoConquista.tresDiasConsecutivos]!.desbloqueada) {
      await _desbloquearConquista(username, TipoConquista.tresDiasConsecutivos);
    }
    if (progresso.diasConsecutivos >= 7 && !conquistas[TipoConquista.seteDiasConsecutivos]!.desbloqueada) {
      await _desbloquearConquista(username, TipoConquista.seteDiasConsecutivos);
    }
    if (progresso.diasConsecutivos >= 30 && !conquistas[TipoConquista.trintaDiasConsecutivos]!.desbloqueada) {
      await _desbloquearConquista(username, TipoConquista.trintaDiasConsecutivos);
    }
    if (progresso.quizesPerfeitos >= 10 && !conquistas[TipoConquista.dezQuizesPerfeitos]!.desbloqueada) {
      await _desbloquearConquista(username, TipoConquista.dezQuizesPerfeitos);
    }
    if (progresso.quizesPerfeitos >= 25 && !conquistas[TipoConquista.vinteCincoQuizesPerfeitos]!.desbloqueada) {
      await _desbloquearConquista(username, TipoConquista.vinteCincoQuizesPerfeitos);
    }
    if (progresso.ultraRapidosTotal >= 1 && !conquistas[TipoConquista.ultravelocista]!.desbloqueada) {
      await _desbloquearConquista(username, TipoConquista.ultravelocista);
    }
    if (progresso.quizRapidosTotal >= 5 && !conquistas[TipoConquista.velocistaAvancado]!.desbloqueada) {
      await _desbloquearConquista(username, TipoConquista.velocistaAvancado);
    }
    if (progresso.quizesCompletados >= 10 && progresso.taxaAcertoGeral >= 90 && !conquistas[TipoConquista.accuracy90_10]!.desbloqueada) {
      await _desbloquearConquista(username, TipoConquista.accuracy90_10);
    }
    if (progresso.quizesCompletados >= 5 && progresso.taxaAcertoGeral >= 95 && !conquistas[TipoConquista.accuracy95_5]!.desbloqueada) {
      await _desbloquearConquista(username, TipoConquista.accuracy95_5);
    }
    if (progresso.quizesHoje >= 3 && !conquistas[TipoConquista.maratona3]!.desbloqueada) {
      await _desbloquearConquista(username, TipoConquista.maratona3);
    }
    if (progresso.quizesCompletados >= 50 && !conquistas[TipoConquista.cinquentaQuizesTotal]!.desbloqueada) {
      await _desbloquearConquista(username, TipoConquista.cinquentaQuizesTotal);
    }

    // Persistente (5 quizes no mesmo dia)
    if (progresso.quizesHoje >= 5 &&
        !conquistas[TipoConquista.persistente]!.desbloqueada) {
      _desbloquearConquista(username, TipoConquista.persistente);
    }
  }

  Future<void> _desbloquearConquista(String username, TipoConquista tipo) async {
    final conquistas = getConquistas(username);
    final conquista = conquistas[tipo]!;
    
    // já desbloqueada?
    if (conquista.desbloqueada) return;

    conquistas[tipo] = conquista.copyWith(
      desbloqueada: true,
      dataDesbloqueio: DateTime.now(),
    );
    
    final progresso = getProgresso(username);
    progresso.desbloquearConquista(tipo.toString());
    progresso.pontuacaoTotal += conquista.pontos;

    // Persiste no banco se possível
    try {
      final user = await AppDatabase.instance.getUserByUsername(username);
      if (user != null && user.id != null) {
        await AppDatabase.instance.saveUserAchievement(user.id!, tipo.toString(), conquista.pontos, DateTime.now());
      }
    } catch (_) {}
  }

  Future<void> _desbloquearSeNecessario(String username, TipoConquista tipo) async {
    final conquistas = getConquistas(username);
    if (conquistas[tipo] == null || conquistas[tipo]!.desbloqueada) return;
    await _desbloquearConquista(username, tipo);
  }

  List<ProgressoAluno> getRanking() {
    final lista = _progressos.values.toList();
    lista.sort((a, b) => b.pontuacaoTotal.compareTo(a.pontuacaoTotal));
    return lista;
  }

  int getPosicaoRanking(String username) {
    final ranking = getRanking();
    return ranking.indexWhere((p) => p.username == username) + 1;
  }
}
