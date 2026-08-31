/// Convite de uso único que autoriza a criação de UMA conta de educador.
///
/// Existe para fechar o P0-03 da auditoria: antes, qualquer pessoa que
/// abrisse o aplicativo pela primeira vez em um aparelho podia se
/// autocadastrar como educador e escolher escola/turmas livremente. Agora a
/// criação da conta exige um código emitido previamente por um
/// administrador (ou pela escola), vinculado a UMA escola específica, e o
/// código é consumido (marcado como usado) no momento em que a conta é
/// criada.
class TeacherInvite {
  final int? id;
  final String code;
  final String schoolId;
  final String? createdByUsername;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final int? usedByUserId;

  const TeacherInvite({
    this.id,
    required this.code,
    required this.schoolId,
    this.createdByUsername,
    required this.createdAt,
    required this.expiresAt,
    this.usedAt,
    this.usedByUserId,
  });

  TeacherInvite copyWith({
    int? id,
    String? code,
    String? schoolId,
    String? createdByUsername,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? usedAt,
    int? usedByUserId,
  }) {
    return TeacherInvite(
      id: id ?? this.id,
      code: code ?? this.code,
      schoolId: schoolId ?? this.schoolId,
      createdByUsername: createdByUsername ?? this.createdByUsername,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt ?? this.usedAt,
      usedByUserId: usedByUserId ?? this.usedByUserId,
    );
  }

  bool get isUsed => usedAt != null;

  bool isExpiredAt(DateTime now) => now.isAfter(expiresAt);

  /// Verdadeiro somente quando o convite pode ser consumido agora:
  /// nunca usado e ainda dentro da validade.
  bool isValidAt(DateTime now) => !isUsed && !isExpiredAt(now);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'schoolId': schoolId,
      'createdByUsername': createdByUsername,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'usedAt': usedAt?.toIso8601String(),
      'usedByUserId': usedByUserId,
    };
  }

  factory TeacherInvite.fromMap(Map<String, dynamic> map) {
    return TeacherInvite(
      id: map['id'] as int?,
      code: map['code'] as String,
      schoolId: map['schoolId'] as String,
      createdByUsername: map['createdByUsername'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      expiresAt: DateTime.parse(map['expiresAt'] as String),
      usedAt: map['usedAt'] != null ? DateTime.tryParse(map['usedAt'] as String) : null,
      usedByUserId: map['usedByUserId'] as int?,
    );
  }
}
