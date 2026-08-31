import 'package:flutter/material.dart';

import '../services/institutional_provisioning_service.dart';
import '../services/session_service.dart';
import '../widgets/app_bar.dart';
import 'access_choice_page.dart';
import 'privacy_settings_page.dart';

class InstitutionalAdminPage extends StatefulWidget {
  const InstitutionalAdminPage({super.key});

  @override
  State<InstitutionalAdminPage> createState() => _InstitutionalAdminPageState();
}

class _InstitutionalAdminPageState extends State<InstitutionalAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _schoolCode = TextEditingController();
  final _alias = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _classroomId = TextEditingController();
  final _lawfulBasis = TextEditingController();
  final _evidence = TextEditingController();
  String _role = 'student';
  String _consentStatus = 'granted';
  bool _busy = false;

  @override
  void dispose() {
    for (final controller in [
      _schoolCode,
      _alias,
      _name,
      _email,
      _password,
      _classroomId,
      _lawfulBasis,
      _evidence,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obrigatorio.' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await InstitutionalProvisioningService.createUser(
        role: _role,
        schoolCode: _schoolCode.text,
        loginAlias: _alias.text,
        displayName: _name.text,
        password: _password.text,
        email: _role == 'teacher' ? _email.text : null,
        classroomId: _role == 'student' ? _classroomId.text : null,
        consentStatus: _consentStatus,
        lawfulBasis: _lawfulBasis.text,
        evidenceReference: _evidence.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta institucional criada.')),
      );
      _alias.clear();
      _name.clear();
      _email.clear();
      _password.clear();
      _evidence.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Gestao institucional',
        actions: [
          IconButton(
            tooltip: 'Privacidade',
            icon: const Icon(Icons.policy_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacySettingsPage()),
            ),
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await SessionService.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AccessChoicePage()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Cadastre somente pessoas autorizadas. Para alunos, registre a base legal e uma referencia verificavel mantida pela escola.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Tipo de conta'),
              items: const [
                DropdownMenuItem(value: 'student', child: Text('Aluno')),
                DropdownMenuItem(value: 'teacher', child: Text('Educador')),
              ],
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _role = value!),
            ),
            _field(_schoolCode, 'Codigo da escola (ex.: SQ-EM-001)'),
            _field(_alias, 'Usuario/alias'),
            _field(_name, 'Nome de exibicao'),
            if (_role == 'teacher') _field(_email, 'E-mail institucional'),
            _field(_password, 'Senha temporaria', obscure: true),
            if (_role == 'student') ...[
              _field(_classroomId, 'ID da turma'),
              DropdownButtonFormField<String>(
                initialValue: _consentStatus,
                decoration: const InputDecoration(
                  labelText: 'Situacao da base legal',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'granted',
                    child: Text('Consentimento concedido'),
                  ),
                  DropdownMenuItem(
                    value: 'not_required',
                    child: Text('Outra base legal documentada'),
                  ),
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _consentStatus = value!),
              ),
              _field(_lawfulBasis, 'Base legal/finalidade documentada'),
              _field(_evidence, 'Referencia da evidencia/autorizacao'),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(
                _busy ? 'Cadastrando...' : 'Criar conta institucional',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: _required,
      ),
    );
  }
}
