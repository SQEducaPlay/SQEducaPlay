import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqeducaplay/widgets/confirm_exit_scope.dart';

void main() {
  testWidgets('asks before exiting and stays in the app when canceled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ConfirmExitScope(child: Scaffold(body: Text('Área autenticada'))),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Deseja realmente sair do aplicativo?'), findsOneWidget);
    await tester.tap(find.text('Continuar no app'));
    await tester.pumpAndSettle();

    expect(find.text('Área autenticada'), findsOneWidget);
    expect(find.text('Deseja realmente sair do aplicativo?'), findsNothing);
  });

  testWidgets('sai do aplicativo somente após confirmação', (tester) async {
    var exited = false;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') exited = true;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ConfirmExitScope(child: Scaffold(body: Text('Área autenticada'))),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(exited, isTrue);
  });
}
