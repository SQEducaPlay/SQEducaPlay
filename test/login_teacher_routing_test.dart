import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqeducaplay/database/app_database.dart';
import 'package:sqeducaplay/login_page.dart';
import 'package:sqeducaplay/models/user_model.dart';
import 'package:sqeducaplay/pages/perfil_professor_page.dart';
import 'package:sqeducaplay/materias_page.dart';
import 'package:sqeducaplay/services/password_service.dart';
import 'package:sqeducaplay/services/user_service.dart';

void main() {
  const username = 'professor_rota_teste';
  const password = 'SenhaForte123';

  setUpAll(() async {
    try {
      await AppDatabase.instance.hasTeacherAccount();
    } catch (_) {}
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
    UserService().addUserFromDb(User(
      id: 999001,
      username: username,
      password: PasswordService.hashPassword(password),
      fullName: 'Professor de Teste',
      role: 'teacher',
      schoolId: '1',
    ));
  });

  tearDown(() {
    UserService().removeUser(username);
  });

  testWidgets('educador autenticado cai no painel do educador, nao na area do aluno', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(audience: LoginAudience.teacher),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), username);
    await tester.enterText(find.byType(TextField).at(1), password);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfessorDashboardPage), findsOneWidget);
    expect(find.byType(MateriasPage), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Deseja realmente sair do aplicativo?'), findsOneWidget);
    await tester.tap(find.text('Continuar no app'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfessorDashboardPage), findsOneWidget);
  });
}
