
import 'package:flutter/material.dart';
import 'models/conquista_model.dart';
import 'models/progresso_model.dart';
import 'models/user_model.dart';
// Firebase removed — feature deferred
import 'manage_schools_page.dart';
import 'materias_page.dart';
import 'pages/access_choice_page.dart';
import 'pages/admin_teacher_invites_page.dart';
import 'pages/perfil_aluno_page.dart';
import 'pages/ranking_database_page.dart';
import 'pages/privacy_settings_page.dart';
import 'services/progresso_service.dart';
import 'services/daily_mission_service.dart';
import 'services/user_service.dart';
import 'widgets/app_bar.dart';
import 'widgets/card_primary.dart';
import 'widgets/section_header.dart';
import 'theme/design_tokens.dart';

class HomePage extends StatefulWidget {
  final List<Map<String, dynamic>> series = [
    {
      'ano': '2º Ano Fundamental',
      'cor': Colors.orange,
      'icone': Icons.looks_two,
    },
    {
      'ano': '3º Ano Fundamental',
      'cor': const Color.fromARGB(255, 112, 103, 17),
      'icone': Icons.looks_3,
    },
    {
      'ano': '4º Ano Fundamental',
      'cor': const Color.fromARGB(255, 47, 95, 91),
      'icone': Icons.looks_4,
    },
    {'ano': '5º Ano Fundamental', 'cor': Colors.blue, 'icone': Icons.looks_5},
  ];

  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? _user;
  ProgressoAluno? _progresso;
  List<Conquista> _conquistasRecentes = [];
  DailyMissionReward _dailyMissionReward = const DailyMissionReward(stars: 0, claimed: false);
  int _dailyMissionStars = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final currentUser = UserService().currentUser;
    if (currentUser == null) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AccessChoicePage()),
          (route) => false,
        );
      }
      return;
    }

    final userProgress = ProgressoService().getProgresso(currentUser.username);
    final dailyMissionReward = await DailyMissionService().claimIfCompleted(
      username: currentUser.username,
      completed: userProgress.quizesHoje >= 1,
      userId: currentUser.id,
    );
    final dailyMissionStars = currentUser.id == null
        ? 0
        : await DailyMissionService().getTotalRewardStars(userId: currentUser.id!);
    final conquistasDesbloqueadas = ProgressoService()
        .getConquistas(currentUser.username)
        .values
        .where((c) => c.desbloqueada)
        .toList()
      ..sort((a, b) =>
          (b.dataDesbloqueio ?? DateTime(0)).compareTo(a.dataDesbloqueio ?? DateTime(0)));

    if (mounted) {
      setState(() {
        _user = currentUser;
        _progresso = userProgress;
        _conquistasRecentes = conquistasDesbloqueadas.take(5).toList();
        _dailyMissionReward = dailyMissionReward;
        _dailyMissionStars = dailyMissionStars;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pontuacao = _progresso?.pontuacaoTotal ?? 0;
    final nivel = _progresso?.nivel ?? 'Novato';
    final progressoBar = (_progresso?.progressoNivel ?? 0) / 100.0;
    final xpParaProximo = _progresso == null || nivel == 'Mestre'
        ? 0
        : _progresso!.proximoNivelPontos - _progresso!.pontuacaoTotal;
    final diasConsecutivos = _progresso?.diasConsecutivos ?? 0;
    final name = _user?.fullName ?? 'Aluno';
    final firstName = name.trim().split(RegExp(r'\s+')).first;

    return Scaffold(
      backgroundColor: DesignTokens.surface,
      appBar: AppTopBar(
        title: 'SQEducaPlay 📚',
        actions: [
          if (_user?.role == 'admin') ...[
            IconButton(
              icon: const Icon(Icons.school_outlined),
              tooltip: 'Gerenciar escolas',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageSchoolsPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_moderator_outlined),
              tooltip: 'Convites de educador',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminTeacherInvitesPage()),
                );
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.privacy_tip_outlined),
            tooltip: 'Privacidade (LGPD)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacySettingsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            tooltip: 'Ranking',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RankingDatabasePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Meu Perfil',
            onPressed: () {
              if (_user == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PerfilAlunoPage(username: _user!.username),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              await UserService().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AccessChoicePage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceLG,
          vertical: DesignTokens.spaceMD,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, $firstName! 👋',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: DesignTokens.primary,
              ),
            ),
            const SizedBox(height: DesignTokens.spaceSM),
            Text(
              'Pronto para aprender hoje?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: DesignTokens.spaceLG),

            Container(
              padding: const EdgeInsets.all(DesignTokens.spaceMD),
              decoration: BoxDecoration(
                color: DesignTokens.primary,
                borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 28),
                          const SizedBox(width: DesignTokens.spaceSM),
                          Text(
                            'Nível $nivel',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$pontuacao XP',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${diasConsecutivos}d de sequência',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceMD),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                    child: LinearProgressIndicator(
                      value: progressoBar.clamp(0.0, 1.0),
                      backgroundColor: Colors.white30,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                      minHeight: 12,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceSM),
                  Text(
                    nivel == 'Mestre'
                        ? 'Você alcançou o nível máximo!'
                        : 'Faltam $xpParaProximo XP para ${_progresso!.proximoNivelPontos}!',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spaceLG),

            _buildDailyMission(context),
            const SizedBox(height: DesignTokens.spaceLG),

            const SectionHeader(
              title: 'Escolha o Ano Escolar',
            ),
            const SizedBox(height: DesignTokens.spaceMD),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: DesignTokens.spaceMD,
                mainAxisSpacing: DesignTokens.spaceMD,
                childAspectRatio: 1.1,
              ),
              itemCount: widget.series.length,
              itemBuilder: (context, index) {
                final serie = widget.series[index];
                return CardPrimary(
                  padding: const EdgeInsets.all(DesignTokens.spaceSM),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => MateriasPage(ano: serie['ano'])),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (serie['cor'] as Color).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          serie['icone'],
                          color: serie['cor'],
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spaceSM),
                      Text(
                        serie['ano'],
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: DesignTokens.spaceLG),

            const SectionHeader(
              title: 'Últimas Conquistas',
            ),
            const SizedBox(height: DesignTokens.spaceMD),
            SizedBox(
              height: 100,
              child: _conquistasRecentes.isEmpty
                  ? const Center(child: Text('Nenhuma conquista recente. Continue jogando!'))
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _conquistasRecentes.length,
                itemBuilder: (context, index) {
                  return _buildConquistaCard(context, _conquistasRecentes[index]);
                },
              ),
            ),
            const SizedBox(height: DesignTokens.spaceLG),
          ],
        ),
      ),
    );
  }

  Widget _buildConquistaCard(BuildContext context, Conquista conquista) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: DesignTokens.spaceMD),
      padding: const EdgeInsets.all(DesignTokens.spaceSM),
      decoration: BoxDecoration(
        color: conquista.cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
        border: Border.all(color: conquista.cor.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(conquista.icone, color: conquista.cor, size: 28),
          const SizedBox(height: 8),
          Text(
            conquista.titulo,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: conquista.cor.withValues(alpha: 0.9),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMission(BuildContext context) {
    final completed = (_progresso?.quizesHoje ?? 0) >= 1;
    final missionGrade = _user?.grade ?? widget.series.first['ano'] as String;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.spaceMD),
      decoration: BoxDecoration(
        color: completed ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
        border: Border.all(
          color: completed ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                completed ? Icons.check_circle : Icons.flag_rounded,
                color: completed ? Colors.green.shade700 : Colors.orange.shade800,
                size: 28,
              ),
              const SizedBox(width: DesignTokens.spaceSM),
              Text(
                'Missão de hoje',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: completed ? Colors.green.shade900 : Colors.orange.shade900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceSM),
          Text(
            completed ? 'Missão concluída! Você mandou muito bem.' : 'Complete 1 quiz de qualquer matéria',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: DesignTokens.spaceSM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                completed
                    ? 'Recompensa: ${_dailyMissionReward.stars} estrelas | Estrelas de missões: $_dailyMissionStars'
                    : 'Recompensa: reconhecimento por estudar hoje',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
              ),
              if (!completed)
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MateriasPage(ano: missionGrade),
                      ),
                    );
                    if (mounted) _loadUserData();
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Começar'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
