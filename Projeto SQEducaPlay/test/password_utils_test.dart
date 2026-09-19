import 'package:flutter_test/flutter_test.dart';
import 'package:sqeducaplay/utils/password_utils.dart';

void main() {
  group('PasswordUtils', () {
    test('cria hash bcrypt e valida a senha correta', () {
      final hash = PasswordUtils.hashPassword('Senha123');

      expect(PasswordUtils.isBcryptHash(hash), isTrue);
      expect(PasswordUtils.verifyPassword('Senha123', hash), isTrue);
      expect(PasswordUtils.verifyPassword('SenhaErrada123', hash), isFalse);
      expect(PasswordUtils.needsRehash(hash), isFalse);
    });

    test('rejeita senhas fracas', () {
      expect(PasswordUtils.isValidPassword('1234567'), isFalse);
      expect(PasswordUtils.isValidPassword('somenteletras'), isFalse);
      expect(PasswordUtils.isValidPassword('Senha123'), isTrue);
    });
  });
}
