import 'package:flutter_test/flutter_test.dart';
import 'package:sqeducaplay/database/app_database.dart';
import 'package:sqeducaplay/models/teacher_assignment_model.dart';
import 'package:sqeducaplay/models/user_model.dart';
import 'package:sqeducaplay/services/teacher_invite_service.dart';

void main() {
  final db = AppDatabase.instance;
  final inviteService = TeacherInviteService();

  setUpAll(() async {
    try {
      await db.hasTeacherAccount();
    } catch (_) {}
  });

  User buildTeacher(String username, {String schoolId = '1'}) {
    return User(
      username: username,
      password: 'SenhaForte123',
      fullName: 'Educador Teste',
      schoolId: schoolId,
      role: 'teacher',
    );
  }

  List<TeacherAssignment> buildAssignments({String schoolId = '1'}) {
    return [
      TeacherAssignment(
        teacherId: 0,
        schoolId: schoolId,
        grade: '3º Ano Fundamental',
        classGroup: 'A',
        shift: 'Manhã',
      ),
    ];
  }

  test('rejeita criação de educador sem código de convite', () async {
    expect(
      () => db.createTeacherFromInvite(
        inviteCode: '',
        teacher: buildTeacher('sem_convite_1'),
        assignments: buildAssignments(),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('rejeita código de convite inexistente', () async {
    expect(
      () => db.createTeacherFromInvite(
        inviteCode: 'SQ-CODE-INEXISTENTE',
        teacher: buildTeacher('sem_convite_2'),
        assignments: buildAssignments(),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('cria conta de educador com convite válido e consome o código', () async {
    final invite = await inviteService.issueInvite(schoolId: '1', createdByUsername: 'admin_teste');

    final created = await db.createTeacherFromInvite(
      inviteCode: invite.code,
      teacher: buildTeacher('educador_valido_1'),
      assignments: buildAssignments(),
    );

    expect(created.id, isNotNull);
    expect(created.role, 'teacher');

    final storedInvite = await db.getTeacherInviteByCode(invite.code);
    expect(storedInvite, isNotNull);
    expect(storedInvite!.isUsed, isTrue);
    expect(storedInvite.usedByUserId, created.id);
  });

  test('rejeita reutilização do mesmo código de convite', () async {
    final invite = await inviteService.issueInvite(schoolId: '1', createdByUsername: 'admin_teste');

    await db.createTeacherFromInvite(
      inviteCode: invite.code,
      teacher: buildTeacher('educador_valido_2'),
      assignments: buildAssignments(),
    );

    expect(
      () => db.createTeacherFromInvite(
        inviteCode: invite.code,
        teacher: buildTeacher('educador_tentando_reusar'),
        assignments: buildAssignments(),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('rejeita convite emitido para outra escola', () async {
    final invite = await inviteService.issueInvite(schoolId: '2', createdByUsername: 'admin_teste');

    expect(
      () => db.createTeacherFromInvite(
        inviteCode: invite.code,
        teacher: buildTeacher('educador_escola_errada', schoolId: '1'),
        assignments: buildAssignments(schoolId: '1'),
      ),
      throwsA(isA<ArgumentError>()),
    );

    final storedInvite = await db.getTeacherInviteByCode(invite.code);
    expect(storedInvite!.isUsed, isFalse);
  });

  test('rejeita convite expirado', () async {
    final invite = await db.createTeacherInvite(
      code: 'SQ-EXPI-RADO',
      schoolId: '1',
      validFor: const Duration(seconds: -1),
    );

    expect(
      () => db.createTeacherFromInvite(
        inviteCode: invite.code,
        teacher: buildTeacher('educador_convite_expirado'),
        assignments: buildAssignments(),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('nao cria conta com nome de usuario ja existente mesmo com convite valido', () async {
    final invite1 = await inviteService.issueInvite(schoolId: '1', createdByUsername: 'admin_teste');
    await db.createTeacherFromInvite(
      inviteCode: invite1.code,
      teacher: buildTeacher('educador_duplicado'),
      assignments: buildAssignments(),
    );

    final invite2 = await inviteService.issueInvite(schoolId: '1', createdByUsername: 'admin_teste');
    expect(
      () => db.createTeacherFromInvite(
        inviteCode: invite2.code,
        teacher: buildTeacher('educador_duplicado'),
        assignments: buildAssignments(),
      ),
      throwsA(isA<ArgumentError>()),
    );

    final storedInvite2 = await db.getTeacherInviteByCode(invite2.code);
    expect(storedInvite2!.isUsed, isFalse);
  });
}
