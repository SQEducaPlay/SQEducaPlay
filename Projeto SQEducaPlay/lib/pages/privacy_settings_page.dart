import 'package:flutter/material.dart';
import '../services/privacy_settings_service.dart';
import '../widgets/app_bar.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  final privacy = PrivacySettingsService();

  @override
  void initState() {
    super.initState();
    privacy.load().then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'Privacidade (LGPD)'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Essas configurações ajudam a proteger os dados das crianças.\nAltere com responsabilidade e informe professores e responsáveis.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            title: const Text('Anonimizar nomes de alunos'),
            subtitle: const Text('Exibe apelido ou Primeiro nome + inicial do sobrenome'),
            value: privacy.anonymizeStudentNames,
            onChanged: (v) async {
              setState(() => privacy.anonymizeStudentNames = v);
              await privacy.save();
            },
          ),
          const Divider(),
          SwitchListTile.adaptive(
            title: const Text('Mostrar confete em conquistas'),
            subtitle: const Text('Animação rápida ao desbloquear conquistas'),
            value: privacy.enableConfetti,
            onChanged: (v) async {
              setState(() => privacy.enableConfetti = v);
              await privacy.save();
            },
          ),
          const Divider(),
          SwitchListTile.adaptive(
            title: const Text('Tocar sons ao celebrar'),
            subtitle: const Text('Efeito sonoro discreto junto ao confete'),
            value: privacy.enableSounds,
            onChanged: (v) async {
              setState(() => privacy.enableSounds = v);
              await privacy.save();
            },
          ),
          const Divider(),
          SwitchListTile.adaptive(
            title: const Text('Música de fundo no jogo'),
            subtitle: const Text('Desative para aulas ou ambientes silenciosos'),
            value: privacy.enableBackgroundMusic,
            onChanged: (v) async {
              setState(() => privacy.enableBackgroundMusic = v);
              await privacy.save();
            },
          ),
          const Divider(),
          SwitchListTile.adaptive(
            title: const Text('Mostrar escola no ranking de alunos'),
            subtitle: const Text('Desmarque para esconder a escola no ranking público de alunos'),
            value: privacy.showSchoolInStudentRanking,
            onChanged: (v) async {
              setState(() => privacy.showSchoolInStudentRanking = v);
              await privacy.save();
            },
          ),
          const Divider(),
          SwitchListTile.adaptive(
            title: const Text('Aluno ver primeiro a própria escola'),
            subtitle: const Text('Aplica filtro automático no ranking do aluno'),
            value: privacy.studentDefaultToOwnSchool,
            onChanged: (v) async {
              setState(() => privacy.studentDefaultToOwnSchool = v);
              await privacy.save();
            },
          ),
          const SizedBox(height: 24),
          const Text('Dica: você pode ajustar essas preferências a qualquer momento.'),
        ],
      ),
    );
  }
}
