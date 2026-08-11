import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math' as math;
import 'login_page.dart';
import 'banco_perguntas.dart';
import 'services/privacy_settings_service.dart';
import 'database/app_database.dart';
import 'services/progresso_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/background_audio_service.dart';
import 'widgets/app_bar.dart';

// Widget para desenhar formas geométricas
class ShapeWidget extends StatelessWidget {
  final String shape;
  final Color color;
  final double size;

  const ShapeWidget({
    super.key,
    required this.shape,
    this.color = Colors.blue,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: ShapePainter(shape: shape, color: color),
    );
  }
}

class ShapePainter extends CustomPainter {
  final String shape;
  final Color color;

  ShapePainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    switch (shape.toLowerCase()) {
      case 'triângulo':
      case 'triangulo':
        final path = Path();
        path.moveTo(size.width / 2, 10);
        path.lineTo(size.width - 10, size.height - 10);
        path.lineTo(10, size.height - 10);
        path.close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
        break;

      case 'quadrado':
        final rect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, strokePaint);
        break;

      case 'retângulo':
      case 'retangulo':
        final rect = Rect.fromLTWH(10, size.height * 0.2, size.width - 20, size.height * 0.6);
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, strokePaint);
        break;

      case 'círculo':
      case 'circulo':
        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          (size.width - 20) / 2,
          paint,
        );
        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          (size.width - 20) / 2,
          strokePaint,
        );
        break;

      case 'pentágono':
      case 'pentagono':
        final path = Path();
        final centerX = size.width / 2;
        final centerY = size.height / 2;
        final radius = (size.width - 20) / 2;
        for (int i = 0; i < 5; i++) {
          final angle = (i * 2 * math.pi / 5) - math.pi / 2;
          final x = centerX + radius * math.cos(angle);
          final y = centerY + radius * math.sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
        break;

      default:
        // Forma padrão: estrela
        final path = Path();
        final centerX = size.width / 2;
        final centerY = size.height / 2;
        final outerRadius = (size.width - 20) / 2;
        final innerRadius = outerRadius / 2.5;
        for (int i = 0; i < 10; i++) {
          final radius = i.isEven ? outerRadius : innerRadius;
          final angle = (i * math.pi / 5) - math.pi / 2;
          final x = centerX + radius * math.cos(angle);
          final y = centerY + radius * math.sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(ShapePainter oldDelegate) => false;
}

// Widget para desenhar frações (pizza/círculo dividido)
class FractionWidget extends StatelessWidget {
  final int numerator;
  final int denominator;
  final double size;

  const FractionWidget({
    super.key,
    required this.numerator,
    required this.denominator,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: FractionPainter(
        numerator: numerator,
        denominator: denominator,
      ),
    );
  }
}

class FractionPainter extends CustomPainter {
  final int numerator;
  final int denominator;

  FractionPainter({required this.numerator, required this.denominator});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = (size.width - 20) / 2;

    // Desenha o círculo completo (fundo)
    final bgPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), radius, bgPaint);

    // Desenha as fatias preenchidas
    final fillPaint = Paint()
      ..color = Colors.orange.shade400
      ..style = PaintingStyle.fill;

    final anglePerSlice = 2 * math.pi / denominator;
    for (int i = 0; i < numerator; i++) {
      final path = Path();
      path.moveTo(centerX, centerY);
      final startAngle = -math.pi / 2 + (i * anglePerSlice);
      final sweepAngle = anglePerSlice;
      path.arcTo(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        startAngle,
        sweepAngle,
        false,
      );
      path.close();
      canvas.drawPath(path, fillPaint);
    }

    // Desenha as linhas divisórias
    final linePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < denominator; i++) {
      final angle = -math.pi / 2 + (i * anglePerSlice);
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      canvas.drawLine(Offset(centerX, centerY), Offset(x, y), linePaint);
    }

    // Contorno do círculo
    final outlinePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(centerX, centerY), radius, outlinePaint);
  }

  @override
  bool shouldRepaint(FractionPainter oldDelegate) => 
    oldDelegate.numerator != numerator || oldDelegate.denominator != denominator;
}

// Widget para mostrar operações matemáticas visualmente
// Widget estilo educativo para operações matemáticas (inspirado em apps infantis)
class MathCardStyleWidget extends StatelessWidget {
  final String operation;

  const MathCardStyleWidget({
    super.key,
    required this.operation,
  });

  @override
  Widget build(BuildContext context) {
    final parts = operation.split(' ');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6), // Creme claro
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade300, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade200.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildMathElements(parts),
        ),
      ),
    );
  }

  List<Widget> _buildMathElements(List<String> parts) {
    List<Widget> widgets = [];

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      
      if (part == '+' || part == '-' || part == '×' || part == 'x' || part == '÷' || part == '=') {
        // Símbolo de operação
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              part == 'x' ? '×' : part,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ),
        );
      } else if (int.tryParse(part) != null) {
        // Número
        widgets.add(
          Text(
            part,
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: Colors.red.shade700,
              letterSpacing: 2,
            ),
          ),
        );
      }
    }

    // Adiciona o "= ?" se não tiver
    if (!parts.contains('=')) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '=',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
        ),
      );
      widgets.add(
        Text(
          '?',
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w900,
            color: Colors.red.shade700,
          ),
        ),
      );
    }

    return widgets;
  }
}

class MathOperationWidget extends StatelessWidget {
  final String operation;
  final double size;

  const MathOperationWidget({
    super.key,
    required this.operation,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: _buildOperationWidgets(operation),
      ),
    );
  }

  List<Widget> _buildOperationWidgets(String op) {
    final parts = op.split(' ');
    List<Widget> widgets = [];

    for (var part in parts) {
      if (part == '+' || part == '-' || part == '×' || part == 'x' || part == '÷' || part == '=') {
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getOperationColor(part),
              shape: BoxShape.circle,
            ),
            child: Text(
              part == 'x' ? '×' : part,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      } else if (int.tryParse(part) != null) {
        // É um número
        widgets.add(
          Text(
            part,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Color _getOperationColor(String op) {
    switch (op) {
      case '+':
        return Colors.green;
      case '-':
        return Colors.red;
      case '×':
      case 'x':
        return Colors.purple;
      case '÷':
        return Colors.orange;
      case '=':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

// Widget para mostrar letras do alfabeto de forma destacada
class LetterWidget extends StatelessWidget {
  final String letter;
  final Color color;
  final double size;

  const LetterWidget({
    super.key,
    required this.letter,
    this.color = Colors.blue,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter.toUpperCase(),
          style: TextStyle(
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final double animationValue;
  final math.Random random = math.Random();
  final List<Color> colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
  ];

  ConfettiPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final confettiCount = 100;
    final paint = Paint();

    for (int i = 0; i < confettiCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = size.height * (0.2 + 0.8 * animationValue) - random.nextDouble() * size.height * 0.2;
      final confettiSize = 5.0 + random.nextDouble() * 5.0;
      
      paint.color = colors[random.nextInt(colors.length)];
      
      // Desenha confetes em diferentes formatos
      if (i % 3 == 0) {
        // Círculos
        canvas.drawCircle(Offset(x, y), confettiSize, paint);
      } else if (i % 3 == 1) {
        // Quadrados
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: confettiSize * 2, height: confettiSize * 2),
          paint,
        );
      } else {
        // Triângulos
        final path = Path();
        path.moveTo(x, y - confettiSize);
        path.lineTo(x + confettiSize, y + confettiSize);
        path.lineTo(x - confettiSize, y + confettiSize);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}

class JogoPage extends StatefulWidget {
  final String ano;
  final String materia;
  final String? topico; // Tópico específico da matéria (opcional para compatibilidade)

  const JogoPage({
    super.key,
    required this.ano,
    required this.materia,
    this.topico,
  });

  @override
  JogoPageState createState() => JogoPageState();
}

class JogoPageState extends State<JogoPage> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin, WidgetsBindingObserver {
  int perguntaAtual = 0;
  bool respondeu = false;
  bool acertou = false;
  bool _isMusicPlaying = false;
  bool _bgMusicAllowed = true;
  int pontuacao = 0;
  int estrelas = 0;
  
  late AnimationController _confettiController;
  late AnimationController _starController;
  late Animation<double> _starAnimation;
  final DateTime _inicioQuiz = DateTime.now();

  late List<Map<String, dynamic>> perguntas;
  final AudioPlayer _backgroundMusicPlayer = AudioPlayer();
  AudioPool? _acertoPool;
  AudioPool? _erroPool;
  AudioPlayer? _victoryPlayer; // Player one-shot para som de vitória
  late final FlutterTts _tts;
  bool _ttsEnabled = true;
  double _speechRate = 0.45; // velocidade do TTS (lenta por padrão)
  List<bool?> _progresso = []; // null = não respondida, true = acerto, false = erro
  int acertosConsecutivos = 0; // para avatar emocional
  String? _feedbackMsg; // mensagem curta de feedback
  Color _feedbackColor = Colors.transparent;
  bool _mostrarFeedback = false;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    perguntas = _gerarPerguntas(widget.ano, widget.materia, widget.topico);
  _progresso = List<bool?>.filled(perguntas.length, null);
    
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _starController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _starAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(
        parent: _starController,
        curve: Curves.elasticOut,
      ),
    );
    
    Future.microtask(() async {
      await _initAudio();
      await _initTts();
    });
  }

  Future<void> _initAudio() async {
    // Não criamos pools locais aqui; o BackgroundAudioService inicializa
    // pools de efeitos na inicialização da aplicação para evitar races.
    try {
      final privacy = PrivacySettingsService();
      await privacy.load();
      _bgMusicAllowed = privacy.enableBackgroundMusic;
      if (_bgMusicAllowed) {
        await BackgroundAudioService.instance.init();
        await BackgroundAudioService.instance.playLooped();
        if (mounted) setState(() => _isMusicPlaying = BackgroundAudioService.instance.isPlaying);
      }
    } catch (_) {
      _bgMusicAllowed = true;
      await BackgroundAudioService.instance.init();
      await BackgroundAudioService.instance.playLooped();
      if (mounted) setState(() => _isMusicPlaying = BackgroundAudioService.instance.isPlaying);
    }
  }

  Future<void> _initTts() async {
    _tts = FlutterTts();
    await _tts.setLanguage('pt-BR');
    await _tts.setSpeechRate(_speechRate); // usa velocidade configurável
    await _tts.setPitch(1.0);
    // No web/mobile, ignore erros silenciosamente
  }

  Future<void> _speakCurrentQuestion() async {
    if (!_ttsEnabled) return;
    if (perguntaAtual < 0 || perguntaAtual >= perguntas.length) return;
    final p = perguntas[perguntaAtual];
    final q = p['pergunta']?.toString() ?? '';
    final List opcoes = (p['opcoes'] as List? ?? []);
    final texto = StringBuffer()
      ..writeln(q)
      ..writeln('Opções:');
    for (var i = 0; i < opcoes.length; i++) {
      final letra = String.fromCharCode(65 + i); // A, B, C...
      texto.writeln('$letra) ${opcoes[i]}');
    }
    try {
      await _tts.setSpeechRate(_speechRate);
      await _tts.stop();
      await _tts.speak(texto.toString());
    } catch (_) {}
  }

  Future<void> _stopTts() async {
    try { await _tts.stop(); } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTts();

    Future.microtask(() async {
      try { await _backgroundMusicPlayer.stop(); } catch (_) {}
      try { await _backgroundMusicPlayer.dispose(); } catch (_) {}
      try { await _tts.stop(); } catch (_) {}
    });

    try {
      _confettiController.dispose();
      _starController.dispose();
    } catch (_) {}

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Pausa/parada ao ir para background
      try { _backgroundMusicPlayer.pause(); } catch (_) {}
      try { _victoryPlayer?.stop(); } catch (_) {}
    } else if (state == AppLifecycleState.resumed) {
      // Retoma música se estava ativa
      if (!_isMusicPlaying && _bgMusicAllowed) {
        _backgroundMusicPlayer.resume().then((_) {
          if (mounted) setState(() => _isMusicPlaying = true);
        }).catchError((_){});
      }
    }
  }

  Future<void> _stopAllAudio() async {
    // Delegar controle de background/effects ao serviço centralizado.
    try {
      await BackgroundAudioService.instance.stopForTopic();
    } catch (_) {}

    if (_victoryPlayer != null) {
      try { await _victoryPlayer!.stop(); } catch (_) {}
      try { await _victoryPlayer!.dispose(); } catch (_) {}
      _victoryPlayer = null;
    }
  }

  

  void _toggleMusic() async {
    if (!_bgMusicAllowed) return;
    if (_isMusicPlaying) {
      _backgroundMusicPlayer.pause();
      setState(() {
        _isMusicPlaying = false;
      });
    } else {
      _backgroundMusicPlayer.resume();
      setState(() {
        _isMusicPlaying = true;
      });
    }
  }

  Future<void> _playSoundEffect(String sound) async {
    if (!mounted) return;
    if (sound == 'acerto' || sound == 'erro') {
      try {
        await BackgroundAudioService.instance.playEffect(sound);
        return;
      } catch (_) {
        // se o serviço não estiver disponível, caímos para fallback local
      }
    }
    if (sound == 'acerto') {
      if (_acertoPool != null) {
        _acertoPool!.start();
      } else {
        try {
          _acertoPool = await AudioPool.create(source: AssetSource('sounds/acerto.mp3'), maxPlayers: 2);
          _acertoPool!.start();
        } catch (_) {}
      }
    } else if (sound == 'erro') {
      if (_erroPool != null) {
        _erroPool!.start();
      } else {
        try {
          _erroPool = await AudioPool.create(source: AssetSource('sounds/erro.mp3'), maxPlayers: 2);
          _erroPool!.start();
        } catch (_) {}
      }
    } else if (sound == 'vitoria') {
      // Usa um player one-shot dedicado e mantido em campo para poder parar ao sair
      try {
        // Se já existir um player de vitória tocando, pare e descarte
        if (_victoryPlayer != null) {
          try { await _victoryPlayer!.stop(); } catch (_) {}
          try { await _victoryPlayer!.dispose(); } catch (_) {}
        }
        final player = AudioPlayer();
        _victoryPlayer = player;
        await player.setReleaseMode(ReleaseMode.stop);
        // Ao terminar, descarte e limpe a referência
        player.onPlayerComplete.listen((event) async {
          try { await player.dispose(); } catch (_) {}
          if (identical(_victoryPlayer, player)) {
            _victoryPlayer = null;
          }
        });
        await player.play(AssetSource('sounds/vitoria.mp3'));
      } catch (_) {
        // Ignora erros de áudio para não quebrar o fluxo do jogo
      }
    }
  }

  List<Map<String, dynamic>> _gerarPerguntas(String ano, String materia, String? topico) {
    // Busca perguntas do banco de dados organizado por tópicos
    var perguntasEncontradas = BancoPerguntas.buscarPerguntas(materia, ano, topico);
    
    // Se encontrou perguntas no banco novo, embaralha e retorna
    if (perguntasEncontradas.isNotEmpty) {
      perguntasEncontradas.shuffle(math.Random());
      return perguntasEncontradas;
    }
    
    // Caso contrário, usa o sistema antigo (fallback para compatibilidade)
    List<Map<String, dynamic>> perguntasFallback = [];
    
    if (materia == 'Matemática') { 
      
      if (ano == '1º Ano') {
        perguntasFallback = [ 
          { 
            'pergunta': 'Quanto é 1 + 2?',
            'opcoes': ['2', '3', '4', '5'],
            'resposta': '3',
          },
          {
            'pergunta': 'Quanto é 5 - 3?',
            'opcoes': ['1', '2', '3', '4'],
            'resposta': '2',
          },
          {
            'pergunta': 'Quanto é 2 x 2?',
            'opcoes': ['2', '3', '4', '5'],
            'resposta': '4',
          },
          {
            'pergunta': 'Quanto é 8 ÷ 4?',
            'opcoes': ['1', '2', '3', '4'],
            'resposta': '2',
          },
          {
            'pergunta': 'Qual número vem depois do 4?',
            'opcoes': ['3', '4', '5', '6'],
            'resposta': '5',
          },
          {
            'pergunta': 'Qual é a metade de 10?',
            'opcoes': ['4', '5', '6', '7'],
            'resposta': '5',
          },
          {
            'pergunta': 'Quantos lados tem um triângulo?',
            'opcoes': ['2', '3', '4', '5'],
            'resposta': '3',
          },
          {
            'pergunta': 'Quanto é 10 - 7?',
            'opcoes': ['2', '3', '4', '5'],
            'resposta': '3',
          },
          {
            'pergunta': 'Quanto é 3 + 4?',
            'opcoes': ['6', '7', '8', '9'],
            'resposta': '7',
          },
          {
            'pergunta': 'Qual número vem antes do 6?',
            'opcoes': ['4', '5', '6', '7'],
            'resposta': '5',
          },
        ];
      } else if (ano == '2º Ano') {
        perguntasFallback = [
          {
            'pergunta': 'Quanto é 15 + 10?',
            'opcoes': ['20', '25', '30', '35'],
            'resposta': '25',
          },
          {
            'pergunta': 'Quanto é 20 - 8?',
            'opcoes': ['10', '12', '14', '16'],
            'resposta': '12',
          },
          {
            'pergunta': 'Qual número vem depois de 29?',
            'opcoes': ['28', '30', '31', '32'],
            'resposta': '30',
          },
          {
            'pergunta': 'Quanto é 3 x 4?',
            'opcoes': ['7', '10', '12', '15'],
            'resposta': '12',
          },
          {
            'pergunta': 'Se você tem 10 balas e ganha mais 5, com quantas balas você fica?',
            'opcoes': ['12', '15', '18', '20'],
            'resposta': '15',
          },
          {
            'pergunta': 'Qual é o dobro de 6?',
            'opcoes': ['10', '12', '14', '16'],
            'resposta': '12',
          },
          {
            'pergunta': 'Quanto é 50 - 20?',
            'opcoes': ['20', '30', '40', '50'],
            'resposta': '30',
          },
          {
            'pergunta': 'Quantos meses tem um ano?',
            'opcoes': ['10', '11', '12', '13'],
            'resposta': '12',
          },
          {
            'pergunta': 'Quanto é 2 + 2 + 2?',
            'opcoes': ['4', '5', '6', '8'],
            'resposta': '6',
          },
          {
            'pergunta': 'Qual forma geométrica tem 4 lados iguais?',
            'opcoes': ['Círculo', 'Triângulo', 'Quadrado', 'Retângulo'],
            'resposta': 'Quadrado',
          },
        ];
      } else if (ano == '3º Ano') {
        perguntasFallback = [
          {
            'pergunta': 'Quanto é 7 x 8?',
            'opcoes': ['49', '54', '56', '63'],
            'resposta': '56',
          },
          {
            'pergunta': 'Quanto é 45 ÷ 5?',
            'opcoes': ['7', '8', '9', '10'],
            'resposta': '9',
          },
          {
            'pergunta': 'Qual é a fração que representa a metade?',
            'opcoes': ['1/2', '1/3', '1/4', '2/3'],
            'resposta': '1/2',
          },
          {
            'pergunta': 'Quanto é 150 + 250?',
            'opcoes': ['300', '350', '400', '450'],
            'resposta': '400',
          },
          {
            'pergunta': 'Se um relógio marca 3:00, qual será o horário daqui a 45 minutos?',
            'opcoes': ['3:30', '3:45', '4:00', '4:15'],
            'resposta': '3:45',
          },
          {
            'pergunta': 'Quanto é 9 x 9?',
            'opcoes': ['72', '81', '90', '99'],
            'resposta': '81',
          },
          {
            'pergunta': 'Quanto é 100 - 35?',
            'opcoes': ['55', '65', '75', '85'],
            'resposta': '65',
          },
          {
            'pergunta': 'Quantos centímetros tem 1 metro?',
            'opcoes': ['10', '50', '100', '1000'],
            'resposta': '100',
          },
          {
            'pergunta': 'Qual é o resultado de 32 ÷ 4?',
            'opcoes': ['6', '7', '8', '9'],
            'resposta': '8',
          },
          {
            'pergunta': 'Se um pacote tem 6 biscoitos, quantos biscoitos há em 4 pacotes?',
            'opcoes': ['18', '20', '24', '30'],
            'resposta': '24',
          },
        ];
      } else if (ano == '4º Ano') {
        perguntasFallback = [
          {
            'pergunta': 'Quanto é 12 x 12?',
            'opcoes': ['124', '134', '144', '154'],
            'resposta': '144',
          },
          {
            'pergunta': 'Quanto é 250 ÷ 10?',
            'opcoes': ['10', '15', '25', '50'],
            'resposta': '25',
          },
          {
            'pergunta': 'Qual é o número decimal para a fração 1/4?',
            'opcoes': ['0.10', '0.25', '0.50', '0.75'],
            'resposta': '0.25',
          },
          {
            'pergunta': 'Quanto é 3/5 + 1/5?',
            'opcoes': ['3/5', '4/5', '1', '4/10'],
            'resposta': '4/5',
          },
          {
            'pergunta': 'Um filme começou às 14:30 e durou 1 hora e 30 minutos. Que horas ele terminou?',
            'opcoes': ['15:00', '15:30', '16:00', '16:30'],
            'resposta': '16:00',
          },
          {
            'pergunta': 'Qual é o perímetro de um quadrado com lado de 5 cm?',
            'opcoes': ['10 cm', '15 cm', '20 cm', '25 cm'],
            'resposta': '20 cm',
          },
          {
            'pergunta': 'Quanto é 1000 - 255?',
            'opcoes': ['745', '755', '845', '855'],
            'resposta': '745',
          },
          {
            'pergunta': 'Qual é o resultado de 15 x 6?',
            'opcoes': ['80', '90', '100', '110'],
            'resposta': '90',
          },
          {
            'pergunta': 'Qual número é maior: 0.5 ou 0.05?',
            'opcoes': ['0.5', '0.05', 'São iguais', 'Nenhum'],
            'resposta': '0.5',
          },
          {
            'pergunta': 'Quantos minutos tem em 2 horas?',
            'opcoes': ['60', '90', '120', '180'],
            'resposta': '120',
          },
        ];
      } else if (ano == '5º Ano') {
        perguntasFallback = [
          {
            'pergunta': 'Quanto é 12 x 5?',
            'opcoes': ['60', '55', '50', '65'],
            'resposta': '60',
          },
          {
            'pergunta': 'Qual é 15% de 100?',
            'opcoes': ['10', '15', '20', '25'],
            'resposta': '15',
          },
          {'pergunta': 'Qual é a raiz quadrada de 81?',
            'opcoes': ['7', '8', '9', '10'],
            'resposta': '9',
          }, 
          {
            'pergunta': 'Quanto é 100 dividido por 4?',
            'opcoes': ['20', '25', '30', '40'],
            'resposta': '25',
          },
          {'pergunta': 'Qual é o próximo número na sequência: 2, 4, 6, ...?',
            'opcoes': ['7', '8', '9', '10'],
            'resposta': '8',
          },
          {'pergunta': 'Qual é o valor de π (pi) arredondado?',
            'opcoes': ['3.12', '3.14', '3.16', '3.18'],
            'resposta': '3.14',
          },
          {'pergunta': 'Quantos lados tem um hexágono?',
            'opcoes': ['5', '6', '7', '8'],
            'resposta': '6',
          },
          {'pergunta': 'Quanto é 7² (7 ao quadrado)?',
            'opcoes': ['42', '47', '49', '52'],
            'resposta': '49',
          },
          {'pergunta': 'Qual é a fração equivalente a 0,5?',
            'opcoes': ['1/2', '1/3', '1/4', '1/5'],
            'resposta': '1/2',
          },
          {'pergunta': 'Qual é o valor de 3³ (3 ao cubo)?',
            'opcoes': ['6', '9', '27', '81'],
            'resposta': '27',
          },
         
          
        ];
      }
    } else if (materia == 'Português') {
      if (ano == '1º Ano') {
        perguntasFallback = [
          {
            'pergunta': 'Qual palavra começa com B?',
            'opcoes': ['Bola', 'Gato', 'Pato', 'Rato'],
            'resposta': 'Bola',
          },
          {
            'pergunta': 'Quantas sílabas tem “banana”?',
            'opcoes': ['2', '3', '4', '5'],
            'resposta': '3',
          },
          {
            'pergunta': 'Qual é o plural de “cão”?',
            'opcoes': ['cãos', 'cães', 'cãoes', 'cãezinhos'],
            'resposta': 'cães',
          },
          {
            'pergunta': 'Qual é a letra inicial de “sol”?',
            'opcoes': ['S', 'L', 'O', 'T'],
            'resposta': 'S',
          },
          {
            'pergunta': 'Qual palavra rima com “pato”?',
            'opcoes': ['gato', 'cachorro', 'elefante', 'leão'],
            'resposta': 'gato',
          },
          {
            'pergunta': 'Qual é o contrário de “grande”?',
            'opcoes': ['pequeno', 'alto', 'longo', 'forte'],
            'resposta': 'pequeno',
          },
          {
            'pergunta': 'Quantas letras tem a palavra “flor”?',
            'opcoes': ['3', '4', '5', '6'],
            'resposta': '4',
          },
          {
            'pergunta': 'Qual é o som da letra “M”?',
            'opcoes': ['mim', 'ê-me', 'mum', 'meu'],
            'resposta': 'ê-me',
          },
          {
            'pergunta': 'Qual palavra está escrita corretamente?',
            'opcoes': ['casa', 'kasa', 'qasa', 'xasa'],
            'resposta': 'casa',
          },
          {
            'pergunta': 'Qual é a vogal em “pato”?',
            'opcoes': ['a', 'e', 'i', 'o'],
            'resposta': 'a',
          },
        ];
      } else if (ano == '2º Ano') {
        perguntasFallback = [
          {
            'pergunta': 'Qual palavra tem 3 sílabas?',
            'opcoes': ['Sol', 'Gato', 'Macaco', 'Pé'],
            'resposta': 'Macaco',
          },
          {
            'pergunta': 'Qual é o plural de "flor"?',
            'opcoes': ['flors', 'flores', 'florzinhas', 'flore'],
            'resposta': 'flores',
          },
          {
            'pergunta': 'Qual palavra é um nome de animal?',
            'opcoes': ['Casa', 'Bola', 'Cachorro', 'Carro'],
            'resposta': 'Cachorro',
          },
          {
            'pergunta': 'Qual frase está correta?',
            'opcoes': ['Nós vai', 'Nós vamos', 'Nós foi', 'Nós fomos'],
            'resposta': 'Nós vamos',
          },
          {
            'pergunta': 'Qual palavra começa com a letra "G"?',
            'opcoes': ['Faca', 'Gelo', 'Rato', 'Bota'],
            'resposta': 'Gelo',
          },
          {
            'pergunta': 'Qual é o feminino de "menino"?',
            'opcoes': ['Menina', 'Meninão', 'Menininha', 'Moça'],
            'resposta': 'Menina',
          },
          {
            'pergunta': 'Qual palavra rima com "janela"?',
            'opcoes': ['Porta', 'Panela', 'Mesa', 'Cadeira'],
            'resposta': 'Panela',
          },
          {
            'pergunta': 'Qual é a primeira letra do seu nome?',
            'opcoes': ['A', 'B', 'C', 'Depende do nome'],
            'resposta': 'Depende do nome',
          },
          {
            'pergunta': 'Qual palavra é um verbo (ação)?',
            'opcoes': ['Bonito', 'Correr', 'Mesa', 'Feliz'],
            'resposta': 'Correr',
          },
          {
            'pergunta': 'Complete: O gato ___ leite.',
            'opcoes': ['come', 'bebe', 'pula', 'dorme'],
            'resposta': 'bebe',
          },
        ];
      } else if (ano == '3º Ano') {
        perguntasFallback = [
          {
            'pergunta': 'Qual palavra é um substantivo próprio?',
            'opcoes': ['cidade', 'país', 'Brasil', 'continente'],
            'resposta': 'Brasil',
          },
          {
            'pergunta': 'Qual é o sinônimo de "alegre"?',
            'opcoes': ['Triste', 'Contente', 'Bravo', 'Calmo'],
            'resposta': 'Contente',
          },
          {
            'pergunta': 'Qual palavra precisa de acento?',
            'opcoes': ['cafe', 'casa', 'bola', 'dado'],
            'resposta': 'cafe',
          },
          {
            'pergunta': 'Qual é o sujeito da frase "O cachorro latiu"?',
            'opcoes': ['latiu', 'O cachorro', 'cachorro', 'O'],
            'resposta': 'O cachorro',
          },
          {
            'pergunta': 'Qual é o antônimo de "quente"?',
            'opcoes': ['Frio', 'Morno', 'Gelado', 'Congelado'],
            'resposta': 'Frio',
          },
          {
            'pergunta': 'Qual o coletivo de "abelhas"?',
            'opcoes': ['Cardume', 'Manada', 'Enxame', 'Alcateia'],
            'resposta': 'Enxame',
          },
          {
            'pergunta': 'Qual palavra é um adjetivo?',
            'opcoes': ['Menina', 'Bonita', 'Corre', 'Casa'],
            'resposta': 'Bonita',
          },
          {
            'pergunta': 'Qual a pontuação correta para uma pergunta?',
            'opcoes': ['.', ',', '!', '?'],
            'resposta': '?',
          },
          {
            'pergunta': 'Qual palavra está no diminutivo?',
            'opcoes': ['Gatão', 'Gatinho', 'Gato', 'Gataria'],
            'resposta': 'Gatinho',
          },
          {
            'pergunta': 'Qual o verbo na frase "Eu comi uma maçã"?',
            'opcoes': ['Eu', 'comi', 'uma', 'maçã'],
            'resposta': 'comi',
          },
        ];
      } else if (ano == '4º Ano') {
        perguntasFallback = [
          {
            'pergunta': 'Qual o tempo verbal de "nós estudamos muito"?',
            'opcoes': ['Presente', 'Passado', 'Futuro', 'Infinitivo'],
            'resposta': 'Passado',
          },
          {
            'pergunta': 'Qual palavra é um pronome?',
            'opcoes': ['Ele', 'Casa', 'Bonito', 'Correr'],
            'resposta': 'Ele',
          },
          {
            'pergunta': 'Qual é o sujeito oculto em "Fomos ao parque"?',
            'opcoes': ['Eu', 'Tu', 'Ele', 'Nós'],
            'resposta': 'Nós',
          },
          {
            'pergunta': 'Qual a classificação da palavra "guarda-chuva"?',
            'opcoes': ['Substantivo simples', 'Substantivo composto', 'Adjetivo', 'Verbo'],
            'resposta': 'Substantivo composto',
          },
          {
            'pergunta': 'Qual palavra é paroxítona?',
            'opcoes': ['café', 'pássaro', 'caneta', 'cipó'],
            'resposta': 'caneta',
          },
          {
            'pergunta': 'O que significa a expressão "chover no molhado"?',
            'opcoes': ['Fazer algo inútil', 'Falar de algo óbvio', 'Ter muita sorte', 'Estar muito feliz'],
            'resposta': 'Fazer algo inútil',
          },
          {
            'pergunta': 'Qual é o advérbio na frase "Ele correu rapidamente"?',
            'opcoes': ['Ele', 'correu', 'rapidamente', 'Nenhum'],
            'resposta': 'rapidamente',
          },
          {
            'pergunta': 'Qual a forma correta: "fazem" ou "faz" cinco anos?',
            'opcoes': ['Fazem', 'Faz', 'Ambas estão corretas', 'Nenhuma está correta'],
            'resposta': 'Faz',
          },
          {
            'pergunta': 'Qual o plural de "troféu"?',
            'opcoes': ['troféus', 'troféis', 'trofeles', 'troféu'],
            'resposta': 'troféus',
          },
          {
            'pergunta': 'Na frase "A menina é inteligente", qual é o adjetivo?',
            'opcoes': ['A', 'menina', 'é', 'inteligente'],
            'resposta': 'inteligente',
          },
        ];
      } else if (ano == '5º Ano') {
        perguntasFallback = [
          {
            'pergunta': 'Figura de linguagem: “O vento cantava”?',
            'opcoes': ['metáfora', 'personificação', 'hipérbole', 'comparação'],
            'resposta': 'personificação',
          },
          {
            'pergunta': 'Qual é o predicado de “João leu o livro”?',
            'opcoes': ['João', 'leu o livro', 'livro', 'leu'],
            'resposta': 'leu o livro',
          },
          {
            'pergunta': 'Qual é o sujeito em “A menina brinca”?',
            'opcoes': ['A menina', 'brinca', 'menina', 'A'],
            'resposta': 'A menina',
          },
          {
            'pergunta': 'Qual é o antônimo de “feliz”?',
            'opcoes': ['triste', 'alegre', 'contente', 'satisfeito'],
            'resposta': 'triste',
          },
          {
            'pergunta': 'O que é um advérbio?',
            'opcoes': [
              'Palavra que modifica um verbo, adjetivo ou outro advérbio',
              'Palavra que substitui um substantivo',
              'Palavra que liga orações',
              'Palavra que expressa ação'
            ],
            'resposta':
                'Palavra que modifica um verbo, adjetivo ou outro advérbio',
          },
          {
            'pergunta': 'Qual é a forma correta do plural de “cidadão”?',
            'opcoes': ['cidadãos', 'cidadães', 'cidadões', 'cidadã'],
            'resposta': 'cidadãos',
          },
          {
            'pergunta': 'O que é uma oração subordinada?',
            'opcoes': [
              'Oração que depende de outra para fazer sentido',
              'Oração independente',
              'Oração principal',
              'Oração sem verbo'
            ],
            'resposta': 'Oração que depende de outra para fazer sentido',
          },
          {
            'pergunta': 'Qual é o tempo verbal de “eu cantarei”?',
            'opcoes': ['futuro do presente', 'pretérito perfeito', 'presente', 'futuro do pretérito'],
            'resposta': 'futuro do presente',
          },
          {
            'pergunta': 'Qual é a função do sujeito na frase?',
            'opcoes': [
              'Indicar quem pratica a ação do verbo',
              'Indicar a ação do verbo',
              'Indicar o local da ação',
              'Indicar o tempo da ação'
            ],
            'resposta': 'Indicar quem pratica a ação do verbo',
          },
          {
            'pergunta': 'Qual é o sinônimo de “rápido”?',
            'opcoes': ['veloz', 'lento', 'devagar', 'calmo'],
            'resposta': 'veloz',
          },
        ];
      }
    }

    // Embaralha e retorna as perguntas do fallback (ou pergunta padrão)
    perguntasFallback.shuffle(math.Random());
    return perguntasFallback.isNotEmpty ? perguntasFallback : [
      {
        'pergunta': 'Pergunta padrão',
        'opcoes': ['A', 'B', 'C', 'D'],
        'resposta': 'A',
      },
    ];
  }

  void _verificarResposta(String respostaSelecionada) async {
    // Para a leitura da pergunta ao responder
    await _stopTts();
    
    bool respostaCorreta = respostaSelecionada == perguntas[perguntaAtual]['resposta'];
    
    await _playSoundEffect(respostaCorreta ? 'acerto' : 'erro');
    
    setState(() {
      respondeu = true;
      acertou = respostaCorreta;
      _progresso[perguntaAtual] = respostaCorreta;
      if (respostaCorreta) {
        acertosConsecutivos++;
        _feedbackMsg = 'Muito bem! 😀';
        _feedbackColor = Colors.green;
      } else {
        acertosConsecutivos = 0;
        _feedbackMsg = 'Quase lá, tente outra! 😕';
        _feedbackColor = Colors.red;
      }
      _mostrarFeedback = true;
      
      // Sistema de pontuação
      if (respostaCorreta) {
        pontuacao += 10;
        // Adiciona uma estrela a cada 30 pontos
        if (pontuacao % 30 == 0) {
          estrelas++;
          _starController.reset();
          _starController.forward();
          
          // Exibe mensagem de incentivo
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "Você ganhou uma estrela!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.amber,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        
        // Ativa a animação de confete para respostas corretas
        _confettiController.reset();
        _confettiController.forward();
      }
  });
    // Oculta o feedback após curto período
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      // mantém simples: se ainda está na mesma pergunta, some
      setState(() {
        _mostrarFeedback = false;
      });
    });
  }


  void _proximaPergunta() async {
    // Para a leitura da pergunta anterior antes de avançar
    await _stopTts();
    
    if (perguntaAtual < perguntas.length - 1) {
      setState(() {
        perguntaAtual++;
        respondeu = false;
        acertou = false;
        _mostrarFeedback = false;
      });
    } else {
      // Finalizar o quiz - salvar no banco de dados
      await _salvarPartidaNoBanco();
      
      await _backgroundMusicPlayer.stop();
      try {
        await _backgroundMusicPlayer.dispose();
      } catch (e) {
  debugPrint('Error disposing background music player: $e');
      }
      await _playSoundEffect('vitoria');
      
      // Ativa a animação de confete para a vitória
      _confettiController.reset();
      _confettiController.forward();
      
      setState(() {
        perguntaAtual++; // Trigger rebuild to show completion screen
      });
    }
  }

  // Verifica se a pergunta deve exibir visualização
  bool _shouldShowVisualization(String question) {
    final lowerQuestion = question.toLowerCase();
    
    // Geometria
    if (_isGeometryQuestion(question)) return true;
    
    // Frações
    if (lowerQuestion.contains('fração') || lowerQuestion.contains('fracao') ||
        lowerQuestion.contains('metade') || lowerQuestion.contains('quarto') ||
        lowerQuestion.contains('pizza') || lowerQuestion.contains('pedaço') ||
        lowerQuestion.contains('pedaco') || lowerQuestion.contains('/')) {
      return true;
    }
    
    // Operações matemáticas básicas
    if ((lowerQuestion.contains('quanto é') || lowerQuestion.contains('quanto e')) &&
        (lowerQuestion.contains('+') || lowerQuestion.contains('-') || 
         lowerQuestion.contains('×') || lowerQuestion.contains('x ') ||
         lowerQuestion.contains('÷') || lowerQuestion.contains('dividido'))) {
      return true;
    }
    
    // Letras do alfabeto
    if (lowerQuestion.contains('letra') || lowerQuestion.contains('alfabeto') ||
        lowerQuestion.contains('vogal') || lowerQuestion.contains('consoante')) {
      return true;
    }
    
    return false;
  }

  // Verifica se é uma pergunta de geometria que deve exibir imagem
  bool _isGeometryQuestion(String question) {
    final geometryKeywords = [
      'triângulo', 'triangulo',
      'quadrado',
      'retângulo', 'retangulo',
      'círculo', 'circulo',
      'pentágono', 'pentagono',
      'lados tem',
      'cantos tem',
      'forma',
    ];
    
    final lowerQuestion = question.toLowerCase();
    return geometryKeywords.any((keyword) => lowerQuestion.contains(keyword));
  }

  // Constrói a visualização apropriada baseada na pergunta
  Widget _buildQuestionVisualization(String question) {
    final lowerQuestion = question.toLowerCase();
    
    // Geometria
    if (_isGeometryQuestion(question)) {
      return _buildGeometryImage(question);
    }
    
    // Frações
    if (lowerQuestion.contains('fração') || lowerQuestion.contains('fracao') ||
        lowerQuestion.contains('metade') || lowerQuestion.contains('quarto') ||
        lowerQuestion.contains('pizza') || lowerQuestion.contains('pedaço')) {
      return _buildFractionImage(question);
    }
    
    // Operações matemáticas
    if ((lowerQuestion.contains('quanto é') || lowerQuestion.contains('quanto e')) &&
        (lowerQuestion.contains('+') || lowerQuestion.contains('-') || 
         lowerQuestion.contains('×') || lowerQuestion.contains('x ') ||
         lowerQuestion.contains('÷'))) {
      return _buildMathOperationImage(question);
    }
    
    // Letras
    if (lowerQuestion.contains('letra') && 
        !lowerQuestion.contains('quantas') &&
        !lowerQuestion.contains('qual é a primeira')) {
      return _buildLetterImage(question);
    }
    
    return const SizedBox.shrink();
  }

  // Constrói a imagem da forma geométrica baseada na pergunta
  Widget _buildGeometryImage(String question) {
    String shape = 'quadrado'; // forma padrão
    Color color = Colors.blue.shade300;
    
    final lowerQuestion = question.toLowerCase();
    
    if (lowerQuestion.contains('triângulo') || lowerQuestion.contains('triangulo')) {
      shape = 'triângulo';
      color = Colors.red.shade300;
    } else if (lowerQuestion.contains('quadrado')) {
      shape = 'quadrado';
      color = Colors.blue.shade300;
    } else if (lowerQuestion.contains('retângulo') || lowerQuestion.contains('retangulo')) {
      shape = 'retângulo';
      color = Colors.green.shade300;
    } else if (lowerQuestion.contains('círculo') || lowerQuestion.contains('circulo')) {
      shape = 'círculo';
      color = Colors.orange.shade300;
    } else if (lowerQuestion.contains('pentágono') || lowerQuestion.contains('pentagono')) {
      shape = 'pentágono';
      color = Colors.purple.shade300;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: ShapeWidget(
        shape: shape,
        color: color,
        size: 100,
      ),
    );
  }

  // Constrói visualização de fração
  Widget _buildFractionImage(String question) {
    int numerator = 1;
    int denominator = 2;
    
    final lowerQuestion = question.toLowerCase();
    
    // Detecta frações específicas
    if (lowerQuestion.contains('metade') || lowerQuestion.contains('1/2')) {
      numerator = 1;
      denominator = 2;
    } else if (lowerQuestion.contains('1/4') || lowerQuestion.contains('um quarto')) {
      numerator = 1;
      denominator = 4;
    } else if (lowerQuestion.contains('3/4') || lowerQuestion.contains('três quartos')) {
      numerator = 3;
      denominator = 4;
    } else if (lowerQuestion.contains('2/8')) {
      numerator = 2;
      denominator = 8;
    } else if (lowerQuestion.contains('1/3')) {
      numerator = 1;
      denominator = 3;
    } else if (lowerQuestion.contains('2/3')) {
      numerator = 2;
      denominator = 3;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.shade200, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FractionWidget(
            numerator: numerator,
            denominator: denominator,
            size: 100,
          ),
          const SizedBox(height: 8),
          Text(
            '$numerator/$denominator',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // Constrói visualização de operação matemática
  Widget _buildMathOperationImage(String question) {
    // Extrai a operação da pergunta
    String operation = '';
    
    // Padrões comuns: "Quanto é 5 + 3?"
    final match = RegExp(r'(\d+)\s*([+\-×x÷])\s*(\d+)').firstMatch(question);
    if (match != null) {
      operation = '${match.group(1)} ${match.group(2)} ${match.group(3)}';
    }
    
    if (operation.isEmpty) return const SizedBox.shrink();
    
    // Usa o estilo especial (card com fundo creme) para todas as operações de matemática
    if (widget.materia == 'Matemática') {
      return MathCardStyleWidget(operation: operation);
    }
    
    // Estilo padrão para outras matérias
    return MathOperationWidget(operation: operation);
  }

  // Constrói visualização de letra
  Widget _buildLetterImage(String question) {
    final lowerQuestion = question.toLowerCase();
    String letter = '';
    MaterialColor colorMaterial = Colors.blue;
    
    // Tenta extrair a letra da pergunta
    final letters = 'abcdefghijklmnopqrstuvwxyz';
    for (var i = 0; i < letters.length; i++) {
      final char = letters[i].toUpperCase();
      if (lowerQuestion.contains(' $char ') || 
          lowerQuestion.contains('"$char"') ||
          lowerQuestion.contains('letra $char') ||
          lowerQuestion.endsWith(' $char?')) {
        letter = char;
        // Cores variadas para cada letra
        final colors = [
          Colors.red, Colors.blue, Colors.green, Colors.orange,
          Colors.purple, Colors.pink, Colors.teal, Colors.indigo,
        ];
        colorMaterial = colors[i % colors.length];
        break;
      }
    }
    
    if (letter.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorMaterial.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colorMaterial.shade200, width: 2),
      ),
      child: LetterWidget(
        letter: letter,
        color: colorMaterial,
        size: 80,
      ),
    );
  }

  Future<void> _salvarPartidaNoBanco() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id');
      final nomeUsuario = prefs.getString('usuario_nome');
      
      if (usuarioId == null) {
        debugPrint('Nenhum usuário logado, partida não será salva');
        return;
      }

      final totalAcertos = _progresso.where((acertou) => acertou == true).length;

      await AppDatabase.instance.salvarPartida({
        'usuario_id': usuarioId,
        'materia': widget.materia,
        'ano': widget.ano,
        'topico': widget.topico,
        'pontuacao': pontuacao,
        'estrelas': estrelas,
        'acertos': totalAcertos,
        'total_perguntas': perguntas.length,
        'tempo_segundos': DateTime.now().difference(_inicioQuiz).inSeconds,
        'data_partida': DateTime.now().toIso8601String(),
      });

      if (nomeUsuario != null && nomeUsuario.trim().isNotEmpty) {
        final tempoSegundos = DateTime.now().difference(_inicioQuiz).inSeconds;
        await ProgressoService().registrarResultadoQuiz(
          username: nomeUsuario,
          materia: widget.materia,
          pontos: pontuacao,
          estrelas: estrelas,
          acertos: totalAcertos,
          erros: perguntas.length - totalAcertos,
          perfeito: totalAcertos == perguntas.length,
          tempoSegundos: tempoSegundos,
        );
      }

      debugPrint('Partida salva: $pontuacao pontos, $estrelas estrelas, $totalAcertos/${ perguntas.length} acertos');
    } catch (e) {
      debugPrint('Erro ao salvar partida: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necessário para o AutomaticKeepAliveClientMixin
    
    // Verifica se as perguntas foram carregadas
    if (perguntas.isEmpty) {
      return PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop) return;
          await _stopAllAudio();
        },
        child: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    if (perguntaAtual >= perguntas.length) {
      return PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop) return;
          await _stopAllAudio();
        },
        child: Scaffold(
        appBar: AppTopBar(title: '${widget.materia} - ${widget.ano}'),
        body: Stack(
          children: [
            // Fundo colorido para atrair crianças
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue, Colors.lightBlueAccent],
                ),
              ),
            ),
            
            // Animação de confete
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ConfettiPainter(_confettiController.value),
                  size: Size.infinite,
                  child: Container(),
                );
              },
            ),
            
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animação de escala para o texto de parabéns
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.5, end: 1.0),
                    duration: const Duration(seconds: 1),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.2 * 255).toInt()),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '🎉 PARABÉNS! 🎉',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Você completou o quiz de ${widget.materia}!',
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 30),
                              const SizedBox(width: 10),
                              Text(
                                'Pontuação: $pontuacao',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await _stopAllAudio();
                      // Pequeno delay para garantir término do áudio
                      await Future.delayed(const Duration(milliseconds: 80));
                      if (!mounted) return;
                      navigator.pop();
                    },
                    icon: const Icon(Icons.arrow_back, size: 24),
                    label: const Text(
                      'VOLTAR PARA MATÉRIAS',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
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

    final pergunta = perguntas[perguntaAtual];

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) return;
        await _stopAllAudio();
      },
      child: Scaffold(
      appBar: AppTopBar(
        title: '${widget.materia} - ${widget.ano}',
        actions: [
          IconButton(
            tooltip: 'Ler Pergunta',
            icon: const Icon(Icons.volume_up),
            onPressed: _speakCurrentQuestion,
          ),
          IconButton(
            tooltip: _ttsEnabled ? 'Silenciar Leitura' : 'Ativar Leitura',
            icon: Icon(_ttsEnabled ? Icons.record_voice_over : Icons.voice_over_off),
            onPressed: () async {
              setState(() { _ttsEnabled = !_ttsEnabled; });
              if (!_ttsEnabled) {
                await _stopTts();
              }
            },
          ),
          IconButton(
            tooltip: _speechRate <= 0.5 ? 'Velocidade: Lenta' : 'Velocidade: Normal',
            icon: Icon(_speechRate <= 0.5 ? Icons.slow_motion_video : Icons.speed),
            onPressed: () async {
              setState(() {
                _speechRate = _speechRate <= 0.5 ? 0.7 : 0.45;
              });
              try { await _tts.setSpeechRate(_speechRate); } catch (_) {}
            },
          ),
          // Exibição da pontuação na AppBar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.white, size: 20),
                const SizedBox(width: 4),
                Text(
                  '$pontuacao',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair do jogo',
            onPressed: () async {
              try {
                await _stopAllAudio();
                try { await _backgroundMusicPlayer.stop(); } catch (_) {}
                try { await _backgroundMusicPlayer.dispose(); } catch (_) {}
              } catch (_) {}

              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _bgMusicAllowed ? _toggleMusic : null,
        backgroundColor: Colors.orange,
        tooltip: _isMusicPlaying ? 'Desligar música' : 'Ligar música',
        child: Icon(_isMusicPlaying ? Icons.music_off : Icons.music_note),
      ),
  body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.withValues(alpha: 0.3), Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Indicador de progresso
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Text(
                      'Pergunta ${perguntaAtual + 1} de ${perguntas.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Spacer(),
                    // Estrelas conquistadas
                    Row(
                      children: List.generate(
                        estrelas,
                        (index) => const Icon(Icons.star, color: Colors.amber, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
              // Avatar emocional e mensagem curta
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Text(
                        respondeu
                            ? (acertou ? '😄' : '😕')
                            : (acertosConsecutivos >= 2 ? '🤩' : '🙂'),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      acertosConsecutivos >= 2 ? 'Uau, continue assim!' : 'Vamos lá!',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Barra de progresso segmentada
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: List.generate(perguntas.length, (i) {
                    final status = _progresso[i];
                    final Color color = i == perguntaAtual
                        ? Colors.blue
                        : (status == null
                            ? Colors.grey.shade300
                            : (status ? Colors.green : Colors.red));
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 6),
              // Feedback animado curto
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _mostrarFeedback && (_feedbackMsg ?? '').isNotEmpty
                      ? Container(
                          key: const ValueKey('feedback'),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _feedbackColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _feedbackColor.withValues(alpha: 0.6)),
                          ),
                          child: Text(
                            _feedbackMsg!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _feedbackColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              // Transição entre perguntas (fade + slide)
              Expanded(
                child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  final offsetTween = Tween<Offset>(begin: const Offset(0.12, 0), end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeOut));
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: animation.drive(offsetTween),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  key: ValueKey(perguntaAtual),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cartão da pergunta com animação local
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0.95, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Exibe visualização apropriada baseada no tipo de pergunta
                              if (_shouldShowVisualization(pergunta['pergunta']))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildQuestionVisualization(pergunta['pergunta']),
                                ),
                              Text(
                                pergunta['pergunta'],
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if ((pergunta['dica'] ?? '').toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final dica = (pergunta['dica'] ?? '').toString();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Dica: $dica'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.lightbulb),
                          label: const Text('Dica'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: (pergunta['opcoes'] as List).length,
                        itemBuilder: (context, index) {
                          final opcao = pergunta['opcoes'][index];
                          Color buttonColor = Colors.blueAccent;
                          if (respondeu) {
                            buttonColor = opcao == pergunta['resposta']
                                ? Colors.green
                                : Colors.red;
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                            child: TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0.95, end: 1.0),
                              duration: Duration(milliseconds: 300 + (index * 100)),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: child,
                                );
                              },
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(15),
                                  onTap: respondeu ? null : () => _verificarResposta(opcao),
                                  child: Container(
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          buttonColor.withValues(alpha: 0.7),
                                          buttonColor.withValues(alpha: 0.5),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              String.fromCharCode(65 + index),
                                              style: TextStyle(
                                                color: buttonColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            opcao,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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

            // Área para exibição da animação de estrelas
            AnimatedBuilder(
              animation: _starAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _starController.value,
                  child: Transform.scale(
                    scale: _starAnimation.value,
                    child: Container(
                      height: 60,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 40),
                          const SizedBox(width: 8),
                          Text(
                            "Estrela conquistada!",
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (respondeu)
              ElevatedButton(
                onPressed: _proximaPergunta,
                child: Text(
                  perguntaAtual < perguntas.length - 1
                      ? 'Próxima'
                      : 'Finalizar',
                ),
              ),
            const SizedBox(height: 10),
          ],
          )
        ),
      )
      ),
    );
    }
    }