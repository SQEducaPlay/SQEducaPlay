// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'materias_page.dart';
import 'register_page.dart';
import 'pages/access_choice_page.dart';
import 'pages/perfil_professor_page.dart';
import 'pages/teacher_setup_page.dart';
import 'models/user_model.dart';
import 'services/user_service.dart';
import 'services/password_service.dart';
import 'database/app_database.dart';
import 'package:sqeducaplay/models/user_model.dart' as db_model;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'utils/logger.dart';
import 'widgets/confirm_exit_scope.dart';

enum LoginAudience { student, teacher }

class LoginPage extends StatefulWidget {
  final LoginAudience audience;

  const LoginPage({super.key, required this.audience});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userService = UserService();
  final _secureStorage = const FlutterSecureStorage();
  bool _obscurePassword = true;
  bool _saveCredentials = true;

  String get _credentialSuffix => widget.audience.name;
  String get _savedUsernameKey => 'saved_username_$_credentialSuffix';

  @override
  void initState() {
    super.initState();
    _carregarCredenciaisSalvas();
  }

  Future<void> _carregarCredenciaisSalvas() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final savedUsername = prefs.getString(_savedUsernameKey);
    String? savedPassword;
    try {
      savedPassword = await _secureStorage.read(
        key: 'saved_password_$_credentialSuffix',
      );
    } catch (e) {
      Logger.d('Não foi possível carregar a senha salva: $e');
    }

    if (savedUsername != null && savedUsername.isNotEmpty) {
      _usernameController.text = savedUsername;
    }
    if (savedPassword != null && savedPassword.isNotEmpty) {
      _passwordController.text = savedPassword;
    } else {
      _saveCredentials = false;
    }
    setState(() {});
  }

  Future<void> _persistirCredenciais() async {
    final prefs = await SharedPreferences.getInstance();

    if (_saveCredentials) {
      await prefs.setString(_savedUsernameKey, _usernameController.text.trim());
      try {
        await _secureStorage.write(
          key: 'saved_password_$_credentialSuffix',
          value: _passwordController.text,
        );
      } catch (e) {
        Logger.d('Não foi possível salvar a senha com segurança: $e');
      }
    } else {
      await prefs.remove(_savedUsernameKey);
      try {
        await _secureStorage.delete(key: 'saved_password_$_credentialSuffix');
      } catch (e) {
        Logger.d('Não foi possível remover a senha salva: $e');
      }
    }
  }

  void _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite seu usuário para continuar.')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite sua senha para continuar.')),
      );
      return;
    }

    // O banco é a fonte atualizada da verdade. Isso evita que uma cópia em
    // memória mantenha um aluno como pendente depois da aprovação.
    User? user;
    try {
      final dbUser = await AppDatabase.instance.getUserByUsername(username);
      if (dbUser != null &&
          PasswordService.verifyPassword(password, dbUser.password)) {
        _userService.addUserFromDb(dbUser);
        user = dbUser;
        Logger.d('Usuário recuperado do banco de dados: ${dbUser.fullName}');
      }
    } catch (e) {
      Logger.d('Erro ao buscar usuário no DB: $e');
    }

    // Mantém suporte aos usuários de memória usados no modo web e nos testes.
    user ??= _userService.login(username, password);

    if (user != null) {
      final loggedUser = user; // Cria variável local para null-safety

      if (widget.audience == LoginAudience.teacher &&
          loggedUser.role != 'teacher') {
        _userService.clearCurrentUser();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Use uma conta de educador para este acesso.'),
          ),
        );
        return;
      }

      if (widget.audience == LoginAudience.student &&
          loggedUser.role == 'teacher') {
        _userService.clearCurrentUser();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Use o acesso de educador para esta conta.'),
          ),
        );
        return;
      }

      if (loggedUser.role == 'student' && !loggedUser.isApproved) {
        _userService.clearCurrentUser();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cadastro aguardando aprovação do educador da turma.',
            ),
          ),
        );
        return;
      }

      if (loggedUser.role == 'student' && !loggedUser.isApproved) {
        _userService.clearCurrentUser();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cadastro aguardando aprovação do educador da turma.',
            ),
          ),
        );
        return;
      }

      // Persistir a sessao local somente depois de validar o tipo de acesso.
      await _criarOuBuscarUsuarioNoBanco(
        loggedUser.username,
        password,
        loggedUser.role,
        loggedUser.grade,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_login_audience', widget.audience.name);
      await _persistirCredenciais();

      if (!mounted) return;

      if (loggedUser.role == 'admin') {
        Navigator.of(
          context,
        ).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ConfirmExitScope(child: HomePage()),
          ),
        );
      } else if (loggedUser.role == 'teacher') {
        // Correção P0-04: educadores devem cair no painel do educador,
        // nunca na área de matérias do aluno.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ConfirmExitScope(
              child: ProfessorDashboardPage(username: loggedUser.username),
            ),
          ),
        );
      } else {
        // Para alunos, tentar a série salva e usar 2º Ano como padrão.
        final prefs = await SharedPreferences.getInstance();
        final ano =
            loggedUser.grade ??
            prefs.getString('usuario_grade') ??
            '2º Ano Fundamental';
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                ConfirmExitScope(child: MateriasPage(ano: ano)),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário ou senha inválidos!')),
      );
    }
  }

  Future<void> _criarOuBuscarUsuarioNoBanco(
    String nome,
    String password,
    String? role, [
    String? grade,
  ]) async {
    try {
      // Usamos AppDatabase que trabalha com o modelo User
      final dbUser = await AppDatabase.instance.getUserByUsername(nome);
      final prefs = await SharedPreferences.getInstance();

      if (dbUser == null) {
        // Criar novo usuário no DB
        final created = await AppDatabase.instance.createUser(
          db_model.User(
            username: nome,
            password: password,
            fullName: nome,
            role: role ?? 'student',
            grade: grade,
          ),
        );
        await prefs.setInt('usuario_id', created.id!);
        await prefs.setString('usuario_nome', created.username);
        if (created.grade != null)
          await prefs.setString('usuario_grade', created.grade!);

        Logger.d(
          'Novo usuário criado no DB: ${created.username} (ID: ${created.id})',
        );
      } else {
        await prefs.setInt('usuario_id', dbUser.id!);
        await prefs.setString('usuario_nome', dbUser.username);
        if (grade != null) await prefs.setString('usuario_grade', grade);

        Logger.d(
          'Usuário existente encontrado no DB: ${dbUser.username} (ID: ${dbUser.id})',
        );
      }
    } catch (e) {
      Logger.d('Erro ao criar/buscar usuário no banco: $e');
    }
  }

  void _goToRegisterPage() {
    if (widget.audience == LoginAudience.teacher) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const TeacherSetupPage()));
    } else {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const RegisterPage()));
    }
  }

  void _switchProfile() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            const AccessChoicePage(skipRememberedAudience: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const lineSpacing = 34.0;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/fundo_azul.jpg',
                fit: BoxFit.cover,
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/mascoteTransparente.png',
                          height: 205,
                        ),
                        const SizedBox(height: 5),
                        Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            Image.asset(
                              'assets/images/caderno.png',
                              width: MediaQuery.of(context).size.width - 20,
                            ),
                            Container(
                              width:
                                  (MediaQuery.of(context).size.width - 58) *
                                  0.75,
                              padding: const EdgeInsets.only(
                                left: 10,
                                right: 10,
                                top: 50,
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: lineSpacing * 2.2,
                                    child: Center(
                                      child: Transform.translate(
                                        offset: const Offset(0, 5),
                                        child: Text(
                                          widget.audience ==
                                                  LoginAudience.teacher
                                              ? 'Acesso do Educador!'
                                              : 'Acesso do Aluno!',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.blue.shade900,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            fontFamily: 'Comic Sans MS',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: lineSpacing,
                                    child: const Center(
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 13),
                                        child: Text(
                                          'Aprender é divertido!',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  SizedBox(
                                    height: lineSpacing,
                                    child: _buildTextField(
                                      controller: _usernameController,
                                      hintText: 'Nome de Usuário',
                                      icon: Icons.person,
                                    ),
                                  ),
                                  SizedBox(
                                    height: lineSpacing,
                                    child: _buildTextField(
                                      controller: _passwordController,
                                      hintText: 'Senha Secreta',
                                      icon: Icons.lock,
                                      isPassword: true,
                                      obscureText: _obscurePassword,
                                      onToggleVisibility: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: lineSpacing,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: _saveCredentials,
                                            onChanged: (value) => setState(
                                              () => _saveCredentials =
                                                  value ?? false,
                                            ),
                                            activeColor: Colors.blue,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          const Text(
                                            'Salvar acesso',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: lineSpacing,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Entrar',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: lineSpacing,
                                    child: TextButton(
                                      onPressed: _goToRegisterPage,
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.blue.shade900,
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Text(
                                        widget.audience == LoginAudience.teacher
                                            ? 'Primeiro acesso do educador'
                                            : 'Cadastrar novo usuário',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: lineSpacing),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        TextButton.icon(
                          onPressed: _switchProfile,
                          icon: const Icon(
                            Icons.swap_horiz,
                            color: Colors.blueGrey,
                          ),
                          label: const Text(
                            'Trocar perfil',
                            style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: TextField(
        controller: controller,
        obscureText: isPassword && obscureText,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Colors.blue,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          prefixIcon: Icon(icon, color: Colors.blue, size: 16),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Colors.blue,
                    size: 16,
                  ),
                  onPressed: onToggleVisibility,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              : null,
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
        ),
      ),
    );
  }
}
