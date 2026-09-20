import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqeducaplay/login_page.dart';
import 'package:sqeducaplay/pages/access_choice_page.dart';
import 'package:sqeducaplay/pages/admin_profile_page.dart';

import 'package:sqeducaplay/services/user_service.dart';

void main() {
  Future<void> pumpLoginPage(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(audience: LoginAudience.student),
      ),
    );
  }

  test('cria um admin de desenvolvimento padrão', () {
    final userService = UserService();
    userService.removeUser('betaprime');
    userService.ensureDevelopmentAdmin();

    final user = userService.login('betaprime', 'betaprime10');
    expect(user, isNotNull);
    expect(user?.role, 'admin');

    userService.removeUser('betaprime');
  });

  testWidgets('mostra aviso ao tentar entrar sem usuário', (tester) async {
    await pumpLoginPage(tester);

    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Digite seu usuário para continuar.'), findsOneWidget);
  });

  testWidgets('mostra aviso ao tentar entrar sem senha', (tester) async {
    await pumpLoginPage(tester);

    final usernameField = find.byType(TextField).first;
    await tester.enterText(usernameField, 'aluno_teste');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Digite sua senha para continuar.'), findsOneWidget);
  });

  testWidgets('perfil admin usa AppBar com retorno habilitado e sem logout no perfil', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminProfilePage()));

    expect(find.text('Estatísticas'), findsNothing);
    expect(find.text('Conquistas'), findsNothing);
    expect(find.text('Histórico'), findsNothing);

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.automaticallyImplyLeading, isTrue);
    expect(find.byIcon(Icons.logout), findsNothing);
  });

  testWidgets('salva credenciais quando a opção de salvar senha está marcada', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final userService = UserService();
    userService.removeUser('betaprime');
    userService.ensureDevelopmentAdmin();

    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(audience: LoginAudience.student),
      ),
    );

    final usernameField = find.byType(TextField).first;
    final passwordField = find.byType(TextField).at(1);

    await tester.enterText(usernameField, 'betaprime');
    await tester.enterText(passwordField, 'betaprime10');

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('saved_username_student'), 'betaprime');
    expect(prefs.getString('saved_password_student'), 'betaprime10');
    expect(prefs.getString('last_login_audience'), 'student');

    userService.removeUser('betaprime');
  });

  testWidgets('abre o login do último perfil utilizado', (tester) async {
    SharedPreferences.setMockInitialValues({'last_login_audience': 'teacher'});

    await tester.pumpWidget(const MaterialApp(home: AccessChoicePage()));
    await tester.pumpAndSettle();

    expect(find.text('Acesso do Educador!'), findsOneWidget);
  });
}
