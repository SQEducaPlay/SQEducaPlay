import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqeducaplay/database/app_database.dart';
import 'package:sqeducaplay/models/user_model.dart';
import 'package:sqeducaplay/services/teacher_invite_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final database = AppDatabase.instance;
  final service = TeacherInviteService();

  User teacher(String username, {String schoolId = '1'}) => User(
        username: username,
        password: 'hash',
        fullName: 'Educador Teste',
        role: 'teacher',
        schoolId: schoolId,
      );

  test('gera convite no formato SQ-XXXX-XXXX', () async {
    final invite = await service.issueInvite(schoolId: '1');
    expect(RegExp(r'^SQ-[A-Z2-9]{4}-[A-Z2-9]{4}$').hasMatch(invite.code), isTrue);
  });

  test('consome convite válido uma única vez', () async {
    final invite = await service.issueInvite(schoolId: '1');
    final created = await database.createTeacherFromInvite(
      inviteCode: invite.code,
      schoolId: '1',
      teacher: teacher('prof_${DateTime.now().microsecondsSinceEpoch}'),
    );
    expect(created.role, 'teacher');
    expect((await service.getByCode(invite.code))?.isUsed, isTrue);
    expect(
      () => database.createTeacherFromInvite(
        inviteCode: invite.code,
        schoolId: '1',
        teacher: teacher('outro_${DateTime.now().microsecondsSinceEpoch}'),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('rejeita convite de outra escola e convite expirado', () async {
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final wrongSchool = await database.createTeacherInvite(
      code: 'SQ-WRNG-${suffix.toString().substring(0, 4)}',
      schoolId: '2',
    );
    expect(
      () => database.createTeacherFromInvite(
        inviteCode: wrongSchool.code,
        schoolId: '1',
        teacher: teacher('escola_errada_${DateTime.now().microsecondsSinceEpoch}'),
      ),
      throwsA(isA<ArgumentError>()),
    );

    final expired = await database.createTeacherInvite(
      code: 'SQ-EXPR-${suffix.toString().substring(4, 8)}',
      schoolId: '1',
      validFor: const Duration(seconds: -1),
    );
    expect(
      () => database.createTeacherFromInvite(
        inviteCode: expired.code,
        schoolId: '1',
        teacher: teacher('expirado_${DateTime.now().microsecondsSinceEpoch}'),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
