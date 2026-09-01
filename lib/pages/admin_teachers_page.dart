import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/user_model.dart';
import '../school_service.dart';
import '../widgets/app_bar.dart';

class AdminTeachersPage extends StatefulWidget {
  const AdminTeachersPage({super.key});

  @override
  State<AdminTeachersPage> createState() => _AdminTeachersPageState();
}

class _AdminTeachersPageState extends State<AdminTeachersPage> {
  late Future<List<User>> _teachersFuture;

  @override
  void initState() {
    super.initState();
    _teachersFuture = _loadTeachers();
  }

  Future<List<User>> _loadTeachers() async {
    final users = await AppDatabase.instance.getAllUsers();
    return users
        .where((user) => user.role == 'teacher')
        .toList()
      ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
  }

  Future<void> _refresh() async {
    setState(() {
      _teachersFuture = _loadTeachers();
    });
  }

  Future<void> _deleteTeacher(User teacher) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir professor'),
        content: Text('Deseja remover ${teacher.fullName.isNotEmpty ? teacher.fullName : teacher.username}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true || teacher.id == null) return;

    await AppDatabase.instance.deleteUser(teacher.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Professor excluído com sucesso.')),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'Professores e escolas'),
      body: FutureBuilder<List<User>>(
        future: _teachersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar professores: ${snapshot.error}'));
          }

          final teachers = snapshot.data ?? const <User>[];

          if (teachers.isEmpty) {
            return const Center(child: Text('Nenhum professor cadastrado.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: teachers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final teacher = teachers[index];
                final schoolName = teacher.schoolId != null && teacher.schoolId!.isNotEmpty
                    ? SchoolService().getSchoolById(teacher.schoolId!)?.name ?? 'Escola não encontrada'
                    : 'Sem escola vinculada';

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade200, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.shade100,
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.orange.shade600,
                      child: const Icon(Icons.work_outline, color: Colors.white),
                    ),
                    title: Text(
                      teacher.fullName.isNotEmpty ? teacher.fullName : teacher.username,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Turmas: ${teacher.classGroup ?? 'Sem turma'}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.school_outlined, size: 16, color: Colors.orange.shade800),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  schoolName,
                                  style: TextStyle(color: Colors.blueGrey.shade800, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        tooltip: 'Excluir professor',
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteTeacher(teacher),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
