import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../login_page.dart';
import '../register_page.dart';
import '../services/backend_service.dart';
import 'teacher_setup_page.dart';
import 'guardian_access_page.dart';
import 'institutional_access_page.dart';

class AccessChoicePage extends StatefulWidget {
  final bool skipRememberedAudience;

  const AccessChoicePage({super.key, this.skipRememberedAudience = false});

  @override
  State<AccessChoicePage> createState() => _AccessChoicePageState();
}

class _AccessChoicePageState extends State<AccessChoicePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _studentOpacity;
  late final Animation<Offset> _studentSlide;
  late final Animation<double> _teacherOpacity;
  late final Animation<Offset> _teacherSlide;

  @override
  void initState() {
    super.initState();
    _redirectToRememberedLogin();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _headerOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
          ),
        );

    _studentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.72, curve: Curves.easeOut),
    );
    _studentSlide =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.25, 0.72, curve: Curves.easeOutCubic),
          ),
        );

    _teacherOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _teacherSlide =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _controller.forward();
  }

  Future<void> _redirectToRememberedLogin() async {
    if (widget.skipRememberedAudience || BackendService.instance.isConfigured) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    final audienceName = preferences.getString('last_login_audience');
    final audience = switch (audienceName) {
      'student' => LoginAudience.student,
      'teacher' => LoginAudience.teacher,
      _ => null,
    };
    if (audience == null || !mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginPage(audience: audience)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onlineBackendConfigured = BackendService.instance.isConfigured;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/fundo_azul.jpg',
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
          ),
          Positioned(
            top: -30,
            right: -20,
            child: _decorBubble(120, const Color(0x55FFFFFF)),
          ),
          Positioned(
            bottom: 120,
            left: -25,
            child: _decorBubble(90, const Color(0x44FFFFFF)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      SlideTransition(
                        position: _headerSlide,
                        child: FadeTransition(
                          opacity: _headerOpacity,
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/mascoteTransparente.png',
                                height: 200,
                                semanticLabel: 'Mascote do SQEducaPlay',
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Escolha seu acesso',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0D4F99),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (BackendService.instance.isConfigured) ...[
                        _AccessCard(
                          title: 'Sou Responsavel',
                          subtitle:
                              'Acesse os perfis da sua familia em qualquer aparelho',
                          color: const Color(0xFF27805A),
                          icon: Icons.family_restroom,
                          primaryLabel: 'Entrar na conta',
                          onPrimary: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const GuardianAccessPage(),
                              ),
                            );
                          },
                          secondaryLabel: 'Criar conta da familia',
                          onSecondary: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const GuardianAccessPage(
                                  startWithSignUp: true,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      SlideTransition(
                        position: _studentSlide,
                        child: FadeTransition(
                          opacity: _studentOpacity,
                          child: _AccessCard(
                            title: onlineBackendConfigured
                                ? 'Aluno (modo local)'
                                : 'Sou Aluno',
                            subtitle: onlineBackendConfigured
                                ? 'Contas antigas deste aparelho; nao sincronizam com a nuvem'
                                : 'Entrar para estudar ou criar conta de aluno',
                            color: const Color(0xFF2B7CD3),
                            icon: Icons.school,
                            primaryLabel: onlineBackendConfigured
                                ? 'Entrar neste aparelho'
                                : 'Entrar como aluno',
                            onPrimary: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(
                                    audience: LoginAudience.student,
                                  ),
                                ),
                              );
                            },
                            secondaryLabel: onlineBackendConfigured
                                ? 'Criar conta local'
                                : 'Cadastrar aluno',
                            onSecondary: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SlideTransition(
                        position: _teacherSlide,
                        child: FadeTransition(
                          opacity: _teacherOpacity,
                          child: _AccessCard(
                            title: onlineBackendConfigured
                                ? 'Educador (online)'
                                : 'Sou Educador',
                            subtitle: onlineBackendConfigured
                                ? 'Acesso institucional com convite individual da escola'
                                : 'Acesse o painel da sua turma',
                            color: const Color(0xFFB46A00),
                            icon: Icons.workspace_premium,
                            primaryLabel: 'Entrar como educador',
                            onPrimary: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => onlineBackendConfigured
                                      ? const InstitutionalAccessPage()
                                      : const LoginPage(
                                          audience: LoginAudience.teacher,
                                        ),
                                ),
                              );
                            },
                            secondaryLabel: onlineBackendConfigured
                                ? 'Primeiro acesso (tenho convite)'
                                : 'Primeiro acesso',
                            onSecondary: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => onlineBackendConfigured
                                      ? const InstitutionalAccessPage(
                                          startWithSignUp: true,
                                        )
                                      : const TeacherSetupPage(),
                                ),
                              );
                            },
                            secondaryAsLink: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorBubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _AccessCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;
  final bool secondaryAsLink;

  const _AccessCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    this.secondaryAsLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPrimary,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                primaryLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: secondaryAsLink
                ? TextButton(
                    onPressed: onSecondary,
                    style: TextButton.styleFrom(
                      foregroundColor: color,
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    child: Text(
                      secondaryLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  )
                : OutlinedButton(
                    onPressed: onSecondary,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(
                        color: color.withValues(alpha: 0.62),
                        width: 1.2,
                      ),
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      secondaryLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
