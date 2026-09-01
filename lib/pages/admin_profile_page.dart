import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/user_model.dart';
import '../widgets/app_bar.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  late Future<List<User>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture = _loadStudents();
  }

  Future<List<User>> _loadStudents() async {
    final users = await AppDatabase.instance.getAllUsers();
    return users.where((user) => user.role == 'student').toList();
  }

  Future<void> _refreshStudents() async {
    setState(() {
      _studentsFuture = _loadStudents();
    });
  }

  Future<void> _deleteStudent(User student) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir aluno'),
        content: Text(
          'Deseja remover o aluno ${student.fullName.isNotEmpty ? student.fullName : student.username}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    if (student.id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir este aluno.')),
      );
      return;
    }

    await AppDatabase.instance.deleteUser(student.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aluno excluído com sucesso.')),
    );
    await _refreshStudents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Perfil de admin',
        showBackButton: true,
        showProfileAvatar: false,
      ),
      body: FutureBuilder<List<User>>(
        future: _studentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar alunos: ${snapshot.error}'),
            );
          }

          final students = snapshot.data ?? const <User>[];

          return RefreshIndicator(
            onRefresh: _refreshStudents,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.admin_panel_settings, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Administrador',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${students.length} aluno(s) cadastrado(s)',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gerenciar alunos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (students.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('Nenhum aluno cadastrado.'),
                      ),
                    ),
                  )
                else
                  ...students.map((student) {
                    final studentName = student.fullName.trim().isNotEmpty
                        ? student.fullName
                        : student.username;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(studentName),
                        subtitle: Text(
                          student.grade != null && student.grade!.isNotEmpty
                              ? '${student.grade} • ${student.classGroup ?? 'Sem turma'}'
                              : student.username,
                        ),
                        trailing: IconButton(
                          tooltip: 'Excluir aluno',
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteStudent(student),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
