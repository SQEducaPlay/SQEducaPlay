class ClassGroup {
  final String id;
  final String name; // ex.: 5ºA
  final String schoolId;
  final String grade; // ex.: 5º Ano

  ClassGroup({
    required this.id,
    required this.name,
    required this.schoolId,
    required this.grade,
  });
}

class ClassGroupService {
  static final ClassGroupService _instance = ClassGroupService._internal();
  factory ClassGroupService() => _instance;
  ClassGroupService._internal();

  final List<ClassGroup> _groups = [];

  List<ClassGroup> getAll() => List.unmodifiable(_groups);

  List<ClassGroup> getBySchoolAndGrade(String schoolId, String grade) {
    return _groups.where((g) => g.schoolId == schoolId && g.grade == grade).toList();
  }

  void add(ClassGroup group) {
    // Evita duplicar nome dentro da mesma escola/série
    final exists = _groups.any((g) => g.schoolId == group.schoolId && g.grade == group.grade && g.name.toLowerCase() == group.name.toLowerCase());
    if (!exists) _groups.add(group);
  }

  void remove(String id) {
    _groups.removeWhere((g) => g.id == id);
  }
}
