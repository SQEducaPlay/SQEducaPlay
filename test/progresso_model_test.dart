import 'package:flutter_test/flutter_test.dart';
import 'package:sqeducaplay/models/progresso_model.dart';

void main() {
  test('registra um quiz e atualiza pontos, estrelas e materia', () {
    final progresso = ProgressoAluno(username: 'aluno');

    progresso.registrarQuizCompleto(
      materia: 'Matematica',
      pontos: 10,
      estrelas: 1,
      acertos: 4,
      erros: 1,
      perfeito: false,
      tempoSegundos: 90,
    );

    expect(progresso.pontuacaoTotal, 10);
    expect(progresso.estrelasTotal, 1);
    expect(progresso.quizesCompletados, 1);
    expect(progresso.quizesHoje, 1);
    expect(progresso.diasConsecutivos, 1);
    expect(progresso.quizesPorMateria['Matematica'], 1);
    expect(progresso.acertosPorMateria['Matematica'], 4);
    expect(progresso.errosPorMateria['Matematica'], 1);
    expect(progresso.quizRapidosTotal, 1);
  });

  test('mantem a sequencia de quizzes feitos no mesmo dia', () {
    final progresso = ProgressoAluno(username: 'aluno');

    for (var i = 0; i < 2; i++) {
      progresso.registrarQuizCompleto(
        materia: 'Portugues',
        pontos: 10,
        estrelas: 0,
        acertos: 5,
        erros: 0,
        perfeito: true,
        tempoSegundos: 180,
      );
    }

    expect(progresso.quizesHoje, 2);
    expect(progresso.diasConsecutivos, 1);
    expect(progresso.quizesPerfeitos, 2);
    expect(progresso.perfectsToday, 2);
    expect(progresso.consecutivePerfects, 2);
  });

  test('avanca de nivel ao atingir a pontuacao necessaria', () {
    final progresso = ProgressoAluno(username: 'aluno', pontuacaoTotal: 1050);

    expect(progresso.nivel, 'Iniciante');
    expect(progresso.proximoNivelPontos, 1850);
    expect(progresso.progressoNivel, 0);
  });
}
