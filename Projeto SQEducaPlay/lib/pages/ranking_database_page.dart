import 'package:flutter/material.dart';
import '../utils/logger.dart';
import '../database/app_database.dart';
import '../widgets/app_bar.dart';

class RankingDatabasePage extends StatefulWidget {
  const RankingDatabasePage({super.key});

  @override
  State<RankingDatabasePage> createState() => _RankingDatabasePageState();
}

class _RankingDatabasePageState extends State<RankingDatabasePage> {
  List<Map<String, dynamic>> _rankingGeral = [];
  List<Map<String, dynamic>> _rankingPortugues = [];
  List<Map<String, dynamic>> _rankingMatematica = [];
  bool _carregando = true;
  String _abaSelecionada = 'geral';

  @override
  void initState() {
    super.initState();
    _carregarRankings();
  }

  Future<void> _carregarRankings() async {
    setState(() => _carregando = true);

    try {
  final geral = await AppDatabase.instance.buscarRankingGeral(limit: 20);
  final portugues = await AppDatabase.instance.buscarRankingPorMateria('Português', limit: 20);
  final matematica = await AppDatabase.instance.buscarRankingPorMateria('Matemática', limit: 20);

      setState(() {
        _rankingGeral = geral;
        _rankingPortugues = portugues;
        _rankingMatematica = matematica;
        _carregando = false;
      });
    } catch (e) {
  Logger.d('Erro ao carregar rankings: $e');
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: '🏆 Ranking',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarRankings,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Abas
          Container(
            color: Colors.orange.shade50,
            child: Row(
              children: [
                Expanded(
                  child: _buildAbaButton('Geral', 'geral', Icons.emoji_events),
                ),
                Expanded(
                  child: _buildAbaButton('Português', 'portugues', Icons.abc),
                ),
                Expanded(
                  child: _buildAbaButton('Matemática', 'matematica', Icons.calculate),
                ),
              ],
            ),
          ),
          // Conteúdo
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _buildRankingList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAbaButton(String titulo, String aba, IconData icone) {
    final selecionada = _abaSelecionada == aba;
    return InkWell(
      onTap: () => setState(() => _abaSelecionada = aba),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selecionada ? Colors.orange : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: selecionada ? Colors.orange : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icone,
              color: selecionada ? Colors.white : Colors.orange,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              style: TextStyle(
                color: selecionada ? Colors.white : Colors.orange.shade700,
                fontWeight: selecionada ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingList() {
    List<Map<String, dynamic>> ranking;
    
    switch (_abaSelecionada) {
      case 'portugues':
        ranking = _rankingPortugues;
        break;
      case 'matematica':
        ranking = _rankingMatematica;
        break;
      default:
        ranking = _rankingGeral;
    }

    if (ranking.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum dado no ranking ainda',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Jogue um quiz para aparecer aqui!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarRankings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ranking.length,
        itemBuilder: (context, index) {
          final item = ranking[index];
          final posicao = index + 1;
          
          return _buildRankingCard(item, posicao);
        },
      ),
    );
  }

  Widget _buildRankingCard(Map<String, dynamic> item, int posicao) {
    final nome = item['nome'] as String;
    final pontuacao = _abaSelecionada == 'geral'
        ? (item['pontuacao_total'] as int? ?? 0)
        : (item['pontuacao_materia'] as int? ?? 0);
    final estrelas = _abaSelecionada == 'geral'
        ? (item['estrelas_total'] as int? ?? 0)
        : (item['estrelas_materia'] as int? ?? 0);

    final cor = _getCorPosicao(posicao);
    final medalha = _getMedalha(posicao);

    return Card(
      elevation: posicao <= 3 ? 8 : 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: cor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildPosicaoWidget(posicao, medalha),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: posicao <= 3 ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 14,
                        color: posicao <= 3 ? Colors.yellow.shade200 : Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '$estrelas ${estrelas == 1 ? 'estrela' : 'estrelas'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: posicao <= 3 ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 84,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.emoji_events, color: Colors.yellow, size: 22),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$pontuacao',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: posicao <= 3 ? Colors.white : Colors.orange.shade800,
                      ),
                    ),
                  ),
                  Text(
                    'pontos',
                    style: TextStyle(
                      fontSize: 9,
                      color: posicao <= 3 ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosicaoWidget(int posicao, String? medalha) {
    if (medalha != null) {
      return Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        child: Text(
          medalha,
          style: const TextStyle(fontSize: 32),
        ),
      );
    }

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$posicao°',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.orange.shade800,
        ),
      ),
    );
  }

  Color _getCorPosicao(int posicao) {
    switch (posicao) {
      case 1:
        return Colors.amber.shade600; // Ouro
      case 2:
        return Colors.grey.shade400; // Prata
      case 3:
        return Colors.brown.shade400; // Bronze
      default:
        return Colors.white;
    }
  }

  String? _getMedalha(int posicao) {
    switch (posicao) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return null;
    }
  }
}
