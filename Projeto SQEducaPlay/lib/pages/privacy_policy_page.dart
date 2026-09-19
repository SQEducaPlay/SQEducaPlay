import 'package:flutter/material.dart';

import '../widgets/app_bar.dart';

class PrivacyPolicyPage extends StatelessWidget {
  static const consentVersion = '2026-08-15';

  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'Política de privacidade'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'Privacidade e segurança',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Versão do consentimento: $consentVersion'),
          SizedBox(height: 20),
          _PolicySection(
            title: 'Quais dados são usados',
            body:
                'O aplicativo pode registrar nome, apelido, usuário, turma, escola, progresso, pontuação e resultados das atividades. Esses dados são usados para liberar o acesso, acompanhar a aprendizagem e exibir rankings com as preferências escolhidas.',
          ),
          _PolicySection(
            title: 'Proteção da conta',
            body:
                'As senhas novas são protegidas com bcrypt. A senha não é salva nas preferências do dispositivo e não é incluída na exportação de dados. O acesso de alunos depende de aprovação do professor.',
          ),
          _PolicySection(
            title: 'Consentimento e controle',
            body:
                'No cadastro do aluno, o consentimento é registrado com data e versão. O responsável pode revisar as preferências, exportar os dados sem senha e solicitar a exclusão usando a área Privacidade (LGPD).',
          ),
          _PolicySection(
            title: 'Rankings e exposição',
            body:
                'Os rankings podem usar apelido ou nome anonimizado. A exibição da escola pode ser desativada. Evite informar dados pessoais desnecessários no nome, apelido ou respostas.',
          ),
          _PolicySection(
            title: 'Limites desta versão',
            body:
                'Esta versão usa armazenamento local SQLite no mobile e um fallback em memória na Web. Para uso institucional em produção, ainda é necessário configurar um backend com controle de acesso, política de retenção e responsáveis definidos pela escola.',
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;

  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }
}
