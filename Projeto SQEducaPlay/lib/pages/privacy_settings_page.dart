import 'package:flutter/material.dart';
import '../services/privacy_settings_service.dart';
import '../widgets/app_bar.dart';
import '../database/app_database.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'privacy_policy_page.dart';

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
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
              );
            },
            icon: const Icon(Icons.policy_outlined),
            label: const Text('Ler política de privacidade'),
          ),
          const SizedBox(height: 8),
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
          ElevatedButton.icon(
            onPressed: _exportData,
            icon: const Icon(Icons.download),
            label: const Text('Exportar meus dados (JSON)'),
          ),
          OutlinedButton.icon(
            onPressed: _deleteData,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Excluir meus dados'),
          ),
          const Text('Dica: você pode ajustar essas preferências a qualquer momento.'),
        ],
      ),
    );
  }

  Future<int?> _currentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('usuario_id');
  }

  Future<void> _exportData() async {
    final id = await _currentUserId();
    if (!mounted || id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Exportar dados'),
        content: const Text(
          'O JSON será copiado para a área de transferência. Evite compartilhá-lo em locais públicos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Copiar JSON'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final data = await AppDatabase.instance.exportUserData(id);
    if (!mounted || data == null) return;
    await Clipboard.setData(ClipboardData(text: jsonEncode(data)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('JSON copiado sem incluir a senha.')),
    );
  }

  Future<void> _deleteData() async {
    final confirmation = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir dados'),
        content: TextField(
          controller: confirmation,
          decoration: const InputDecoration(labelText: 'Digite EXCLUIR para confirmar'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, confirmation.text.trim() == 'EXCLUIR'),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    confirmation.dispose();
    if (confirmed != true) return;
    final id = await _currentUserId();
    if (id == null) return;
    await AppDatabase.instance.deleteUserData(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dados excluídos.')),
    );
  }
}
