class QuizScoringService {
  const QuizScoringService._();

  static const int completionBonus = 10;
  static const int performanceBonus80 = 10;
  static const int performanceBonus100 = 20;

  static int pointsForDifficulty(Object? value) {
    switch (value?.toString().trim().toLowerCase()) {
      case 'facil':
      case 'fácil':
      case 'easy':
        return 10;
      case 'dificil':
      case 'difícil':
      case 'hard':
        return 20;
      case 'media':
      case 'médio':
      case 'medio':
      case 'medium':
      default:
        return 15;
    }
  }

  static int calculateScore({
    required List<Map<String, dynamic>> questions,
    required List<bool?> answers,
  }) {
    final totalQuestions = questions.length;
    if (totalQuestions == 0) return 0;

    var score = 0;
    var correctAnswers = 0;
    for (var index = 0; index < totalQuestions; index++) {
      if (index < answers.length && answers[index] == true) {
        correctAnswers++;
        score += pointsForDifficulty(
          questions[index]['dificuldade'] ?? questions[index]['difficulty'],
        );
      }
    }

    final accuracy = correctAnswers / totalQuestions;
    score += completionBonus;
    if (accuracy >= 1) {
      score += performanceBonus100;
    } else if (accuracy >= 0.8) {
      score += performanceBonus80;
    }
    return score;
  }
}
