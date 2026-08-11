import 'package:flutter/material.dart';
import '../utils/logger.dart';
import '../database/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_bar.dart';

class EstatisticasPage extends StatefulWidget {
  const EstatisticasPage({super.key});

  @override
  State<EstatisticasPage> createState() => _EstatisticasPageState();
}

class _EstatisticasPageState extends State<EstatisticasPage> {
  Map<String, dynamic>? _estatisticas;
  List<Map<String, dynamic>> _ultimasPartidas = [];
  bool _carregando = true;
  String? _nomeUsuario;

  @override
  void initState() {
    super.initState();
    _carregarEstatisticas();
  }

  Future<void> _carregarEstatisticas() async {
    setState(() => _carregando = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id');
      _nomeUsuario = prefs.getString('usuario_nome');

      if (usuarioId == null) {
        setState(() => _carregando = false);
        return;
      }

  final stats = await AppDatabase.instance.buscarEstatisticasUsuario(usuarioId);
  final ultimas = await AppDatabase.instance.buscarUltimasPartidas(usuarioId, limit: 15);

      setState(() {
        _estatisticas = stats;
        _ultimasPartidas = ultimas;
        _carregando = false;
      });
    } catch (e) {
  Logger.d('Erro ao carregar estatísticas: $e');
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: '📊 Minhas Estatísticas',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarEstatisticas,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _estatisticas == null
              ? _buildSemDados()
              : RefreshIndicator(
                  onRefresh: _carregarEstatisticas,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildHeaderUsuario(),
                        _buildCardsEstatisticas(),
                        _buildProgressoPorMateria(),
                        _buildHistoricoPartidas(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSemDados() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma estatística ainda',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jogue um quiz para ver suas estatísticas!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderUsuario() {
    final usuario = _estatisticas!['usuario'] as Map<String, dynamic>;
    final pontuacaoTotal = usuario['pontuacao_total'] as int? ?? 0;
    final estrelasTotal = usuario['estrelas_total'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Text(
              (_nomeUsuario ?? 'U')[0].toUpperCase(),
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _nomeUsuario ?? 'Usuário',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatChip(Icons.emoji_events, '$pontuacaoTotal', 'Pontos'),
              _buildStatChip(Icons.star, '$estrelasTotal', 'Estrelas'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String valor, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
  color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsEstatisticas() {
    final stats = _estatisticas!['estatisticas_gerais'] as Map<String, dynamic>;
    final totalPartidas = stats['total_partidas'] as int? ?? 0;
    final totalAcertos = stats['total_acertos'] as int? ?? 0;
    final totalPerguntas = stats['total_perguntas'] as int? ?? 0;
    final mediaPontuacao = (stats['media_pontuacao'] as num?)?.toDouble() ?? 0.0;

    final taxaAcerto = totalPerguntas > 0 
        ? ((totalAcertos / totalPerguntas) * 100).toStringAsFixed(1)
        : '0.0';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo Geral',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  Icons.quiz,
                  '$totalPartidas',
                  'Partidas',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  Icons.check_circle,
                  '$taxaAcerto%',
                  'Taxa de Acerto',
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            Icons.trending_up,
            mediaPontuacao.toStringAsFixed(1),
            'Média de Pontuação',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  String _formatarValorK(String valor) {
    bool isPercent = valor.endsWith('%');
    String plainNumber = valor.replaceAll('%', '').replaceAll(',', '.');
    double? numero = double.tryParse(plainNumber);

    if (numero == null) return valor;

    String formatado;
    if (numero.abs() >= 1000) {
      double kValue = numero / 1000;
      formatado = kValue.toStringAsFixed(1).replaceAll('.', ',');
      if (formatado.endsWith(',0')) {
        formatado = formatado.substring(0, formatado.length - 2);
      }
      formatado += 'k';
    } else {
      if (numero.truncateToDouble() == numero) {
        formatado = numero.toInt().toString();
      } else {
        formatado = numero.toStringAsFixed(1).replaceAll('.', ',');
        if (formatado.endsWith(',0')) {
          formatado = formatado.substring(0, formatado.length - 2);
        }
      }
    }

    return isPercent ? '$formatado%' : formatado;
  }

  Widget _buildStatCard(IconData icon, String valor, String label, Color cor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: cor, size: 32),
            ),
            const SizedBox(height: 8),
            Text(
              _formatarValorK(valor),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressoPorMateria() {
    final raw = _estatisticas!['progresso_por_materia'] as List<dynamic>?;
    final progresso = raw?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];

    if (progresso.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progresso por Matéria',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...progresso.map((item) => _buildProgressoMateriaCard(item)),
        ],
      ),
    );
  }

  Widget _buildProgressoMateriaCard(Map<String, dynamic> item) {
    final materia = item['materia'] as String? ?? '-';
    final ano = item['ano'] as String? ?? '';
    final acertos = (item['total_acertos'] as int?) ?? 0;
    final perguntas = (item['total_perguntas'] as int?) ?? 0;
    final melhorPontuacao = (item['melhor_pontuacao'] as int?) ?? 0;

    final taxaAcerto = perguntas > 0 ? (acertos / perguntas) * 100 : 0.0;
    final icone = materia == 'Português' ? Icons.abc : Icons.calculate;
    final cor = materia == 'Português' ? Colors.blue : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, color: cor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        materia,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ano,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${taxaAcerto.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('$acertos/$perguntas', 'Acertos'),
                _buildMiniStat('$melhorPontuacao', 'Recorde'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String valor, String label) {
    return Column(
      children: [
        Text(
          valor,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoricoPartidas() {
    if (_ultimasPartidas.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Últimas Partidas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._ultimasPartidas.map((partida) => _buildPartidaCard(partida)),
        ],
      ),
    );
  }

  Widget _buildPartidaCard(Map<String, dynamic> partida) {
    final materia = partida['materia'] as String? ?? '-';
    final ano = partida['ano'] as String? ?? '';
    final pontuacao = (partida['pontuacao'] as int?) ?? 0;
    final estrelas = (partida['estrelas'] as int?) ?? 0;
    final acertos = (partida['acertos'] as int?) ?? 0;
    final totalPerguntas = (partida['total_perguntas'] as int?) ?? 0;
    final dataStr = partida['data_partida'] as String?;
    DateTime data = DateTime.now();
    if (dataStr != null) {
      data = DateTime.tryParse(dataStr) ?? DateTime.now();
    }

    final dataFormatada = '${data.day}/${data.month}/${data.year}';
    final horaFormatada = '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: materia == 'Português' ? Colors.blue.shade100 : Colors.green.shade100,
          child: Icon(
            materia == 'Português' ? Icons.abc : Icons.calculate,
            color: materia == 'Português' ? Colors.blue : Colors.green,
          ),
        ),
        title: Text('$materia - $ano'),
        subtitle: Text('$dataFormatada às $horaFormatada'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$pontuacao pts',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                Text(' $estrelas  '),
                Text(
                  '$acertos/$totalPerguntas',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
