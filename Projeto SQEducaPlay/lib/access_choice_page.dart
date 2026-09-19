import 'package:flutter/material.dart';

import 'login_page.dart';
import 'register_page.dart';
import 'teacher_setup_page.dart';

class AccessChoicePage extends StatelessWidget {
  const AccessChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/mascoteTransparente.png',
                    height: 180,
                    semanticLabel: 'Mascote do SQEducaPlay',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Escolha seu acesso',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _AccessCard(
                    title: 'Sou aluno',
                    subtitle: 'Acesse suas matérias e atividades.',
                    icon: Icons.school,
                    onLogin: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginPage(initialProfessor: false),
                      ),
                    ),
                    onRegister: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AccessCard(
                    title: 'Sou professor',
                    subtitle: 'Acesse o painel das suas turmas.',
                    icon: Icons.workspace_premium,
                    onLogin: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginPage(initialProfessor: true),
                      ),
                    ),
                    onRegister: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TeacherSetupPage()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onLogin;
  final VoidCallback? onRegister;

  const _AccessCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onLogin,
    this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: Colors.blue, size: 34),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(subtitle),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onLogin,
                child: const Text('Entrar'),
              ),
            ),
            if (onRegister != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onRegister,
                  child: Text(title.contains('professor')
                      ? 'Primeiro acesso'
                      : 'Cadastrar aluno'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
