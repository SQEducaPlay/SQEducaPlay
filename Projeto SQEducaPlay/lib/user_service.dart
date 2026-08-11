import 'user_model.dart';

class UserService {
  // Usando um Singleton para manter os dados em memória durante a execução do app.
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal() {
    _initializeAdmin();
  }

  final List<User> _users = [];
  String? _currentUsername;

  // Inicializa com um usuário administrador padrão
  void _initializeAdmin() {
    _users.add(User(
      username: 'Keinan',
      password: 'keinan',
      fullName: 'Professor Keinan',
      role: 'teacher',
    ));
  }

  // Método para adicionar usuário administrador de forma segura
  void addAdminUser(String username, String password, {String? fullName}) {
    final normalized = normalizeUsername(username);
    _users.add(User(
      username: normalized,
      password: password,
      fullName: fullName ?? normalized,
      role: 'admin',
    ));
  }

  // Tenta fazer o login e retorna o usuário se for bem-sucedido
  User? login(String username, String password) {
    try {
      return _users.firstWhere(
        (user) => user.username == username && user.password == password,
      );
    } catch (e) {
      return null; // Retorna nulo se o usuário não for encontrado
    }
  }

  // Cadastra um novo usuário com validações básicas
  void register(User newUser) {
    final normalized = normalizeUsername(newUser.username);

    final validationError = validateUsername(normalized);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    // Impede cadastro de estudante sem escola informada
    if (newUser.role == 'student' && (newUser.schoolId == null || newUser.schoolId!.isEmpty)) {
      throw ArgumentError('Para criar conta de aluno, selecione a escola.');
    }

    // Valida nome completo
    if (newUser.fullName.trim().isEmpty) {
      throw ArgumentError('Informe seu nome completo.');
    }

    // Impede cadastro de usernames duplicados (case-insensitive)
    final exists = _users.any((u) => u.username.toLowerCase() == normalized.toLowerCase());
    if (exists) {
      throw ArgumentError('Este nome de usuário já está em uso.');
    }

    _users.add(User(
      username: normalized,
      password: newUser.password,
      fullName: newUser.fullName.trim(),
      nickname: newUser.nickname,
      profilePhotoPath: newUser.profilePhotoPath,
      grade: newUser.grade,
      classGroup: newUser.classGroup,
      schoolId: newUser.schoolId,
      role: newUser.role,
    ));

    _currentUsername = normalized;
  }

  // Recupera um usuário pelo username
  User? getUserByUsername(String username) {
    try {
      return _users.firstWhere((user) => user.username == username);
    } catch (e) {
      return null;
    }
  }

  // Adiciona/atualiza um usuário proveniente do banco de dados à sessão em memória
  // Sem aplicar validações rígidas de registro (útil para sincronizar sessão após login)
  void addUserFromDb(User user) {
    final normalized = normalizeUsername(user.username);
    final idx = _users.indexWhere((u) => u.username.toLowerCase() == normalized.toLowerCase());
    final newUser = User(
      username: normalized,
      password: user.password,
      fullName: user.fullName,
      nickname: user.nickname,
      profilePhotoPath: user.profilePhotoPath,
      grade: user.grade,
      classGroup: user.classGroup,
      schoolId: user.schoolId,
      role: user.role,
    );
    if (idx >= 0) {
      _users[idx] = newUser;
    } else {
      _users.add(newUser);
    }

    _currentUsername = normalized;
  }

  User? get currentUser {
    if (_currentUsername == null) return null;
    return getUserByUsername(_currentUsername!);
  }

  void setCurrentUser(User user) {
    _currentUsername = normalizeUsername(user.username);
  }

  void clearCurrentUser() {
    _currentUsername = null;
  }

  // Retorna uma cópia imutável da lista de usuários (se necessário para agregações)
  List<User> getAllUsers() => List.unmodifiable(_users);

  // Verifica se existe um username (case-insensitive)
  bool existsUsername(String username) {
    final normalized = normalizeUsername(username);
    return _users.any((u) => u.username.toLowerCase() == normalized.toLowerCase());
  }

  // Normaliza username (trim e colapsa espaços, converte espaços para underscore)
  String normalizeUsername(String value) {
    final trimmed = value.trim();
    // Troca sequências de espaço por underscore
    final noSpaces = trimmed.replaceAll(RegExp(r"\s+"), '_');
    return noSpaces;
  }

  // Valida username e retorna mensagem de erro ou null se válido
  String? validateUsername(String value) {
    if (value.isEmpty) return 'Por favor, insira um nome.';
    if (value.length < 3 || value.length > 20) {
      return 'O nome deve ter entre 3 e 20 caracteres.';
    }
    final regex = RegExp(r'^[a-zA-Z0-9._-]+$');
    if (!regex.hasMatch(value)) {
      return 'Use apenas letras, números e . _ - (sem espaços).';
    }
    return null;
  }
}