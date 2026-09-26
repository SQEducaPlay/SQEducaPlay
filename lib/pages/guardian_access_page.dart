import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../config/privacy_policy_config.dart';
import '../database/app_database.dart';
import '../home_page.dart';
import '../materias_page.dart';
import '../models/user_model.dart';
import 'access_choice_page.dart';
import '../services/backend_service.dart';
import '../services/password_service.dart';
import '../services/progresso_service.dart';
import '../services/remote_sync_service.dart';
import '../services/user_service.dart';
import '../widgets/confirm_exit_scope.dart';

class GuardianAccessPage extends StatefulWidget {
  final bool startWithSignUp;

  const GuardianAccessPage({super.key, this.startWithSignUp = false});

  @override
  State<GuardianAccessPage> createState() => _GuardianAccessPageState();
}

class _GuardianAccessPageState extends State<GuardianAccessPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _childNameController = TextEditingController();
  final _childUsernameController = TextEditingController();
  final _childNicknameController = TextEditingController();

  late bool _createAccount;
  bool _busy = false;
  bool _consentAccepted = false;
  String? _error;
  String? _guardianRole;
  String? _guardianFullName;
  String? _selectedGrade;
  List<Map<String, dynamic>> _children = [];

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
    if (BackendService.instance.isInitialized &&
        BackendService.instance.client.auth.currentSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAccount());
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _guardianNameController.dispose();
    _childNameController.dispose();
    _childUsernameController.dispose();
    _childNicknameController.dispose();
    super.dispose();
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
    if (_createAccount && _guardianNameController.text.trim().isEmpty) {
      setState(() => _error = 'Informe o nome do responsavel.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = BackendService.instance.client.auth;
      if (_createAccount) {
        final response = await auth.signUp(
          email: email,
          password: password,
          data: {'full_name': _guardianNameController.text.trim()},
        );
        if (response.session == null) {
          setState(() {
            _busy = false;
            _error =
                'Confira seu e-mail e confirme a conta; depois volte e entre.';
          });
          return;
        }
      } else {
        await auth.signInWithPassword(email: email, password: password);
      }
      await _loadAccount();
    } on AuthException catch (error) {
      setState(() {
        _error = _friendlyAuthError(error.message);
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

  Future<void> _loadAccount() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = BackendService.instance.client;
      final authUser = client.auth.currentUser;
      if (authUser == null) throw StateError('Sessao encerrada.');
      final profile = await client
          .from('profiles')
          .select('id, full_name, role')
          .eq('id', authUser.id)
          .maybeSingle();
      if (profile == null) {
        throw StateError('O perfil da conta ainda nao foi criado no banco.');
      }
      final role = profile['role'] as String? ?? 'guardian';
      if (role != 'guardian' && role != 'admin') {
        setState(() {
          _error =
              'Esta conta e institucional; o acesso online de educadores sera ativado depois.';
          _busy = false;
        });
        return;
      }

      final children = await RemoteSyncService.listChildren();
      if (!mounted) return;
      setState(() {
        _guardianRole = role;
        _guardianFullName = profile['full_name'] as String? ?? '';
        _children = children;
        _busy = false;
        _createAccount = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Nao foi possivel carregar a conta. Tente novamente.';
        _busy = false;
      });
    }
  }

  Future<void> _openAdmin() async {
    final authUser = BackendService.instance.client.auth.currentUser;
    if (authUser == null) {
      setState(() => _error = 'A sessao do administrador expirou.');
      return;
    }
    final user = User(
      username: '_admin_${authUser.id.substring(0, 12)}',
      password: RemoteSyncService.createClientSessionId(),
      fullName: _guardianFullName ?? 'Administrador',
      role: 'admin',
    );
    final username = user.username;
    final localUser =
        await AppDatabase.instance.getUserByUsername(username) ??
        await AppDatabase.instance.createUser(user);
    UserService().addUserFromDb(localUser);
    ProgressoService().setRemoteStudentScope(null);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt('usuario_id', localUser.id!);
    await preferences.setString('usuario_nome', localUser.username);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ConfirmExitScope(child: HomePage())),
    );
  }

  Future<void> _createChild() async {
    final username = _childUsernameController.text.trim().toLowerCase();
    final fullName = _childNameController.text.trim();
    if (!RegExp(r'^[a-zA-Z0-9._-]{3,20}$').hasMatch(username)) {
      setState(
        () => _error =
            'O usuario do perfil deve ter de 3 a 20 caracteres: letras, numeros, ponto, hifen ou underline.',
      );
      return;
    }
    if (fullName.isEmpty || _selectedGrade == null) {
      setState(() => _error = 'Informe o nome e o ano escolar do perfil.');
      return;
    }
    if (!_consentAccepted) {
      setState(() => _error = 'Confirme a autorizacao do responsavel.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await RemoteSyncService.createStudent(
        username: username,
        fullName: fullName,
        nickname: _childNicknameController.text.trim().isEmpty
            ? null
            : _childNicknameController.text.trim(),
        grade: _selectedGrade!,
        consentVersion: PrivacyPolicyConfig.version,
      );
      _childNameController.clear();
      _childUsernameController.clear();
      _childNicknameController.clear();
      _consentAccepted = false;
      await _loadAccount();
    } on PostgrestException catch (error) {
      setState(() {
        _error = error.message.contains('already in use')
            ? 'Esse usuario ja esta em uso. Escolha outro.'
            : 'Nao foi possivel criar o perfil. Confira os dados e tente novamente.';
        _busy = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Nao foi possivel criar o perfil. Tente novamente.';
        _busy = false;
      });
    }
  }

  Future<void> _selectChild(Map<String, dynamic> child) async {
    if (child['status'] != 'active') return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final localUser = await RemoteSyncService.activateStudent(child);
      final localStudents =
          (await AppDatabase.instance.getLocalStudentsWithUnlinkedHistory())
              .where((user) => user.id != localUser.id)
              .toList();
      if (localStudents.isNotEmpty) {
        final migration = await _confirmLocalHistoryMigration(
          localStudents,
          child['nickname'] as String? ?? child['full_name'] as String,
        );
        if (migration != null) {
          await RemoteSyncService.migrateLocalStudentHistory(
            sourceUser: migration.user,
            sourcePassword: migration.password,
            remoteStudent: localUser,
            consentVersion: PrivacyPolicyConfig.version,
          );
        }
      }
      UserService().addUserFromDb(localUser);
      ProgressoService().setRemoteStudentScope(localUser.username);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setInt('usuario_id', localUser.id!);
      await preferences.setString('usuario_nome', localUser.username);
      await preferences.setString('usuario_grade', localUser.grade!);
      await preferences.setString('last_login_audience', 'student');
      await ProgressoService().carregarDoBanco();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              ConfirmExitScope(child: MateriasPage(ano: localUser.grade!)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Nao foi possivel sincronizar. Confira a conexao e tente novamente.';
        _busy = false;
      });
    }
  }

  Future<({User user, String password})?> _confirmLocalHistoryMigration(
    List<User> localStudents,
    String destinationName,
  ) async {
    final passwordController = TextEditingController();
    User selectedUser = localStudents.first;
    bool consent = false;
    String? validationError;
    try {
      return await showDialog<({User user, String password})>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Encontramos progresso neste aparelho'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Escolha a conta local que pertence ao perfil "$destinationName". '
                    'As partidas e respostas serao enviadas para a nuvem.',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selectedUser.id,
                    decoration: const InputDecoration(
                      labelText: 'Conta local de aluno',
                    ),
                    items: localStudents
                        .map(
                          (user) => DropdownMenuItem(
                            value: user.id,
                            child: Text(user.nickname ?? user.username),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      final match = localStudents
                          .where((user) => user.id == id)
                          .firstOrNull;
                      if (match != null) {
                        setDialogState(() => selectedUser = match);
                      }
                    },
                  ),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha antiga dessa conta local',
                    ),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: consent,
                    onChanged: (value) =>
                        setDialogState(() => consent = value ?? false),
                    title: const Text(
                      'Sou responsavel e autorizo enviar o historico escolhido para este perfil.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  if (validationError != null)
                    Text(
                      validationError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Agora nao'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (!consent) {
                    setDialogState(
                      () => validationError =
                          'Marque a autorizacao para continuar.',
                    );
                    return;
                  }
                  if (!PasswordService.verifyPassword(
                    passwordController.text,
                    selectedUser.password,
                  )) {
                    setDialogState(
                      () => validationError = 'A senha local nao confere.',
                    );
                    return;
                  }
                  Navigator.of(dialogContext).pop((
                    user: selectedUser,
                    password: passwordController.text,
                  ));
                },
                child: const Text('Importar historico'),
              ),
            ],
          ),
        ),
      );
    } finally {
      passwordController.dispose();
    }
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Deseja realmente sair da conta do responsavel neste aparelho?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuar conectado'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair da conta'),
          ),
        ],
      ),
    );
    if (shouldSignOut != true) return;

    try {
      await BackendService.instance.client.auth.signOut();
      ProgressoService().setRemoteStudentScope(null);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AccessChoicePage()),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Nao foi possivel sair da conta. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmExitScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Acesso do responsavel')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Icon(Icons.family_restroom, size: 52, color: Colors.blue),
                const SizedBox(height: 12),
                Text(
                  _guardianRole != null
                      ? 'Ola${_guardianFullName == null || _guardianFullName!.isEmpty ? '' : ', $_guardianFullName'}!'
                      : _createAccount
                      ? 'Criar conta da familia'
                      : 'Entrar na conta da familia',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                if (_guardianRole == null) ..._buildAuthForm(),
                if (_guardianRole == 'guardian' || _guardianRole == 'admin')
                  ..._buildFamilyProfiles(),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
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

  List<Widget> _buildAuthForm() => [
    if (_createAccount)
      TextField(
        controller: _guardianNameController,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Nome do responsavel'),
      ),
    TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      decoration: const InputDecoration(labelText: 'E-mail do responsavel'),
    ),
    TextField(
      controller: _passwordController,
      obscureText: true,
      decoration: const InputDecoration(
        labelText: 'Senha (minimo 8 caracteres)',
      ),
      onSubmitted: (_) => _busy ? null : _authenticate(),
    ),
    const SizedBox(height: 16),
    ElevatedButton(
      onPressed: _busy ? null : _authenticate,
      child: Text(_createAccount ? 'Criar conta' : 'Entrar'),
    ),
    TextButton(
      onPressed: _busy
          ? null
          : () => setState(() {
              _createAccount = !_createAccount;
              _error = null;
            }),
      child: Text(
        _createAccount
            ? 'Ja tem conta? Entrar'
            : 'Novo por aqui? Criar conta do responsavel',
      ),
    ),
    const SizedBox(height: 10),
    const Text(
      'Para testar, use perfis sem informacoes identificaveis de criancas. '
      'A senha da conta fica no servico seguro de autenticacao; o app nao a guarda localmente.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12),
    ),
  ];

  List<Widget> _buildFamilyProfiles() => [
    if (_children.isNotEmpty) ...[
      const SizedBox(height: 12),
      const Text(
        'Escolha um perfil para estudar:',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      ..._children.map((child) {
        final active = child['status'] == 'active';
        return Card(
          child: ListTile(
            leading: const Icon(Icons.face),
            title: Text(
              (child['nickname'] as String?)?.trim().isNotEmpty == true
                  ? child['nickname'] as String
                  : child['full_name'] as String,
            ),
            subtitle: Text(
              active
                  ? '${child['grade']}'
                  : '${child['grade']} • Aguardando aprovacao da escola',
            ),
            trailing: active ? const Icon(Icons.arrow_forward) : null,
            enabled: active && !_busy,
            onTap: active ? () => _selectChild(child) : null,
          ),
        );
      }),
      const Divider(height: 28),
    ],
    if (_guardianRole == 'admin')
      OutlinedButton.icon(
        onPressed: _busy ? null : _openAdmin,
        icon: const Icon(Icons.admin_panel_settings),
        label: const Text('Abrir painel administrativo'),
      ),
    const Text(
      'Adicionar perfil de aluno',
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    TextField(
      controller: _childNameController,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(labelText: 'Nome do perfil'),
    ),
    TextField(
      controller: _childNicknameController,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(labelText: 'Apelido (opcional)'),
    ),
    TextField(
      controller: _childUsernameController,
      autocorrect: false,
      decoration: const InputDecoration(labelText: 'Usuario do perfil'),
    ),
    DropdownButtonFormField<String>(
      initialValue: _selectedGrade,
      decoration: const InputDecoration(labelText: 'Ano escolar'),
      items: _grades
          .map((grade) => DropdownMenuItem(value: grade, child: Text(grade)))
          .toList(),
      onChanged: _busy
          ? null
          : (grade) => setState(() => _selectedGrade = grade),
    ),
    CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: _consentAccepted,
      onChanged: _busy
          ? null
          : (value) => setState(() => _consentAccepted = value ?? false),
      title: const Text(
        'Sou responsavel e autorizo a criacao deste perfil para o teste.',
        style: TextStyle(fontSize: 13),
      ),
    ),
    ElevatedButton(
      onPressed: _busy ? null : _createChild,
      child: const Text('Salvar perfil'),
    ),
    TextButton(
      onPressed: _busy ? null : _signOut,
      child: const Text('Sair da conta'),
    ),
  ];
}
