import 'package:flutter_test/flutter_test.dart';
import 'package:sqeducaplay/database/app_database.dart';
import 'package:sqeducaplay/models/user_model.dart';

void main() {
  test('mantém aluno pendente até ser aprovado pelo educador', () async {
    final database = AppDatabase.instance;
    final username = 'aluno_pendente_${DateTime.now().microsecondsSinceEpoch}';

    await database.hasTeacherAccount();

    final student = await database.createUser(
      User(
        username: username,
        password: 'SenhaForte123',
        fullName: 'Aluno Pendente',
        schoolId: 'escola-teste',
        grade: '2º Ano Fundamental',
        classGroup: 'A',
        role: 'student',
        isApproved: false,
      ),
    );
    addTearDown(() async {
      if (student.id != null) await database.deleteUser(student.id!);
    });

    final pending = await database.getUserByUsername(username);
    expect(pending, isNotNull);
    expect(pending!.isApproved, isFalse);

    await database.updateUser(pending.copy(isApproved: true));

    final approved = await database.getUserByUsername(username);
    expect(approved!.isApproved, isTrue);
  });
}