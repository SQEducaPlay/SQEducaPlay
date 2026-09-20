import 'package:flutter_test/flutter_test.dart';
import 'package:sqeducaplay/services/quiz_scoring_service.dart';

void main() {
  const questions = [
    {'dificuldade': 'facil'},
    {'dificuldade': 'media'},
    {'dificuldade': 'dificil'},
    {'dificuldade': 'facil'},
    {'dificuldade': 'media'},
  ];

  test('soma a pontuacao conforme a dificuldade e bonus de conclusao', () {
    final score = QuizScoringService.calculateScore(
      questions: questions,
      answers: [true, true, true, false, false],
    );

    expect(score, 55);
  });

  test('aplica bonus de 80 por cento sem acumular bonus de 100 por cento', () {
    final score = QuizScoringService.calculateScore(
      questions: questions,
      answers: [true, true, true, true, false],
    );

    expect(score, 75);
  });

  test('aplica bonus maximo quando todas as respostas estao corretas', () {
    final score = QuizScoringService.calculateScore(
      questions: questions,
      answers: [true, true, true, true, true],
    );

    expect(score, 100);
  });
}
