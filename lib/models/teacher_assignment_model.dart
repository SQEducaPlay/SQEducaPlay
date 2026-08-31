class TeacherAssignment {
  final int? id;
  final int teacherId;
  final String schoolId;
  final String grade;
  final String classGroup;
  final String shift;
  final String? schedule;

  const TeacherAssignment({
    this.id,
    required this.teacherId,
    required this.schoolId,
    required this.grade,
    required this.classGroup,
    required this.shift,
    this.schedule,
  });

  TeacherAssignment copyWith({
    int? id,
    int? teacherId,
    String? schoolId,
    String? grade,
    String? classGroup,
    String? shift,
    String? schedule,
  }) {
    return TeacherAssignment(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      schoolId: schoolId ?? this.schoolId,
      grade: grade ?? this.grade,
      classGroup: classGroup ?? this.classGroup,
      shift: shift ?? this.shift,
      schedule: schedule ?? this.schedule,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teacherId': teacherId,
      'schoolId': schoolId,
      'grade': grade,
      'classGroup': classGroup,
      'shift': shift,
      'schedule': schedule,
    };
  }

  factory TeacherAssignment.fromMap(Map<String, dynamic> map) {
    return TeacherAssignment(
      id: map['id'] as int?,
      teacherId: map['teacherId'] as int,
      schoolId: map['schoolId'] as String,
      grade: map['grade'] as String,
      classGroup: map['classGroup'] as String,
      shift: map['shift'] as String,
      schedule: map['schedule'] as String?,
    );
  }
}
