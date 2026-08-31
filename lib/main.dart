import 'package:flutter/material.dart';
import 'pages/access_choice_page.dart';
import 'package:flutter/services.dart';
import 'services/backend_service.dart';
import 'services/background_audio_service.dart';
import 'services/progresso_service.dart';
import 'services/user_service.dart';
import 'theme/design_tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Backend Supabase é opcional; sem --dart-define o app opera offline.
  await BackendService.instance.initialize();
  try {
    await BackgroundAudioService.instance.init();
  } catch (e, s) {
    debugPrint('Falha ao inicializar o serviço de áudio: $e\n$s');
  }
  try {
    await ProgressoService().carregarDoBanco();
  } catch (e, s) {
    debugPrint('Falha ao carregar o progresso do banco: $e\n$s');
  }

  UserService().ensureDevelopmentAdmin();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
      home: const AccessChoicePage(),
    );
  }
}
