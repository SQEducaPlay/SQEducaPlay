import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqeducaplay/config/privacy_policy_config.dart';
import 'package:sqeducaplay/pages/privacy_policy_page.dart';

void main() {
  test('aviso de privacidade usa a versão compartilhada do consentimento', () {
    expect(PrivacyPolicyPage.policyVersion, PrivacyPolicyConfig.version);
    expect(PrivacyPolicyConfig.version, '2026-09-26-pilot');
  });

  testWidgets('aviso descreve foto opcional e armazenamento web temporário', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyPage()));

    expect(find.textContaining(PrivacyPolicyConfig.version), findsOneWidget);
    expect(find.textContaining('foto de perfil e opcional'), findsOneWidget);
    expect(find.textContaining('memoria no navegador'), findsOneWidget);
    expect(
      find.textContaining('senha tambem fica armazenada localmente'),
      findsOneWidget,
    );
  });
}
