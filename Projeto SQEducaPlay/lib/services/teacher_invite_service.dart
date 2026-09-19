import 'dart:math';

import '../database/app_database.dart';
import '../models/teacher_invite_model.dart';

class TeacherInviteService {
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final Random _random;

  TeacherInviteService({Random? random}) : _random = random ?? Random.secure();

  String _generateCode() {
    String group() => List.generate(
          4,
          (_) => _alphabet[_random.nextInt(_alphabet.length)],
        ).join();
    return 'SQ-${group()}-${group()}';
  }

  Future<TeacherInvite> issueInvite({
    required String schoolId,
    String? createdByUsername,
    Duration validFor = const Duration(days: 14),
  }) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        return await AppDatabase.instance.createTeacherInvite(
          code: _generateCode(),
          schoolId: schoolId,
          createdByUsername: createdByUsername,
          validFor: validFor,
        );
      } on ArgumentError {
        if (attempt == 4) rethrow;
      }
    }
    throw StateError('Não foi possível gerar o convite.');
  }

  Future<TeacherInvite?> getByCode(String code) {
    return AppDatabase.instance.getTeacherInviteByCode(code);
  }
}
