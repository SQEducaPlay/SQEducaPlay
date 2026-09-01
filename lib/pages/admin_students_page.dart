import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/user_model.dart';
import '../school_service.dart';
import '../widgets/app_bar.dart';

class AdminStudentsPage extends StatefulWidget {
  const AdminStudentsPage({super.key});

  @override
  State<AdminStudentsPage> createState() => _AdminStudentsPageState();
}

class _AdminStudentsPageState extends State<AdminStudentsPage> {
  late Future<List<User>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture = _loadStudents();
  }

  Future<List<User>> _loadStudents() async {
    final users = await AppDatabase.instance.getAllUsers();
    return users
        .where((user) => user.role == 'student')
        .toList()
      ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
  }

  Future<void> _refresh() async {
    setState(() {
      _studentsFuture = _loadStudents();
    });
  }

  Future<void> _deleteStudent(User student) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir aluno'),
        content: Text('Deseja remover ${student.fullName.isNotEmpty ? student.fullName : student.username}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true || student.id == null) return;

    await AppDatabase.instance.deleteUser(student.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aluno excluído com sucesso.')),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'Alunos e escolas'),
      body: FutureBuilder<List<User>>(
        future: _studentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar alunos: ${snapshot.error}'));
          }

          final students = snapshot.data ?? const <User>[];

          if (students.isEmpty) {
            return const Center(child: Text('Nenhum aluno cadastrado.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final student = students[index];
                final schoolName = student.schoolId != null && student.schoolId!.isNotEmpty
                    ? SchoolService().getSchoolById(student.schoolId!)?.name ?? 'Escola não encontrada'
                    : 'Sem escola vinculada';

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade200, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100,
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue.shade600,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      student.fullName.isNotEmpty ? student.fullName : student.username,
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
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${student.grade ?? 'Sem série'} • ${student.classGroup ?? 'Sem turma'}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.school_outlined, size: 16, color: Colors.blueGrey.shade700),
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
                        tooltip: 'Excluir aluno',
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteStudent(student),
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
