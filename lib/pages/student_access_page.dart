import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../materias_page.dart';
import '../services/backend_service.dart';
import '../services/progresso_service.dart';
import '../services/remote_sync_service.dart';
import '../services/user_service.dart';
import '../widgets/confirm_exit_scope.dart';

/// Acesso independente do aluno: cria e usa a propria conta (e-mail e
/// senha), sem depender de um responsavel estar logado.
class StudentAccessPage extends StatefulWidget {
  final bool startWithSignUp;

  const StudentAccessPage({super.key, this.startWithSignUp = false});

  @override
  State<StudentAccessPage> createState() => _StudentAccessPageState();
}

class _StudentAccessPageState extends State<StudentAccessPage> {
  static const _supportEmail = 'suportesqeducaplay@gmail.com';
  static const _savedEmailKey = 'student_saved_email';
  static const _savedPasswordKey = 'student_saved_password';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();

  late bool _createAccount;
  bool _busy = false;
  bool _saveCredentials = true;
  String? _error;
  String? _info;
  String? _selectedGrade;
  List<Map<String, dynamic>> _schools = [];
  String? _selectedSchoolId;

  static const _grades = [
    '2º Ano Fundamental',
    '3º Ano Fundamental',
    '4º Ano Fundamental',
    '5º Ano Fundamental',
  ];

  @override
  void initState() {
    super.initState();
    _createAccount = widget.startWithSignUp;
    if (!_createAccount) {
      _loadSavedCredentials();
    } else {
      _loadSchools();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSchools() async {
    try {
      final schools = await RemoteSyncService.listActiveSchools();
      if (!mounted) return;
      setState(() => _schools = schools);
    } catch (_) {
      // Lista de escolas e opcional; segue sem ela se a busca falhar.
    }
  }

  Future<void> _loadSavedCredentials() async {
    String? savedEmail;
    try {
      final prefs = await SharedPreferences.getInstance();
      savedEmail = prefs.getString(_savedEmailKey);
    } catch (_) {
      return;
    }
    String? savedPassword;
    try {
      savedPassword = await _secureStorage.read(key: _savedPasswordKey);
    } catch (_) {
      // Armazenamento seguro indisponivel; segue sem preencher a senha.
    }
    if (!mounted) return;
    if (savedEmail != null && savedEmail.isNotEmpty) {
      _emailController.text = savedEmail;
    }
    if (savedPassword != null && savedPassword.isNotEmpty) {
      _passwordController.text = savedPassword;
    } else {
      setState(() => _saveCredentials = false);
    }
  }

  Future<void> _persistCredentials(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_saveCredentials) {
        await prefs.setString(_savedEmailKey, email);
      } else {
        await prefs.remove(_savedEmailKey);
      }
    } catch (_) {
      // Preferencias indisponiveis; a lembranca de e-mail sera ignorada.
    }
    if (_saveCredentials) {
      try {
        await _secureStorage.write(key: _savedPasswordKey, value: password);
      } catch (_) {
        // Sem suporte a armazenamento seguro; a senha nao sera lembrada.
      }
    } else {
      try {
        await _secureStorage.delete(key: _savedPasswordKey);
      } catch (_) {
        // Nada a remover se o armazenamento seguro nao estiver disponivel.
      }
    }
  }

  Future<void> _forgotPassword() async {
    if (!BackendService.instance.isInitialized) {
      setState(
        () => _error =
            'O acesso online ainda nao esta configurado nesta versao do aplicativo.',
      );
      return;
    }
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      setState(
        () => _error = 'Informe o e-mail da conta para redefinir a senha.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await BackendService.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? Uri.base.toString() : null,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _info =
            'Se houver conta com esse e-mail, enviamos um link para redefinir a senha.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Nao foi possivel enviar o e-mail agora. Tente novamente.';
      });
    }
  }

  Future<void> _showSupportDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajuda e suporte'),
        content: const SelectableText(
          'Duvidas, problemas de acesso ou solicitacoes sobre a conta: '
          '$_supportEmail',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: _supportEmail));
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('E-mail copiado.')));
            },
            child: const Text('Copiar e-mail'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  String _friendlyAuthError(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('invalid login credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (normalized.contains('already registered')) {
      return 'Esse e-mail ja tem conta. Escolha Entrar.';
    }
    if (normalized.contains('password')) {
      return 'A senha nao atende aos requisitos da conta.';
    }
    return 'Nao foi possivel autenticar. Verifique os dados e tente novamente.';
  }

  Future<void> _authenticate() async {
    if (!BackendService.instance.isInitialized) {
      setState(
        () => _error =
            'O acesso online ainda nao esta configurado nesta versao do aplicativo.',
      );
      return;
    }
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Informe um e-mail valido.');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'A senha deve ter pelo menos 8 caracteres.');
      return;
    }
    if (_createAccount) {
      if (_fullNameController.text.trim().isEmpty) {
        setState(() => _error = 'Informe seu nome.');
        return;
      }
      if (_selectedGrade == null) {
        setState(() => _error = 'Informe seu ano escolar.');
        return;
      }
    }

    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final auth = BackendService.instance.client.auth;
      if (_createAccount) {
        final response = await auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': _fullNameController.text.trim(),
            'account_type': 'student',
          },
          emailRedirectTo: kIsWeb ? Uri.base.toString() : null,
        );
        if (response.session == null) {
          setState(() {
            _busy = false;
            _error =
                'Confira seu e-mail e confirme a conta; depois volte e entre.';
          });
          return;
        }
        await RemoteSyncService.createSelfStudentProfile(
          fullName: _fullNameController.text.trim(),
          grade: _selectedGrade!,
          schoolId: _selectedSchoolId,
        );
      } else {
        await auth.signInWithPassword(email: email, password: password);
      }
      await _persistCredentials(email, password);
      await _enterGame();
    } on AuthException catch (error) {
      setState(() {
        _error = _friendlyAuthError(error.message);
        _busy = false;
      });
    } on PostgrestException {
      setState(() {
        _error = 'Esta conta nao e uma conta de aluno, ou o perfil ja existe.';
        _busy = false;
      });
    } catch (_) {
      setState(() {
        _error =
            'Nao foi possivel conectar. Confira a internet e tente novamente.';
        _busy = false;
      });
    }
  }

  Future<void> _enterGame() async {
    final child = await RemoteSyncService.fetchOwnStudentProfile();
    if (child == null) {
      setState(() {
        _busy = false;
        _error =
            'Esta conta ainda nao possui um perfil de aluno neste aplicativo.';
      });
      return;
    }
    final localUser = await RemoteSyncService.activateStudent(child);
    UserService().addUserFromDb(localUser);
    ProgressoService().setRemoteStudentScope(localUser.username);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt('usuario_id', localUser.id!);
    await preferences.setString('usuario_nome', localUser.username);
    await preferences.setString('usuario_grade', localUser.grade!);
    await preferences.setString('last_login_audience', 'student');
    await ProgressoService().carregarDoBanco();
    if (!mounted) return;

    final studentCode = child['student_code'] as String?;
    if (_createAccount && studentCode != null) {
      await _showStudentCodeDialog(studentCode);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            ConfirmExitScope(child: MateriasPage(ano: localUser.grade!)),
      ),
    );
  }

  Future<void> _showStudentCodeDialog(String studentCode) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Conta criada!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Guarde este codigo. Um responsavel pode usa-lo para '
              'acompanhar seu progresso (sem acessar sua senha ou conta):',
            ),
            const SizedBox(height: 12),
            SelectableText(
              studentCode,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: studentCode));
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Codigo copiado.')));
            },
            child: const Text('Copiar codigo'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmExitScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Acesso do aluno'),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'Ajuda e suporte',
              onPressed: _showSupportDialog,
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Icon(Icons.school, size: 52, color: Colors.blue),
                const SizedBox(height: 12),
                Text(
                  _createAccount
                      ? 'Criar minha conta'
                      : 'Entrar na minha conta',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
                if (_info != null) ...[
                  Text(
                    _info!,
                    style: const TextStyle(color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
                if (_createAccount)
                  TextField(
                    controller: _fullNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Seu nome'),
                  ),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: 'Seu e-mail'),
                ),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha (minimo 8 caracteres)',
                  ),
                  onSubmitted: (_) => _busy ? null : _authenticate(),
                ),
                if (_createAccount) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGrade,
                    decoration: const InputDecoration(labelText: 'Ano escolar'),
                    items: _grades
                        .map(
                          (grade) => DropdownMenuItem(
                            value: grade,
                            child: Text(grade),
                          ),
                        )
                        .toList(),
                    onChanged: _busy
                        ? null
                        : (grade) => setState(() => _selectedGrade = grade),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSchoolId ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Escola (opcional)',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Nao informar agora'),
                      ),
                      ..._schools.map(
                        (school) => DropdownMenuItem(
                          value: school['id'] as String,
                          child: Text(school['name'] as String),
                        ),
                      ),
                    ],
                    onChanged: _busy
                        ? null
                        : (schoolId) => setState(
                            () => _selectedSchoolId = schoolId == ''
                                ? null
                                : schoolId,
                          ),
                  ),
                ],
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _saveCredentials,
                  onChanged: _busy
                      ? null
                      : (value) =>
                            setState(() => _saveCredentials = value ?? false),
                  title: const Text(
                    'Salvar senha neste aparelho',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _busy ? null : _authenticate,
                  child: Text(_createAccount ? 'Criar conta' : 'Entrar'),
                ),
                if (!_createAccount)
                  TextButton(
                    onPressed: _busy ? null : _forgotPassword,
                    child: const Text('Esqueci a senha'),
                  ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _createAccount = !_createAccount;
                          _error = null;
                          _info = null;
                          if (_createAccount) _loadSchools();
                        }),
                  child: Text(
                    _createAccount
                        ? 'Ja tem conta? Entrar'
                        : 'Novo por aqui? Criar minha conta',
                  ),
                ),
                if (_busy) ...[
                  const SizedBox(height: 18),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
