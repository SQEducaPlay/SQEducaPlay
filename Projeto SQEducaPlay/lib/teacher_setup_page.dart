import 'package:flutter/material.dart';

import 'database/app_database.dart';
import 'models/user_model.dart';
import 'utils/password_utils.dart';
import 'user_service.dart';

class TeacherSetupPage extends StatefulWidget {
  const TeacherSetupPage({super.key});

  @override
  State<TeacherSetupPage> createState() => _TeacherSetupPageState();
}

class _TeacherSetupPageState extends State<TeacherSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _username = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _schoolId = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _code.dispose();
    _username.dispose();
    _name.dispose();
    _password.dispose();
    _schoolId.dispose();
    super.dispose();
  }

  Future<void> _createTeacher() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final service = UserService();
      await AppDatabase.instance.createTeacherFromInvite(
        inviteCode: _code.text,
        schoolId: _schoolId.text.trim(),
        teacher: User(
          username: service.normalizeUsername(_username.text),
          password: PasswordUtils.hashPassword(_password.text),
          fullName: _name.text.trim(),
          role: 'teacher',
          isApproved: true,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Educador cadastrado. Faça login para continuar.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('FormatException: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Primeiro acesso do educador')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Use o código de convite fornecido pela escola. O código é de uso único no fluxo de primeiro acesso.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _code,
              decoration: const InputDecoration(labelText: 'Código SQ-XXXX-XXXX'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Informe o código.' : null,
            ),
            TextFormField(
              controller: _schoolId,
              decoration: const InputDecoration(labelText: 'Identificador da escola'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe a escola vinculada ao convite.'
                  : null,
            ),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome completo'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Informe o nome.' : null,
            ),
            TextFormField(
              controller: _username,
              decoration: const InputDecoration(labelText: 'Nome de usuário'),
              validator: (value) => value == null || value.trim().length < 3 ? 'Informe um usuário válido.' : null,
            ),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
              validator: (value) => value == null || !PasswordUtils.isValidPassword(value)
                  ? 'Use pelo menos 8 caracteres, uma letra e um número.'
                  : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _createTeacher,
              child: Text(_saving ? 'Cadastrando...' : 'Criar acesso'),
            ),
          ],
        ),
      ),
    );
  }
}
