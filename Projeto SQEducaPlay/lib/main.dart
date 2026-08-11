import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:flutter/services.dart';
import 'services/background_audio_service.dart';
import 'services/progresso_service.dart';
import 'theme/design_tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa o serviço de áudio de fundo uma vez por toda a aplicação
  try {
    await BackgroundAudioService.instance.init();
  } catch (_) {}
  // Carrega progresso persistido do banco para disponibilizar perfil/ranking
  try {
    await ProgressoService().carregarDoBanco();
  } catch (e) {
    // Não interrompe o início se houver problema com o DB
  }
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const SQEducaPlay());
}

class SQEducaPlay extends StatelessWidget {
  const SQEducaPlay({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQEducaPlay',
      debugShowCheckedModeBanner: false,
      theme: DesignTokens.lightTheme(),
      home: const LoginPage(),
    );
  }
}
