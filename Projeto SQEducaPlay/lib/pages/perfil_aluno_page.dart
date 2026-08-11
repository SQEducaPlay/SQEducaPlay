import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../database/app_database.dart';
import '../school_service.dart';
import '../services/celebration_service.dart';
import '../services/privacy_settings_service.dart';
import '../services/progresso_service.dart';
import '../models/progresso_model.dart';
import '../theme/design_tokens.dart';
import '../user_model.dart';
import '../user_service.dart';
import '../widgets/app_bar.dart';
import '../widgets/card_primary.dart';
import '../widgets/section_header.dart';

class PerfilAlunoPage extends StatefulWidget {
  final String username;

  const PerfilAlunoPage({super.key, required this.username});

  @override
  State<PerfilAlunoPage> createState() => _PerfilAlunoPageState();
}

class _PerfilAlunoPageState extends State<PerfilAlunoPage> {
  final _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  final _player = AudioPlayer();
  final _picker = ImagePicker();
  late final Future<List<Map<String, dynamic>>> _historicoFuture;

  @override
  void initState() {
    super.initState();
    _historicoFuture = _carregarHistorico(widget.username);
    _tryCelebrate();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _tryCelebrate() async {
    final privacy = PrivacySettingsService();
    await privacy.load();
    if (!privacy.enableConfetti && !privacy.enableSounds) return;

    final progressoService = ProgressoService();
    final conquistas = progressoService.getConquistas(widget.username);
    final desbloqueadas = conquistas.values.where((c) => c.desbloqueada).map((c) => c.tipo.toString()).toList();

    final celebration = CelebrationService();
    final novas = await celebration.getNewlyUnlockedKeys(widget.username, desbloqueadas);
    if (novas.isEmpty) return;

    if (privacy.enableConfetti) {
      _confettiController.play();
    }
    if (privacy.enableSounds) {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.play(AssetSource('sounds/vitoria.mp3'));
    }
    await celebration.acknowledge(widget.username, novas);
  }

  @override
  Widget build(BuildContext context) {
    final progressoService = ProgressoService();
    final progresso = progressoService.getProgresso(widget.username);
    final conquistas = progressoService.getConquistas(widget.username);
    final posicaoRanking = progressoService.getPosicaoRanking(widget.username);
    final user = UserService().getUserByUsername(widget.username);
    final privacy = PrivacySettingsService();
    final schoolName = (user?.schoolId != null && privacy.showSchoolInStudentRanking)
        ? (SchoolService().getSchoolById(user!.schoolId!)?.name ?? 'Escola não encontrada')
        : null;

    final conquistasDesbloqueadas = conquistas.values.where((c) => c.desbloqueada).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppTopBar(
          title: 'Perfil de ${widget.username}',
          showProfileAvatar: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Estatísticas'),
              Tab(text: 'Conquistas'),
              Tab(text: 'Histórico'),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _buildEstatisticasTab(
                  context,
                  user: user,
                  schoolName: schoolName,
                  progresso: progresso,
                  conquistasDesbloqueadas: conquistasDesbloqueadas,
                  conquistas: conquistas,
                  posicaoRanking: posicaoRanking,
                  privacy: privacy,
                ),
                _buildConquistasTab(conquistasDesbloqueadas),
                _buildHistoricoTab(),
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.blue, Colors.orange, Colors.green, Colors.purple],
                numberOfParticles: 30,
                gravity: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstatisticasTab(
    BuildContext context, {
    required User? user,
    required String? schoolName,
    required ProgressoAluno progresso,
    required List<dynamic> conquistasDesbloqueadas,
    required Map<dynamic, dynamic> conquistas,
    required int posicaoRanking,
    required PrivacySettingsService privacy,
  }) {
    final conquistasBloqueadas = conquistas.values.where((c) => !c.desbloqueada).toList();
    final progressoNivel = progresso.nivel == 'Mestre'
        ? 1.0
        : (progresso.pontuacaoTotal / progresso.proximoNivelPontos).clamp(0.0, 1.0);
    final totalPontosJogos = progresso.pontosPorMateria.values.fold<int>(
      0,
      (int sum, int value) => sum + value,
    );
    final mediaPontuacao = progresso.quizesCompletados > 0
        ? totalPontosJogos / progresso.quizesCompletados
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardPrimary(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _editPhoto,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: DesignTokens.primary,
                    child: _buildUserAvatar(user),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _publicName(
                    user?.fullName ?? widget.username,
                    user?.nickname,
                    privacy.anonymizeStudentNames,
                  ),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                if (schoolName != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.school, size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          schoolName,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getCorNivel(progresso.nivel),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    progresso.nivel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      Icons.emoji_events,
                      '$totalPontosJogos',
                      'Pontos',
                      Colors.orange,
                    ),
                    _buildStatItem(
                      Icons.stars,
                      '${progresso.estrelasTotal}',
                      'Estrelas',
                      const Color.fromARGB(255, 173, 164, 35),
                    ),
                    _buildStatItem(
                      Icons.format_list_numbered,
                      '#$posicaoRanking',
                      'Ranking',
                      Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Resumo Geral'),
          CardPrimary(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        Icons.quiz,
                        '${progresso.quizesCompletados}',
                        'Quizzes feitos',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        Icons.verified,
                        '${progresso.quizesPerfeitos}',
                        'Quizzes perfeitos',
                        Colors.teal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        Icons.trending_up,
                        mediaPontuacao.toStringAsFixed(1),
                        'Poder de Acerto',
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        Icons.military_tech,
                        '${conquistasDesbloqueadas.length}/${conquistas.length}',
                        'Conquistas obtidas',
                        Colors.purple,
                        onTap: conquistasBloqueadas.isEmpty
                            ? null
                            : () => _showConquistasBloqueadas(context, conquistasBloqueadas),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(title: 'Progresso do Nível'),
          CardPrimary(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${progresso.pontuacaoTotal} / ${progresso.proximoNivelPontos}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${(progressoNivel * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progressoNivel,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  minHeight: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(title: 'Progresso por Matéria'),
          if (progresso.quizesPorMateria.isEmpty)
            const CardPrimary(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Jogue um quiz para ver o progresso por matéria.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            ...progresso.quizesPorMateria.entries.map((entry) {
              final materia = entry.key;
              final quantidade = entry.value;
              final taxa = progresso.taxaAcertoPorMateria(materia);
              final acertos = progresso.acertosPorMateria[materia] ?? 0;
              final erros = progresso.errosPorMateria[materia] ?? 0;
              final pontos = progresso.pontosPorMateria[materia] ?? 0;
              return _buildProgressoMateriaCard(
                materia: materia,
                quantidade: quantidade,
                taxa: taxa,
                acertos: acertos,
                erros: erros,
                pontos: pontos,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildConquistasTab(List<dynamic> conquistasDesbloqueadas) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Conquistas Desbloqueadas'),
          const SizedBox(height: 12),
          if (conquistasDesbloqueadas.isEmpty)
            const CardPrimary(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Nenhuma conquista desbloqueada ainda.\nComplete quizes para desbloquear!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            ...conquistasDesbloqueadas.map(
              (conquista) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CardPrimary(
                  child: ListTile(
                    leading: Icon(conquista.icone, color: conquista.cor, size: 32),
                    title: Text(
                      conquista.titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(conquista.descricao),
                        if (conquista.dataDesbloqueio != null)
                          Text(
                            'Desbloqueada em: ${conquista.dataDesbloqueio!.day}/${conquista.dataDesbloqueio!.month}/${conquista.dataDesbloqueio!.year}',
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                    trailing: Text(
                      '+${conquista.pontos}',
                      style: TextStyle(
                        color: conquista.cor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoricoTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _historicoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Não foi possível carregar o histórico.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          );
        }

        final partidas = snapshot.data ?? const <Map<String, dynamic>>[];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Histórico de Partidas'),
              const SizedBox(height: 12),
              if (partidas.isEmpty)
                const CardPrimary(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Nenhuma partida concluída ainda.\nJogue um quiz para ver seu histórico!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                )
              else
                ...partidas.map(
                  (partida) {
                    final materia = partida['materia'] as String? ?? 'Sem matéria';
                    final ano = partida['ano'] as String? ?? '';
                    final topico = partida['topico'] as String? ?? '';
                    final pontos = (partida['pontuacao'] as int?) ?? 0;
                    final estrelas = (partida['estrelas'] as int?) ?? 0;
                    final acertos = (partida['acertos'] as int?) ?? 0;
                    final totalPerguntas = (partida['total_perguntas'] as int?) ?? 0;
                    final tempo = _formatarTempo(partida['tempo_segundos'] as int?);
                    final data = _formatarDataPartida(partida['data_partida'] as String?);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CardPrimary(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getCorMateria(materia),
                            child: const Icon(Icons.play_arrow, color: Colors.white),
                          ),
                          title: Text(
                            ano.isNotEmpty ? '$materia • $ano' : materia,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (topico.trim().isNotEmpty) Text(topico),
                              Text('Data: $data'),
                              Text('Acertos: $acertos/$totalPerguntas • Tempo: $tempo'),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '+$pontos',
                                style: TextStyle(
                                  color: _getCorMateria(materia),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$estrelas ⭐',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _carregarHistorico(String username) async {
    final dbUser = await AppDatabase.instance.getUserByUsername(username);
    if (dbUser?.id == null) return [];
    return AppDatabase.instance.buscarUltimasPartidas(dbUser!.id!, limit: 10);
  }

  String _formatarDataPartida(String? dataStr) {
    final data = dataStr != null ? DateTime.tryParse(dataStr) : null;
    if (data == null) return 'Data indisponível';
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  String _formatarTempo(int? segundos) {
    if (segundos == null || segundos <= 0) return 'Tempo indisponível';
    final minutos = segundos ~/ 60;
    final resto = segundos % 60;
    if (minutos == 0) {
      return '$resto s';
    }
    return '${minutos}m ${resto.toString().padLeft(2, '0')}s';
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String valor,
    String label,
    Color cor, {
    VoidCallback? onTap,
  }) {
    return CardPrimary(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cor, size: 28),
              ),
              const SizedBox(height: 6),
              Text(
                _formatResumoValor(valor),
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.blueGrey.shade900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.12,
                  color: Colors.blueGrey.shade800,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(height: 2),
                Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatResumoValor(String valor) {
    final normalized = valor.trim().replaceAll(',', '.');
    final numero = double.tryParse(normalized);
    if (numero == null) return valor;

    String removerDecimalInutil(String texto) {
      return texto.endsWith(',0') ? texto.substring(0, texto.length - 2) : texto;
    }

    String formatarNumero(double numero) {
      if (numero.truncateToDouble() == numero) {
        return numero.toInt().toString();
      }
      return removerDecimalInutil(
        numero.toStringAsFixed(1).replaceAll('.', ','),
      );
    }

    if (numero.abs() < 1000) {
      return formatarNumero(numero);
    }

    final abreviado = numero / 1000;
    return '${formatarNumero(abreviado)}k';
  }

  Future<void> _showConquistasBloqueadas(BuildContext context, List<dynamic> conquistasBloqueadas) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.78,
              minChildSize: 0.45,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Conquistas que faltam desbloquear',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${conquistasBloqueadas.length} conquistas pendentes',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: conquistasBloqueadas.isEmpty
                            ? Center(
                                child: Text(
                                  'Você já desbloqueou todas as conquistas!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: conquistasBloqueadas.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final conquista = conquistasBloqueadas[index];
                                  return CardPrimary(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: conquista.cor.withValues(alpha: 0.15),
                                        child: Icon(conquista.icone, color: conquista.cor),
                                      ),
                                      title: Text(
                                        conquista.titulo,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(conquista.descricao),
                                      trailing: Text(
                                        '+${conquista.pontos}',
                                        style: TextStyle(
                                          color: conquista.cor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
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

  Widget _buildProgressoMateriaCard({
    required String materia,
    required int quantidade,
    required double taxa,
    required int acertos,
    required int erros,
    required int pontos,
  }) {
    final icone = materia == 'Português' ? Icons.abc : Icons.calculate;
    final cor = materia == 'Português' ? Colors.blue : Colors.green;
    final totalPerguntas = acertos + erros;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CardPrimary(
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
                    '${taxa.toStringAsFixed(0)}%',
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
                _buildMiniStat('$acertos/$totalPerguntas', 'Acertos'),
                _buildMiniStat('$quantidade', 'Quizes'),
                _buildMiniStat('$pontos', 'Pontos'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(User? user) {
    try {
      final path = user?.profilePhotoPath;
      if (path != null && path.isNotEmpty) {
        return ClipOval(
          child: Image.file(
            File(path),
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        );
      }
    } catch (_) {}

    return Text(
      widget.username.isNotEmpty ? widget.username[0].toUpperCase() : 'U',
      style: const TextStyle(
        fontSize: 40,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Future<void> _editPhoto() async {
    final choice = await showModalBottomSheet<String?>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher da Galeria'),
              onTap: () => Navigator.of(context).pop('gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tirar Foto'),
              onTap: () => Navigator.of(context).pop('camera'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    final granted = await _requestPermission(choice == 'camera' ? Permission.camera : Permission.photos);
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissão negada para acessar a imagem.')),
      );
      return;
    }

    final picked = await _picker.pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: choice == 'camera' ? 1600 : 1200,
    );
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Ajustar foto',
          toolbarColor: DesignTokens.primary,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Ajustar foto',
          aspectRatioLockEnabled: true,
        ),
      ],
    );
    if (cropped == null) return;

    final dbUser = await AppDatabase.instance.getUserByUsername(widget.username);
    if (dbUser == null) return;

    final updated = dbUser.copy(profilePhotoPath: cropped.path);
    await AppDatabase.instance.updateUser(updated);

    UserService().addUserFromDb(
      User(
        username: dbUser.username,
        password: dbUser.password,
        fullName: dbUser.fullName,
        nickname: dbUser.nickname,
        grade: dbUser.grade,
        classGroup: dbUser.classGroup,
        schoolId: dbUser.schoolId,
        profilePhotoPath: cropped.path,
        role: dbUser.role,
      ),
    );

    if (!mounted) return;
    setState(() {});
  }

  Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.request();
    return status.isGranted;
  }

  Color _getCorNivel(String nivel) {
    switch (nivel) {
      case 'Novato':
        return Colors.grey;
      case 'Iniciante':
        return Colors.grey;
      case 'Aprendiz':
        return Colors.green;
      case 'Intermediário':
        return Colors.teal;
      case 'Estudioso':
        return Colors.blue;
      case 'Expert':
        return Colors.purple;
      case 'Mestre':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getCorMateria(String materia) {
    switch (materia) {
      case 'Matemática':
        return Colors.teal;
      case 'Português':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

}

String _publicName(String fullName, String? nickname, bool anonymize) {
  if (!anonymize) {
    return nickname?.trim().isNotEmpty == true ? nickname!.trim() : fullName;
  }

  if (nickname != null && nickname.trim().isNotEmpty) return nickname.trim();

  final parts = fullName.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return fullName;
  if (parts.length == 1) return parts.first;

  final first = parts.first;
  final lastInitial = parts.last.isNotEmpty ? parts.last[0].toUpperCase() : '';
  return '$first $lastInitial.';
}
