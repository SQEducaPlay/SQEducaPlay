class User {
  final int? id;
  final String username;
  final String password;
  final String fullName;
  final String? nickname;
  final String? grade;
  final String? classGroup;
  final String? schoolId;
  final String role;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final int? pontuacaoTotal;
  final int? estrelasTotal;
  final String? profilePhotoPath;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.fullName,
    this.nickname,
    this.grade,
    this.classGroup,
    this.schoolId,
    required this.role,
    this.createdAt,
    this.lastLogin,
    this.pontuacaoTotal,
    this.estrelasTotal,
    this.profilePhotoPath,
  });

  User copy({
    int? id,
    String? username,
    String? password,
    String? fullName,
    String? nickname,
    String? grade,
    String? classGroup,
    String? schoolId,
    String? role,
    DateTime? createdAt,
    DateTime? lastLogin,
    int? pontuacaoTotal,
    int? estrelasTotal,
    String? profilePhotoPath,
  }) =>
      User(
        id: id ?? this.id,
        username: username ?? this.username,
        password: password ?? this.password,
        fullName: fullName ?? this.fullName,
        nickname: nickname ?? this.nickname,
        grade: grade ?? this.grade,
        classGroup: classGroup ?? this.classGroup,
        schoolId: schoolId ?? this.schoolId,
        role: role ?? this.role,
        createdAt: createdAt ?? this.createdAt,
        lastLogin: lastLogin ?? this.lastLogin,
        pontuacaoTotal: pontuacaoTotal ?? this.pontuacaoTotal,
        estrelasTotal: estrelasTotal ?? this.estrelasTotal,
        profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'fullName': fullName,
      'nickname': nickname,
      'grade': grade,
      'classGroup': classGroup,
      'schoolId': schoolId,
      'role': role,
      'createdAt': createdAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'pontuacao_total': pontuacaoTotal ?? 0,
      'estrelas_total': estrelasTotal ?? 0,
      'profilePhotoPath': profilePhotoPath,
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      password: map['password'] as String,
      fullName: map['fullName'] as String,
      nickname: map['nickname'] as String?,
      grade: map['grade'] as String?,
      classGroup: map['classGroup'] as String?,
      schoolId: map['schoolId'] as String?,
      role: map['role'] as String,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      lastLogin: map['lastLogin'] != null ? DateTime.parse(map['lastLogin'] as String) : null,
      pontuacaoTotal: (map['pontuacao_total'] is int) ? map['pontuacao_total'] as int : ((map['pontuacao_total'] is String) ? int.tryParse(map['pontuacao_total'] as String) : 0),
      estrelasTotal: (map['estrelas_total'] is int) ? map['estrelas_total'] as int : ((map['estrelas_total'] is String) ? int.tryParse(map['estrelas_total'] as String) : 0),
      profilePhotoPath: map['profilePhotoPath'] as String?,
    );
  }
}