
import 'package:flutter/material.dart';
// Firebase removed — feature deferred
import 'materias_page.dart';
import 'login_page.dart';
import 'pages/perfil_aluno_page.dart';
import 'pages/ranking_tabs_page.dart';
import 'pages/privacy_settings_page.dart';
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
  @override
  void initState() {
    super.initState();
    // Exercise/Firebase listener removed — feature deferred
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.surface,
      appBar: AppTopBar(
        title: 'SQEducaPlay 📚',
        actions: [
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
                MaterialPageRoute(builder: (_) => const RankingTabsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Meu Perfil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PerfilAlunoPage(username: 'admin'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceLG,
          vertical: DesignTokens.spaceMD,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Bloco de Boas-vindas
            Text(
              'Olá, Aluno! 👋',
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

            // 2. Card de Progresso Principal
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
                            'Nível 5',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      Text(
                        '1.250 XP',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceMD),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const LinearProgressIndicator(
                      value: 0.6, // 60% de progresso
                      backgroundColor: Colors.white30,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                      minHeight: 12,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceSM),
                  Text(
                    'Faltam 250 XP para o Nível 6!',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spaceLG),

            // 3. Escolher o Ano
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

            // 4. Conquistas Recentes
            const SectionHeader(
              title: 'Últimas Conquistas',
            ),
            const SizedBox(height: DesignTokens.spaceMD),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildConquistaCard(
                      context, 'Mestre da Adição', Icons.add_task, Colors.green),
                  _buildConquistaCard(context, '3 Dias Seguidos!',
                      Icons.local_fire_department, Colors.orange),
                  _buildConquistaCard(
                      context, 'Explorador', Icons.travel_explore, Colors.purple),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spaceLG),
          ],
        ),
      ),
    );
  }

  Widget _buildConquistaCard(
      BuildContext context, String title, IconData icon, Color color) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: DesignTokens.spaceMD),
      padding: const EdgeInsets.all(DesignTokens.spaceSM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.withValues(alpha: 0.9),
                ),
          ),
        ],
      ),
    );
  }
}
