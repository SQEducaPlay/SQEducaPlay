import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqeducaplay/widgets/confirm_exit_scope.dart';

void main() {
  testWidgets('asks before exiting and stays in the app when canceled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ConfirmExitScope(
          child: Scaffold(body: Text('Área autenticada')),
          startPageBuilder: _buildStartPage,
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(
      find.text('Deseja sair da conta e voltar ao inicio?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Continuar no app'));
    await tester.pumpAndSettle();

    expect(find.text('Área autenticada'), findsOneWidget);
    expect(find.text('Deseja sair da conta e voltar ao inicio?'), findsNothing);
  });

  testWidgets('volta ao inicio somente apos confirmacao', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: ConfirmExitScope(
          child: Scaffold(body: Text('Área autenticada')),
          startPageBuilder: _buildStartPage,
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Tela inicial'), findsNothing);

    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(find.text('Tela inicial'), findsOneWidget);
    expect(find.text('Área autenticada'), findsNothing);
  });
}

Widget _buildStartPage(BuildContext context) {
  return const Scaffold(body: Text('Tela inicial'));
}
