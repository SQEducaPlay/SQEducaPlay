import 'dart:math';

import '../database/app_database.dart';
import '../models/teacher_invite_model.dart';

/// Camada fina sobre [AppDatabase] para emissão de convites de educador.
///
/// Pensada para ser chamada apenas de uma tela administrativa (papel
/// `admin`). A validação/consumo do código continua acontecendo dentro de
/// [AppDatabase.createTeacherFromInvite], que é a única forma de criar uma
/// conta de educador no aplicativo.
class TeacherInviteService {
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // sem O/0/I/1
  final Random _random;

  TeacherInviteService({Random? random}) : _random = random ?? Random.secure();

  String _generateCode() {
    String group() => List.generate(4, (_) => _alphabet[_random.nextInt(_alphabet.length)]).join();
    return 'SQ-${group()}-${group()}';
  }

  Future<TeacherInvite> issueInvite({
    required String schoolId,
    String? createdByUsername,
    Duration validFor = const Duration(days: 14),
  }) async {
    // Tenta algumas vezes em caso de colisão improvável de código único.
    ArgumentError? lastError;
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        return await AppDatabase.instance.createTeacherInvite(
          code: _generateCode(),
          schoolId: schoolId,
          createdByUsername: createdByUsername,
          validFor: validFor,
        );
      } on ArgumentError catch (e) {
        lastError = e;
      } catch (_) {
        // Provável UNIQUE constraint por colisão de código; tenta de novo.
      }
    }
    throw lastError ?? ArgumentError('Não foi possível gerar um código de convite.');
  }

  Future<List<TeacherInvite>> listInvites({String? schoolId}) {
    return AppDatabase.instance.listTeacherInvites(schoolId: schoolId);
  }
}
