import 'package:flutter/material.dart';
// audio managed by BackgroundAudioService
import 'topicos_page.dart';
import 'services/background_audio_service.dart';
import 'login_page.dart';
import 'pages/perfil_aluno_page.dart';
import 'pages/ranking_database_page.dart';
import 'widgets/app_bar.dart';
import 'user_service.dart';

class MateriasPage extends StatelessWidget {
  final String ano;
  final String? username;

  MateriasPage({super.key, required this.ano, this.username});

  final List<Map<String, dynamic>> materias = [
    {'nome': 'Português', 'icone': Icons.edit, 'cor': Colors.orange},
    {'nome': 'Matemática', 'icone': Icons.calculate, 'cor': Colors.teal},
  ];

  @override
  Widget build(BuildContext context) {
    final user = UserService().getUserByUsername(username ?? '');
    final name = user?.fullName ?? username ?? 'Aluno';
    final firstName = name.trim().split(RegExp(r'\s+')).first;
    final titleGreeting = 'Oi, $firstName! 👋';

    return Scaffold(
      appBar: AppTopBar(
        title: titleGreeting,
        actions: [
          _buildRoundedAction(Icons.person, 'Meu Perfil', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PerfilAlunoPage(username: username ?? 'aluno'),
              ),
            );
          }),
          _buildRoundedAction(Icons.leaderboard, 'Ranking', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RankingDatabasePage()),
            );
          }),
          _buildRoundedAction(Icons.logout, 'Sair', () async {
            try { await BackgroundAudioService.instance.stopForTopic(); } catch (_) {}
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
          }),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.purple.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Título
                Text(
                  'Escolha sua matéria',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.blue.shade900,
                  ),
                ),
                
                // Caminho Visual Animado
                _buildPathAnimation(),

                // Botões (Lado a Lado)
                Row(
                  children: [
                    Expanded(
                      child: SubjectCard(
                        materia: materias[0],
                        index: 0,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TopicosPage(
                                ano: ano,
                                materia: materias[0]['nome'],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: SubjectCard(
                        materia: materias[1],
                        index: 1,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TopicosPage(
                                ano: ano,
                                materia: materias[1]['nome'],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Mascote + Balão de fala
                _buildMascotSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundedAction(IconData icon, String tooltip, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildPathAnimation() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDot(0),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildDot(1),
          ),
          const SizedBox(width: 16),
          _buildDot(2),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildDot(3),
          ),
          const SizedBox(width: 16),
          _buildDot(4),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 200)),
      curve: Curves.elasticOut,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMascotSection() {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'O que vamos aprender hoje?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.blue.shade800,
              ),
            ),
          ),
          CustomPaint(
            size: const Size(20, 10),
            painter: BubbleTailPainter(),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: Image.asset(
              'assets/images/mascote.png',
              height: 120,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.smart_toy, size: 80, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}

class SubjectCard extends StatefulWidget {
  final Map<String, dynamic> materia;
  final int index;
  final VoidCallback onTap;

  const SubjectCard({
    super.key,
    required this.materia,
    required this.index,
    required this.onTap,
  });

  @override
  State<SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<SubjectCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (widget.index * 150)),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutBack,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.materia['cor'],
                  (widget.materia['cor'] as Color).withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (widget.materia['cor'] as Color).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.materia['icone'],
                    size: 56,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.materia['nome'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}