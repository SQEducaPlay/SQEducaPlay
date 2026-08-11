class User {
  final String username;
  final String password;
  final String fullName; // Nome completo do usuário
  final String? nickname; // Apelido público (opcional)
  final String? grade; // Opcional, pois o admin não tem uma série
  final String? classGroup; // Turma (ex.: 5ºA)
  final String? schoolId; // ID da escola onde o aluno estuda
  final String? profilePhotoPath; // Caminho para foto de perfil (opcional)
  final String role; // 'admin' ou 'student'

  User({
    required this.username,
    required this.password,
    required this.fullName,
    this.nickname,
    this.grade,
    this.classGroup,
    this.schoolId,
    this.profilePhotoPath,
    this.role = 'student', // Por padrão, usuários são estudantes
  });
}