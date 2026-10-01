import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../services/account_data_service.dart';
import '../services/firebase_service.dart';
import '../services/privacy_settings_service.dart';
import '../services/user_service.dart';
import '../widgets/app_bar.dart';
import 'access_choice_page.dart';
import 'privacy_policy_page.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  final privacy = PrivacySettingsService();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    privacy.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _exportData() async {
    final user = UserService().currentUser;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      final json = await AccountDataService.exportAsJson(user);
      await Clipboard.setData(ClipboardData(text: json));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cópia dos dados copiada para a área de transferência.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível gerar a cópia dos dados.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete() async {
    final user = UserService().currentUser;
    if (user == null) return;
    final confirmation = TextEditingController();
    final password = TextEditingController();
    final requiresFirebasePassword =
        FirebaseService.instance.isInitialized &&
        FirebaseService.instance.auth.currentUser != null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir conta e dados?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta ação remove a conta, o histórico de atividades e o progresso. '
              'Ela não pode ser desfeita. Digite EXCLUIR para confirmar.',
            ),
            const SizedBox(height: 16),
            if (requiresFirebasePassword)
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha da conta'),
              ),
            if (requiresFirebasePassword) const SizedBox(height: 12),
            TextField(
              controller: confirmation,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Confirmação'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              confirmation.text.trim().toUpperCase() == 'EXCLUIR' &&
                  (!requiresFirebasePassword || password.text.isNotEmpty),
            ),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Excluir definitivamente'),
          ),
        ],
      ),
    );
    final enteredPassword = password.text;
    confirmation.dispose();
    password.dispose();
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await AccountDataService.deleteAccount(
        user,
        firebasePassword: enteredPassword,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AccessChoicePage()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is firebase_auth.FirebaseAuthException
          ? switch (error.code) {
              'wrong-password' ||
              'invalid-credential' => 'A senha da conta está incorreta.',
              'requires-recent-login' =>
                'Entre novamente na conta e repita a exclusão.',
              _ => 'Não foi possível excluir a conta (${error.code}).',
            }
          : error is StateError
          ? error.message.toString()
          : 'Não foi possível concluir a exclusão ($error).';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
          ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: const Text('Ler aviso de privacidade'),
            subtitle: const Text('Versão e informações sobre o uso de dados'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
            ),
          ),
          const Divider(),
          SwitchListTile.adaptive(
            title: const Text('Anonimizar nomes de alunos'),
            subtitle: const Text(
              'Exibe apelido ou Primeiro nome + inicial do sobrenome',
            ),
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
            title: const Text('Reduzir movimento'),
            subtitle: const Text('Desativa confetes e animações decorativas'),
            value: privacy.reduceMotion,
            onChanged: (v) async {
              setState(() => privacy.reduceMotion = v);
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
            subtitle: const Text(
              'Desative para aulas ou ambientes silenciosos',
            ),
            value: privacy.enableBackgroundMusic,
            onChanged: (v) async {
              setState(() => privacy.enableBackgroundMusic = v);
              await privacy.save();
            },
          ),
          const Divider(),
          SwitchListTile.adaptive(
            title: const Text('Mostrar escola no ranking de alunos'),
            subtitle: const Text(
              'Desmarque para esconder a escola no ranking público de alunos',
            ),
            value: privacy.showSchoolInStudentRanking,
            onChanged: (v) async {
              setState(() => privacy.showSchoolInStudentRanking = v);
              await privacy.save();
            },
          ),
          const Divider(),
          SwitchListTile.adaptive(
            title: const Text('Aluno ver primeiro a própria escola'),
            subtitle: const Text(
              'Aplica filtro automático no ranking do aluno',
            ),
            value: privacy.studentDefaultToOwnSchool,
            onChanged: (v) async {
              setState(() => privacy.studentDefaultToOwnSchool = v);
              await privacy.save();
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Seus dados',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _exportData,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Copiar meus dados (JSON)'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _confirmDelete,
            icon: const Icon(Icons.delete_forever_outlined),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
            label: const Text('Excluir minha conta e meus dados'),
          ),
          if (_busy) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
          const SizedBox(height: 24),
          const Text(
            'Dica: você pode ajustar essas preferências a qualquer momento.',
          ),
        ],
      ),
    );
  }
}
