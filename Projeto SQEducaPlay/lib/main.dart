import 'package:flutter/material.dart';
import 'home_page.dart';
import 'materias_page.dart';
import 'register_page.dart';
import 'pages/perfil_professor_page.dart';
import 'user_service.dart';
import 'user_model.dart';
import 'database/app_database.dart';
import 'services/progresso_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/logger.dart';
import 'utils/password_utils.dart';
import 'access_choice_page.dart';

class LoginPage extends StatefulWidget {
  final bool initialProfessor;

  const LoginPage({super.key, this.initialProfessor = true});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final _userService = UserService();

  bool _obscurePassword = true;
  bool _salvarSenha = false;

  // true = professor
  // false = aluno
  bool _modoProfessor = true;

  @override
  void initState() {
    super.initState();
    _modoProfessor = widget.initialProfessor;
    _carregarLoginSalvo();
  }

  String _canonicalGrade(String? grade) {
    final value = grade?.trim();

    if (value == null || value.isEmpty) {
      return '2º Ano Fundamental';
    }

    if (value.endsWith('Fundamental')) {
      return value;
    }

    return '$value Fundamental';
  }

  Future<void> _carregarLoginSalvo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final perfilSalvo =
          prefs.getString('perfil_login') ?? 'professor';

      final salvarSenha =
          prefs.getBool('salvar_senha_$perfilSalvo') ?? false;

      if (!salvarSenha) return;

      final username =
          prefs.getString('login_usuario_$perfilSalvo') ?? '';

      if (!mounted) return;

      setState(() {
        _modoProfessor = perfilSalvo == 'professor';
        _salvarSenha = true;
        _usernameController.text = username;
      });
    } catch (e) {
      Logger.d('Erro ao carregar login salvo: $e');
    }
  }

  Future<void> _salvarLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final perfil =
          _modoProfessor ? 'professor' : 'aluno';

      if (_salvarSenha) {
        await prefs.setBool(
          'salvar_senha_$perfil',
          true,
        );

        await prefs.setString(
          'login_usuario_$perfil',
          _usernameController.text.trim(),
        );

        await prefs.remove('login_senha_$perfil');

        await prefs.setString(
          'perfil_login',
          perfil,
        );
      } else {
        await prefs.setBool(
          'salvar_senha_$perfil',
          false,
        );

        await prefs.remove(
          'login_usuario_$perfil',
        );

        await prefs.remove(
          'login_senha_$perfil',
        );
      }
    } catch (e) {
      Logger.d('Erro ao salvar login: $e');
    }
  }

  Future<void> _trocarPerfil() async {
    setState(() {
      _modoProfessor = !_modoProfessor;
      _usernameController.clear();
      _passwordController.clear();
      _salvarSenha = false;
      _obscurePassword = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'perfil_login',
        _modoProfessor ? 'professor' : 'aluno',
      );

      await _carregarLoginSalvo();
    } catch (e) {
      Logger.d('Erro ao trocar perfil: $e');
    }
  }

  void _login() async {
    final username =
        _usernameController.text.trim();

    final password =
        _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Informe o usuário e a senha.',
          ),
        ),
      );

      return;
    }

    User? user =
        _userService.login(username, password);

    if (user == null) {
      try {
        final dbUser =
            await AppDatabase.instance
                .getUserByUsername(username);

        if (dbUser != null &&
            PasswordUtils.verifyPassword(password, dbUser.password)) {
          final memUser = User(
            username: dbUser.username,
            password: dbUser.password,
            fullName: dbUser.fullName,
            nickname: dbUser.nickname,
            grade: dbUser.grade,
            classGroup: dbUser.classGroup,
            schoolId: dbUser.schoolId,
            profilePhotoPath: dbUser.profilePhotoPath,
            role: dbUser.role,
            consentAt: dbUser.consentAt,
            consentVersion: dbUser.consentVersion,
            isApproved: dbUser.isApproved,
          );

          _userService.addUserFromDb(memUser);

          user = memUser;

          if (PasswordUtils.needsRehash(dbUser.password) &&
              dbUser.id != null) {
            await AppDatabase.instance.updateUser(
              dbUser.copy(
                password: PasswordUtils.hashPassword(password),
              ),
            );
          }
        }
      } catch (e) {
        Logger.d(
          'Erro ao buscar usuário no DB: $e',
        );
      }
    }

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Usuário ou senha inválidos!',
          ),
        ),
      );

      return;
    }

    final loggedUser =
        _normalizeLoggedUser(user);

    if (!_modoProfessor &&
        loggedUser.role == 'student' &&
        !loggedUser.isApproved) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cadastro aguardando aprovação de um professor.',
          ),
        ),
      );
      return;
    }

    // ==========================================
    // VERIFICAÇÃO DO PERFIL DO PROFESSOR
    // ==========================================
    if (_modoProfessor &&
        loggedUser.role != 'teacher') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta conta não possui acesso de professor.',
          ),
        ),
      );

      return;
    }

    // ==========================================
    // VERIFICAÇÃO DO PERFIL DO ALUNO
    // ==========================================
    if (!_modoProfessor &&
        loggedUser.role == 'teacher') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta é uma conta de professor. '
            'Troque o perfil para acessar.',
          ),
        ),
      );

      return;
    }

    await _salvarLogin();

    await _salvarSessaoDoUsuario(
      loggedUser,
    );

    _userService.addUserFromDb(
      loggedUser,
    );

    _userService.setCurrentUser(
      loggedUser,
    );

    await ProgressoService()
        .carregarDoBanco();

    if (!mounted) return;

    // ==========================================
    // PROFESSOR
    // ==========================================
    if (loggedUser.role == 'teacher') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              ProfessorDashboardPage(
            username: loggedUser.username,
          ),
        ),
      );

      return;
    }

    // ==========================================
    // ADMINISTRADOR
    // ==========================================
    if (loggedUser.role == 'admin') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
      );

      return;
    }

    // ==========================================
    // ALUNO
    // ==========================================
    final prefs =
        await SharedPreferences.getInstance();
    if (!mounted) return;

    final ano = _canonicalGrade(
      loggedUser.grade ??
          prefs.getString('usuario_grade'),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            MateriasPage(
          ano: ano,
          username: loggedUser.username,
        ),
      ),
    );
  }

  User _normalizeLoggedUser(User user) {
    final isTeacherKeinan =
        user.username.toLowerCase() == 'keinan';

    if (!isTeacherKeinan &&
        user.role != 'teacher') {
      return user;
    }

    return User(
      username: user.username,
      password: user.password,
      fullName:
          user.fullName.trim().isEmpty
              ? 'Professor Keinan'
              : user.fullName,
      nickname: user.nickname,
      grade: user.grade,
      classGroup: user.classGroup,
      schoolId: user.schoolId,
      profilePhotoPath: user.profilePhotoPath,
      role: 'teacher',
      consentAt: user.consentAt,
      consentVersion: user.consentVersion,
      isApproved: user.isApproved,
    );
  }

  Future<void> _salvarSessaoDoUsuario(
    User user,
  ) async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final dbUser =
          await AppDatabase.instance
              .getUserByUsername(
        user.username,
      );

      if (dbUser != null &&
          dbUser.id != null) {
        await prefs.setInt(
          'usuario_id',
          dbUser.id!,
        );

        await prefs.setString(
          'usuario_nome',
          dbUser.username,
        );

        if (dbUser.grade != null) {
          await prefs.setString(
            'usuario_grade',
            _canonicalGrade(dbUser.grade),
          );
        }
      } else {
        await prefs.setString(
          'usuario_nome',
          user.username,
        );

        if (user.grade != null) {
          await prefs.setString(
            'usuario_grade',
            _canonicalGrade(user.grade),
          );
        }
      }
    } catch (e) {
      Logger.d(
        'Erro ao salvar sessão do usuário: $e',
      );
    }
  }

  void _goToRegisterPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const RegisterPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double lineSpacing = 34.0;

    final titulo = _modoProfessor
        ? 'Acesso do Professor'
        : 'Acesso do Aluno';

    final subtitulo = _modoProfessor
        ? 'Painel de gerenciamento do professor'
        : 'Área de aprendizagem do aluno';

    return GestureDetector(
      onTap: () =>
          FocusScope.of(context).unfocus(),
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
                    constraints:
                        const BoxConstraints(
                      maxWidth: 340,
                    ),
                    child: Column(
                      children: [
                        Transform.translate(
                          offset:
                              const Offset(0, -5),
                          child: Image.asset(
                            'assets/images/mascoteTransparente.png',
                            height: 205,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Stack(
                          alignment:
                              Alignment.topCenter,
                          children: [
                            Image.asset(
                              'assets/images/caderno.png',
                              width: (MediaQuery.of(context)
                                      .size
                                      .width -
                                  20)
                                  .clamp(0.0, double.infinity),
                              fit: BoxFit.contain,
                            ),

                            Container(
                              width:
                                  ((MediaQuery.of(context)
                                        .size
                                        .width -
                                      58)
                                    .clamp(0.0, double.infinity)) *
                                    0.75,

                              // Aumentei um pouco o espaço interno
                              // para evitar cortes.
                              padding:
                                  const EdgeInsets.only(
                                left: 8,
                                right: 8,
                                top: 45,
                              ),

                              child: Column(
                                children: [
                                  // ======================================
                                  // TÍTULO
                                  // ======================================
                                  SizedBox(
                                    height:
                                        lineSpacing * 2.2,
                                    child: Center(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          horizontal: 4,
                                        ),
                                        child: Text(
                                          titulo,
                                          textAlign:
                                              TextAlign.center,
                                          maxLines: 2,
                                          overflow:
                                              TextOverflow.visible,
                                          style: TextStyle(
                                            color:
                                                Colors.blue.shade900,
                                            fontSize: 21,
                                            fontWeight:
                                                FontWeight.w900,
                                            fontFamily:
                                                'Comic Sans MS',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // ======================================
                                  // SUBTÍTULO
                                  // ======================================
                                  SizedBox(
                                    height:
                                        lineSpacing,
                                    child: Center(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets
                                                .only(
                                          top: 7,
                                        ),
                                        child: Text(
                                          subtitulo,
                                          textAlign:
                                              TextAlign.center,
                                          maxLines: 2,
                                          overflow:
                                              TextOverflow.visible,
                                          style:
                                              const TextStyle(
                                            color:
                                                Colors.orange,
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 10,
                                  ),

                                  // ======================================
                                  // USUÁRIO
                                  // ======================================
                                  SizedBox(
                                    height:
                                        lineSpacing,
                                    child:
                                        _buildTextField(
                                      controller:
                                          _usernameController,
                                      hintText:
                                          'Nome de Usuário',
                                      icon:
                                          Icons.person,
                                    ),
                                  ),

                                  // ======================================
                                  // SENHA
                                  // ======================================
                                  SizedBox(
                                    height:
                                        lineSpacing,
                                    child:
                                        _buildTextField(
                                      controller:
                                          _passwordController,
                                      hintText:
                                          'Senha',
                                      icon:
                                          Icons.lock,
                                      isPassword:
                                          true,
                                      obscureText:
                                          _obscurePassword,
                                      onToggleVisibility:
                                          () {
                                        setState(() {
                                          _obscurePassword =
                                              !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),

                                  // ======================================
                                  // SALVAR SENHA
                                  // ======================================
                                  SizedBox(
                                    height:
                                        lineSpacing,
                                    child:
                                        CheckboxListTile(
                                      contentPadding:
                                          EdgeInsets.zero,
                                      dense: true,
                                      visualDensity:
                                          const VisualDensity(
                                        horizontal: -4,
                                        vertical: -4,
                                      ),
                                      value:
                                          _salvarSenha,
                                      onChanged:
                                          (value) {
                                        setState(() {
                                          _salvarSenha =
                                              value ??
                                                  false;
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity
                                              .leading,
                                      title:
                                          const Text(
                                        'Salvar senha',
                                        style:
                                            TextStyle(
                                          color:
                                              Colors.blue,
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // ======================================
                                  // ENTRAR
                                  // ======================================
                                  SizedBox(
                                    height:
                                        lineSpacing,
                                    child:
                                        ElevatedButton(
                                      onPressed:
                                          _login,
                                      style:
                                          ElevatedButton
                                              .styleFrom(
                                        backgroundColor:
                                            Colors.blue,
                                        foregroundColor:
                                            Colors.white,
                                        padding:
                                            EdgeInsets.zero,
                                        minimumSize:
                                            const Size(
                                          double.infinity,
                                          34,
                                        ),
                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child:
                                          const Text(
                                        'Entrar',
                                        style:
                                            TextStyle(
                                          fontSize: 15,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 5,
                                  ),

                                  // ======================================
                                  // PRIMEIRO ACESSO DO PROFESSOR
                                  // ======================================
                                  if (_modoProfessor)
                                    const Padding(
                                      padding:
                                          EdgeInsets
                                              .symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        'Configure a conta do professor '
                                        'antes do primeiro login.',
                                        textAlign:
                                            TextAlign.center,
                                        maxLines: 2,
                                        overflow:
                                            TextOverflow.visible,
                                        style:
                                            TextStyle(
                                          color:
                                              Colors.blue,
                                          fontSize: 10,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                  const SizedBox(
                                    height: 2,
                                  ),

                                  // ======================================
                                  // TEXTO TROCAR PERFIL
                                  // ======================================
                                  TextButton(
                                    onPressed:
                                        _trocarPerfil,
                                    style:
                                        TextButton.styleFrom(
                                      foregroundColor:
                                          Colors.blue.shade900,
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      minimumSize:
                                          const Size(
                                        0,
                                        28,
                                      ),
                                      tapTargetSize:
                                          MaterialTapTargetSize
                                              .shrinkWrap,
                                    ),
                                    child:
                                        Text(
                                      _modoProfessor
                                          ? 'Aluno? Troque o perfil.'
                                          : 'Professor? Troque o perfil.',
                                      textAlign:
                                          TextAlign.center,
                                      style:
                                          const TextStyle(
                                        fontSize: 12,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  // ======================================
                                  // BOTÃO TROCAR PERFIL
                                  // ======================================
                                  OutlinedButton(
                                    onPressed:
                                        _trocarPerfil,
                                    style:
                                        OutlinedButton.styleFrom(
                                      foregroundColor:
                                          Colors.blue,
                                      minimumSize:
                                          const Size(
                                        0,
                                        34,
                                      ),
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 18,
                                        vertical: 4,
                                      ),
                                      side:
                                          const BorderSide(
                                        color:
                                            Colors.blue,
                                      ),
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          10,
                                        ),
                                      ),
                                    ),
                                    child:
                                        const Text(
                                      'Trocar perfil',
                                      style:
                                          TextStyle(
                                        fontSize: 12,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 2,
                                  ),

                                  // ======================================
                                  // CADASTRO DO ALUNO
                                  // ======================================
                                  if (!_modoProfessor)
                                    TextButton(
                                      onPressed:
                                          _goToRegisterPage,
                                      style:
                                          TextButton.styleFrom(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          vertical: 2,
                                        ),
                                      ),
                                      child:
                                          const Text(
                                        'Cadastrar novo usuário',
                                        style:
                                            TextStyle(
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                  const SizedBox(
                                    height: 15,
                                  ),
                                ],
                              ),
                            ),
                          ],
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
      margin:
          const EdgeInsets.symmetric(
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius:
            BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        obscureText:
            isPassword
                ? obscureText
                : false,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle:
              const TextStyle(
            color: Colors.blue,
            fontSize: 15,
            fontWeight:
                FontWeight.bold,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.blue,
            size: 16,
          ),
          suffixIcon:
              isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color:
                            Colors.blue,
                        size: 16,
                      ),
                      onPressed:
                          onToggleVisibility,
                      padding:
                          EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(),
                    )
                  : null,
          border:
              InputBorder.none,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
        ),
      ),
    );
  }
}
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AccessChoicePage(),
    ),
  );
}