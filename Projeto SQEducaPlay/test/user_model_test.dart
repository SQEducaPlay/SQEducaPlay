import 'package:flutter_test/flutter_test.dart';
import 'package:sqeducaplay/models/user_model.dart';

void main() {
  test('preserva consentimento e aprovação no mapa do usuário', () {
    final consentAt = DateTime.utc(2026, 8, 15);
    final user = User(
      id: 7,
      username: 'aluno',
      password: 'hash',
      fullName: 'Aluno Teste',
      role: 'student',
      consentAt: consentAt,
      consentVersion: '2026-08-15',
      isApproved: false,
    );

    final restored = User.fromMap(user.toMap());

    expect(restored.id, 7);
    expect(restored.consentVersion, '2026-08-15');
    expect(restored.consentAt, consentAt);
    expect(restored.isApproved, isFalse);
  });

  test('não exporta senha no mapa público', () {
    final user = User(
      username: 'aluno',
      password: 'hash-secreto',
      fullName: 'Aluno Teste',
      role: 'student',
    );
    final publicData = user.toMap()..remove('password');

    expect(publicData.containsKey('password'), isFalse);
  });
}
