import 'dart:math';

import 'backend_service.dart';

abstract final class QuizSyncService {
  static Future<void> submit({
    required String subject,
    required String grade,
    required String? topic,
    required List<Map<String, dynamic>> questions,
    required List<String?> selectedAnswers,
    required List<bool?> progress,
  }) async {
    final backend = BackendService.instance;
    if (!backend.isInitialized || backend.client.auth.currentUser == null) {
      return;
    }

    final attempts = List.generate(questions.length, (index) {
      final question = questions[index];
      final options = (question['opcoes'] as List).cast<String>();
      final selected = selectedAnswers[index];
      return {
        'questionKey':
            '$subject|$grade|${topic ?? 'geral'}|${question['pergunta']}',
        'selectedOption': selected == null ? null : options.indexOf(selected),
        'isCorrect': progress[index] == true,
      };
    });

    await backend.client.rpc(
      'submit_quiz_session',
      params: {
        'p_client_session_id': _uuidV4(),
        'p_content_version': 1,
        'p_attempts': attempts,
      },
    );
  }

  static String _uuidV4() {
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
}
