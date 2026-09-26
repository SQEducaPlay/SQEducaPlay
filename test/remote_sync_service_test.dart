import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sqeducaplay/pages/guardian_access_page.dart';
import 'package:sqeducaplay/services/remote_sync_service.dart';
import 'package:sqeducaplay/services/progresso_service.dart';

void main() {
  test('gera identificadores de sincronizacao UUID v4 validos e unicos', () {
    final ids = List.generate(
      100,
      (_) => RemoteSyncService.createClientSessionId(),
    );

    expect(ids.toSet(), hasLength(ids.length));
    for (final id in ids) {
      expect(
        id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    }
  });

  test('nao inclui progresso de outros perfis no ranking de uma familia', () {
    final progress = ProgressoService();
    final familyStudent = progress.getProgresso('remote_family_student_test');
    final unrelatedStudent = progress.getProgresso(
      'local_unrelated_student_test',
    );
    familyStudent.pontuacaoTotal = 25;
    unrelatedStudent.pontuacaoTotal = 500;

    progress.setRemoteStudentScope('remote_family_student_test');
    expect(progress.getRanking().map((item) => item.username), [
      'remote_family_student_test',
    ]);
    progress.setRemoteStudentScope(null);
    progress.removeUserData('remote_family_student_test');
    progress.removeUserData('local_unrelated_student_test');
  });

  testWidgets('nao tenta login online quando backend nao esta configurado', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GuardianAccessPage()));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ainda nao esta configurado'), findsOneWidget);
  });

  testWidgets('confirma antes de sair do acesso do responsavel', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GuardianAccessPage()));

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(
      find.text('Deseja sair da conta e voltar ao inicio?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Continuar no app'));
    await tester.pumpAndSettle();

    expect(find.text('Acesso do responsavel'), findsOneWidget);
  });
}
