class ProgressoAluno {
  final String username;
  int pontuacaoTotal;
  int estrelasTotal;
  int quizesCompletados;
  int quizesPerfeitos;
  int consecutivePerfects;
  int perfectsToday;
  Map<String, int> quizesPorMateria; // matéria -> quantidade
  Map<String, int> acertosPorMateria; // matéria -> acertos
  Map<String, int> errosPorMateria; // matéria -> erros
  Map<String, int> pontosPorMateria; // matéria -> pontos acumulados
  List<String> conquistasDesbloqueadas;
  DateTime? ultimoQuizData;
  int quizesHoje;
  int diasConsecutivos;
  int quizRapidosTotal; // < 120s
  int ultraRapidosTotal; // < 60s

  ProgressoAluno({
    required this.username,
    this.pontuacaoTotal = 0,
    this.estrelasTotal = 0,
    this.quizesCompletados = 0,
    this.quizesPerfeitos = 0,
    Map<String, int>? quizesPorMateria,
    Map<String, int>? acertosPorMateria,
    Map<String, int>? errosPorMateria,
    Map<String, int>? pontosPorMateria,
    List<String>? conquistasDesbloqueadas,
    this.ultimoQuizData,
    this.quizesHoje = 0,
    this.diasConsecutivos = 0,
    this.quizRapidosTotal = 0,
    this.ultraRapidosTotal = 0,
    this.consecutivePerfects = 0,
    this.perfectsToday = 0,
  })  : quizesPorMateria = quizesPorMateria ?? {},
        acertosPorMateria = acertosPorMateria ?? {},
        errosPorMateria = errosPorMateria ?? {},
        pontosPorMateria = pontosPorMateria ?? {},
        conquistasDesbloqueadas = conquistasDesbloqueadas ?? [];

  void registrarQuizCompleto({
    required String materia,
    required int pontos,
    required int estrelas,
    required int acertos,
    required int erros,
    required bool perfeito,
    int? tempoSegundos,
  }) {
    pontuacaoTotal += pontos;
    estrelasTotal += estrelas;
    quizesCompletados++;
    if (perfeito) {
      quizesPerfeitos++;
      consecutivePerfects++;
    } else {
      consecutivePerfects = 0;
    }

    // Atualiza por matéria
    quizesPorMateria[materia] = (quizesPorMateria[materia] ?? 0) + 1;
    acertosPorMateria[materia] = (acertosPorMateria[materia] ?? 0) + acertos;
    errosPorMateria[materia] = (errosPorMateria[materia] ?? 0) + erros;
    pontosPorMateria[materia] = (pontosPorMateria[materia] ?? 0) + pontos;

    // Atualiza contadores de velocidade
    if (tempoSegundos != null) {
      if (tempoSegundos < 120) quizRapidosTotal++;
      if (tempoSegundos < 60) ultraRapidosTotal++;
      if (perfeito && tempoSegundos < 30) {
        // marca conquista rara via ProgressoService
      }
    }

    // Atualiza contador diário e perfectsToday
    final hoje = DateTime.now();
    if (ultimoQuizData == null ||
        !_mesmaData(ultimoQuizData!, hoje)) {
      quizesHoje = 1;
      perfectsToday = perfeito ? 1 : 0;
    } else {
      quizesHoje++;
      if (perfeito) perfectsToday++;
    }
    ultimoQuizData = hoje;
  }

  bool _mesmaData(DateTime data1, DateTime data2) {
    return data1.year == data2.year &&
        data1.month == data2.month &&
        data1.day == data2.day;
  }

  void desbloquearConquista(String tipoConquista) {
    if (!conquistasDesbloqueadas.contains(tipoConquista)) {
      conquistasDesbloqueadas.add(tipoConquista);
    }
  }

  double get taxaAcertoGeral {
    int totalAcertos =
        acertosPorMateria.values.fold(0, (sum, value) => sum + value);
    int totalErros = errosPorMateria.values.fold(0, (sum, value) => sum + value);
    int total = totalAcertos + totalErros;
    return total > 0 ? (totalAcertos / total) * 100 : 0;
  }

  double taxaAcertoPorMateria(String materia) {
    int acertos = acertosPorMateria[materia] ?? 0;
    int erros = errosPorMateria[materia] ?? 0;
    int total = acertos + erros;
    return total > 0 ? (acertos / total) * 100 : 0;
  }

  String get nivel {
    final levels = [
      {'nome': 'Novato', 'limite': 150},
      {'nome': 'Iniciante', 'limite': 350},
      {'nome': 'Aprendiz', 'limite': 650},
      {'nome': 'Intermediário', 'limite': 1200},
      {'nome': 'Estudioso', 'limite': 2300},
      {'nome': 'Expert', 'limite': 3600},
      {'nome': 'Mestre', 'limite': double.infinity},
    ];
    for (var level in levels) {
      final limite = level['limite'] as num;
      if (pontuacaoTotal < limite) return level['nome'] as String;
    }
    return 'Mestre';
  }

  int get proximoNivelPontos {
    final thresholds = [150, 350, 650, 1200, 2300, 3600];
    for (var t in thresholds) {
      if (pontuacaoTotal < t) return t;
    }
    return 9999999;
  }

  double get progressoNivel {
    final levels = [
      0,
      150,
      350,
      650,
      1200,
      2300,
      3600,
    ];
    int lower = 0;
    int upper = levels.last;
    for (var i = 0; i < levels.length; i++) {
      final lim = levels[i];
      if (pontuacaoTotal < lim) {
        upper = lim;
        lower = i == 0 ? 0 : levels[i - 1];
        break;
      }
    }
    if (upper - lower == 0) return 100.0;
    return ((pontuacaoTotal - lower) / (upper - lower)) * 100;
  }
}
