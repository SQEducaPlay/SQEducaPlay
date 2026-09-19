class TeacherInvite {
  final int? id;
  final String code;
  final String schoolId;
  final String? createdByUsername;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isUsed;
  final int? usedByUserId;

  const TeacherInvite({
    this.id,
    required this.code,
    required this.schoolId,
    this.createdByUsername,
    required this.createdAt,
    required this.expiresAt,
    this.isUsed = false,
    this.usedByUserId,
  });

  bool get isExpired => !expiresAt.isAfter(DateTime.now());

  factory TeacherInvite.fromMap(Map<String, dynamic> map) {
    return TeacherInvite(
      id: map['id'] as int?,
      code: map['code'] as String,
      schoolId: map['schoolId'] as String,
      createdByUsername: map['createdByUsername'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      expiresAt: DateTime.parse(map['expiresAt'] as String),
      isUsed: (map['isUsed'] as int? ?? 0) == 1,
      usedByUserId: map['usedByUserId'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'code': code,
        'schoolId': schoolId,
        'createdByUsername': createdByUsername,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'isUsed': isUsed ? 1 : 0,
        'usedByUserId': usedByUserId,
      };

  TeacherInvite copyWith({
    int? id,
    bool? isUsed,
    int? usedByUserId,
  }) {
    return TeacherInvite(
      id: id ?? this.id,
      code: code,
      schoolId: schoolId,
      createdByUsername: createdByUsername,
      createdAt: createdAt,
      expiresAt: expiresAt,
      isUsed: isUsed ?? this.isUsed,
      usedByUserId: usedByUserId ?? this.usedByUserId,
    );
  }
}
