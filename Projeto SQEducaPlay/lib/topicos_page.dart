import 'package:flutter/material.dart';
import 'jogo_page.dart';
import 'banco_perguntas.dart';
import 'widgets/app_bar.dart';

class TopicosPage extends StatelessWidget {
  final String ano;
  final String materia;

  const TopicosPage({super.key, required this.ano, required this.materia});

  String _canonicalGrade(String grade) {
    final value = grade.trim();
    if (value.endsWith('Fundamental')) return value;
    return '$value Fundamental';
  }

  // Busca os tópicos disponíveis no banco de perguntas
  List<Map<String, dynamic>> _getTopicos() {
    final anoNormalizado = _canonicalGrade(ano);
    final perguntas = BancoPerguntas.perguntas[materia]?[anoNormalizado];
    
    if (perguntas == null || perguntas.isEmpty) {
      return [];
    }

    // Cria lista de tópicos com ícones e cores apropriadas
    List<Map<String, dynamic>> topicos = [];
    int colorIndex = 0;
    
    // Ordem específica dos tópicos BNCC para Português por ano
    List<String> ordemTopicosPortugues = [];
    
    if (anoNormalizado == '2º Ano Fundamental') {
      ordemTopicosPortugues = [
        'Leitura/escuta e interpretação',
        'Análise linguística/semiótica (ortografia e pontuação)',
        'Análise linguística/semiótica (vocabulário)'
      ];
    } else if (anoNormalizado == '5º Ano Fundamental') {
      ordemTopicosPortugues = [
        'Leitura/escuta e interpretação',
        'Produção de textos'
      ];
    } else {
      // 3º e 4º Anos
      ordemTopicosPortugues = [
        'Leitura/escuta e interpretação',
        'Análise linguística/semiótica (ortografia)',
        'Produção de textos'
      ];
    }
    
    // Cores variadas para os cards
    final cores = [
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.deepOrange,
      Colors.purple,
      Colors.teal,
      Colors.blue,
      Colors.green,
      Colors.red,
    ];

    // Ícones por tipo de tópico
    Map<String, IconData> iconesMatematica = {
      'números': Icons.numbers,
      'adição': Icons.add,
      'subtração': Icons.remove,
      'multiplicação': Icons.close,
      'divisão': Icons.clear,
      'frações': Icons.pie_chart,
      'geometria': Icons.square,
      'formas': Icons.category,
      'área': Icons.crop_square,
      'perímetro': Icons.border_style,
      'decimais': Icons.looks_one,
      'medidas': Icons.straighten,
      'tempo': Icons.access_time,
      'operações': Icons.calculate,
      'sistema': Icons.grid_3x3,
    };

    Map<String, IconData> iconesPortugues = {
      'Alfabetização': Icons.abc,
      'Análise linguística/semiótica': Icons.spellcheck,
      'Leitura/escuta e interpretação': Icons.menu_book,
      'Análise linguística/semiótica (ortografia e pontuação)': Icons.spellcheck,
      'Análise linguística/semiótica (vocabulário)': Icons.book,
      'Produção de textos': Icons.create,
      'Ortografia': Icons.spellcheck,
      'ortografia': Icons.spellcheck,
      'pontuação': Icons.edit,
      'texto': Icons.description,
      'linguística': Icons.spellcheck,
      'semiótica': Icons.spellcheck,
      'leitura': Icons.menu_book,
      'interpretação': Icons.article,
    };

    // Lista para armazenar os tópicos na ordem correta
    List<String> topicosOrdenados = [];
    
    if (materia == 'Português') {
      // Filtra os tópicos disponíveis na ordem BNCC
      topicosOrdenados = ordemTopicosPortugues
          .where((t) => perguntas.keys.contains(t))
          .toList();
    } else {
      // Para outras matérias, mantém a ordem original
      topicosOrdenados = perguntas.keys.toList();
    }

    for (var topico in topicosOrdenados) {
      IconData icone = Icons.star; // ícone padrão
      
      // Seleciona ícone baseado no nome do tópico
      if (materia == 'Matemática') {
        for (var palavra in iconesMatematica.keys) {
          if (topico.toLowerCase().contains(palavra)) {
            icone = iconesMatematica[palavra]!;
            break;
          }
        }
      } else if (materia == 'Português') {
        // Usa o tópico exato para encontrar o ícone
        icone = iconesPortugues[topico] ?? Icons.star;
      }

      topicos.add({
        'nome': topico,
        'icone': icone,
        'cor': cores[colorIndex % cores.length],
      });
      colorIndex++;
    }

    return topicos;
  }

  @override
  Widget build(BuildContext context) {
    final topicos = _getTopicos();
    final anoNormalizado = _canonicalGrade(ano);

    return Scaffold(
      appBar: AppTopBar(title: '$materia - $anoNormalizado'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Escolha um tópico:',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: topicos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum tópico disponível\npara $materia - $anoNormalizado',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600
                          ? 3
                          : MediaQuery.of(context).size.width > 420
                            ? 2
                            : 1,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        childAspectRatio: MediaQuery.of(context).size.width > 600
                          ? 1.0
                          : MediaQuery.of(context).size.width > 420
                            ? 0.88
                            : 1.8,
                        ),
                        itemCount: topicos.length,
                        itemBuilder: (context, index) {
                          final topico = topicos[index];
                          return TweenAnimationBuilder(
                            duration: Duration(milliseconds: 300 + (index * 100)),
                            tween: Tween<double>(begin: 0, end: 1),
                            builder: (context, double value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Opacity(
                                  opacity: value,
                                  child: child,
                                ),
                              );
                            },
                            child: Card(
                              elevation: 8,
                              shadowColor: topico['cor'].withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => JogoPage(
                                        ano: anoNormalizado,
                                        materia: materia,
                                        topico: topico['nome'],
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        topico['cor'],
                                        topico['cor'].withValues(alpha: 0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
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
                                          topico['icone'],
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        topico['nome'],
                                        textAlign: TextAlign.center,
                                        maxLines: 3,
                                        softWrap: true,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.1,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              offset: Offset(0, 1),
                                              blurRadius: 3,
                                              color: Colors.black26,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
