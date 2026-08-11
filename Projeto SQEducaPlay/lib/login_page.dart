// ignore_for_file: use_build_context_synchronously
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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userService = UserService();
  bool _obscurePassword = true;

  String _canonicalGrade(String? grade) {
    final value = grade?.trim();
    if (value == null || value.isEmpty) return '2º Ano Fundamental';
    if (value.endsWith('Fundamental')) return value;
    return '$value Fundamental';
  }

  void _login() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    User? user = _userService.login(username, password);

    if (user == null) {
      try {
        final dbUser = await AppDatabase.instance.getUserByUsername(username);
        if (dbUser != null && dbUser.password == password) {
          final memUser = User(
            username: dbUser.username,
            password: dbUser.password,
            fullName: dbUser.fullName,
            nickname: dbUser.nickname,
            grade: dbUser.grade,
            classGroup: dbUser.classGroup,
            schoolId: dbUser.schoolId,
            role: dbUser.role,
          );
          _userService.addUserFromDb(memUser);
          user = memUser;
        }
      } catch (e) {
        Logger.d('Erro ao buscar usuário no DB: $e');
      }
    }

    if (user != null) {
      final loggedUser = _normalizeLoggedUser(user);
      await _salvarSessaoDoUsuario(loggedUser);
      _userService.addUserFromDb(loggedUser);
      _userService.setCurrentUser(loggedUser);
      await ProgressoService().carregarDoBanco();

      if (!mounted) return;

      if (loggedUser.role == 'teacher') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ProfessorDashboardPage(username: loggedUser.username),
          ),
        );
      } else if (loggedUser.role == 'admin') {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomePage()));
      } else {
        final prefs = await SharedPreferences.getInstance();
        final ano = _canonicalGrade(loggedUser.grade ?? prefs.getString('usuario_grade'));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MateriasPage(ano: ano, username: loggedUser.username),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário ou senha inválidos!')),
      );
    }
  }

  User _normalizeLoggedUser(User user) {
    final isTeacherKeinan = user.username.toLowerCase() == 'keinan';
    if (!isTeacherKeinan && user.role != 'teacher') return user;

    return User(
      username: user.username,
      password: user.password,
      fullName: user.fullName.trim().isEmpty ? 'Professor Keinan' : user.fullName,
      nickname: user.nickname,
      grade: user.grade,
      classGroup: user.classGroup,
      schoolId: user.schoolId,
      profilePhotoPath: user.profilePhotoPath,
      role: 'teacher',
    );
  }

  Future<void> _salvarSessaoDoUsuario(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dbUser = await AppDatabase.instance.getUserByUsername(user.username);

      if (dbUser != null && dbUser.id != null) {
        await prefs.setInt('usuario_id', dbUser.id!);
        await prefs.setString('usuario_nome', dbUser.username);
        if (dbUser.grade != null) {
          await prefs.setString('usuario_grade', _canonicalGrade(dbUser.grade));
        }
      } else {
        await prefs.setString('usuario_nome', user.username);
        if (user.grade != null) {
          await prefs.setString('usuario_grade', _canonicalGrade(user.grade));
        }
      }
    } catch (e) {
      Logger.d('Erro ao salvar sessão do usuário: $e');
    }
  }

  void _goToRegisterPage() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegisterPage()));
  }

  @override
  Widget build(BuildContext context) {
    const double lineSpacing = 34.0;

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
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -5),
                          child: Image.asset(
                            'assets/images/mascoteTransparente.png',
                            height: 205,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            Image.asset(
                              'assets/images/caderno.png',
                              width: MediaQuery.of(context).size.width - 20,
                              fit: BoxFit.contain,
                            ),
                            Container(
                              width: (MediaQuery.of(context).size.width - 58) * 0.75,
                              padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 48.0),
                              child: Column(
                                children: [
                                  // LINHA 1 e 2: Título
                                  SizedBox(
                                    height: lineSpacing * 2.2,
                                    child: Center(
                                      child: Text(
                                        'Bem-vindo ao SQEducaPlay',
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
                                  // LINHA 3: Subtítulo
                                  SizedBox(
                                    height: lineSpacing,
                                    child: const Center(
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 13.0),
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
                                  // LINHA 4: Nome de Usuário (Subiu para cá!)
                                  SizedBox(
                                    height: lineSpacing,
                                    child: _buildTextField(
                                      controller: _usernameController,
                                      hintText: 'Nome de Usuário',
                                      icon: Icons.person,
                                    ),
                                  ),
                                  // LINHA 5: Senha Secreta (Subiu para cá!)
                                  SizedBox(
                                    height: lineSpacing,
                                    child: _buildTextField(
                                      controller: _passwordController,
                                      hintText: 'Senha Secreta',
                                      icon: Icons.lock,
                                      isPassword: true,
                                      obscureText: _obscurePassword,
                                      onToggleVisibility: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  // LINHA 6: Botão Entrar (Subiu para cá!)
                                  SizedBox(
                                    height: lineSpacing,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                                      child: ElevatedButton(
                                        onPressed: _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: const Text(
                                          'Entrar',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // LINHA 7: Botão Cadastrar (Subiu para cá!)
                                  SizedBox(
                                    height: lineSpacing,
                                    child: TextButton(
                                      onPressed: _goToRegisterPage,
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.blue.shade900,
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Text(
                                        'Cadastrar novo usuário',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  // LINHA 8: Espaço livre no final
                                  const SizedBox(height: lineSpacing),
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
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscureText : false,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.blue, fontSize: 15, fontWeight: FontWeight.bold),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
    );
  }
}
