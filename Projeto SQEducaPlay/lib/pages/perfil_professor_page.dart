import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../login_page.dart';
import '../models/user_model.dart' as db_user;
import '../pages/ranking_tabs_page.dart';
import '../services/progresso_service.dart';
import '../services/background_audio_service.dart';
import '../theme/design_tokens.dart';
import '../user_model.dart' as legacy_user;
import '../user_service.dart';
import '../widgets/app_bar.dart';
import '../widgets/card_primary.dart';
import '../widgets/section_header.dart';

class ProfessorDashboardPage extends StatefulWidget {
  final String username;

  const ProfessorDashboardPage({super.key, required this.username});

  @override
  State<ProfessorDashboardPage> createState() => _ProfessorDashboardPageState();
}

class _ProfessorDashboardPageState extends State<ProfessorDashboardPage> {
  late final Future<List<db_user.User>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = AppDatabase.instance.getAllUsers();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _currentUser();
    final teacherName = _displayName(currentUser);
    final allowedGrades = _allowedGrades(currentUser);
    final ranking = ProgressoService().getRanking();

    return Scaffold(
      backgroundColor: DesignTokens.surface,
      appBar: AppTopBar(
        title: 'Perfil do Professor',
        showProfileAvatar: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            tooltip: 'Ranking das turmas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RankingTabsPage(
                    currentUsername: widget.username,
                    allowedGrades: allowedGrades,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              // Parar serviços de áudio para evitar que continuem tocando
              try {
                await BackgroundAudioService.instance.stopForTopic();
              } catch (_) {}

              if (!context.mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<db_user.User>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? const <db_user.User>[];
          final students = users.where((user) => user.role == 'student').toList();
          final studentsByGrade = _groupStudentsByGrade(students, allowedGrades);
          final usersByUsername = {
            for (final user in users) user.username.toLowerCase(): user,
          };

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(teacherName, allowedGrades),
                const SizedBox(height: 24),
                const SectionHeader(title: 'Minhas turmas'),
                const SizedBox(height: 12),
                ...allowedGrades.map(
                  (grade) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildGradeCard(
                      context,
                      grade: grade,
                      students: studentsByGrade[grade] ?? const [],
                      ranking: ranking,
                      usersByUsername: usersByUsername,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const SectionHeader(title: 'Alunos por ano'),
                const SizedBox(height: 12),
                ...allowedGrades.map(
                  (grade) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildStudentsListCard(
                      context,
                      grade: grade,
                      students: studentsByGrade[grade] ?? const [],
                      ranking: ranking,
                      usersByUsername: usersByUsername,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  legacy_user.User? _currentUser() {
    return UserService().getUserByUsername(widget.username) ?? UserService().currentUser;
  }

  String _displayName(legacy_user.User? user) {
    final fullName = user?.fullName.trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;
    return 'Professor Keinan';
  }

  List<String> _allowedGrades(legacy_user.User? user) {
    if (user?.username.toLowerCase() == 'keinan' || user?.role == 'teacher') {
      return const ['2º Ano Fundamental', '3º Ano Fundamental'];
    }

    final grade = user?.grade?.trim();
    if (grade != null && grade.isNotEmpty) {
      return [grade];
    }

    return const ['2º Ano Fundamental', '3º Ano Fundamental'];
  }

  Map<String, List<db_user.User>> _groupStudentsByGrade(List<db_user.User> students, List<String> allowedGrades) {
    final map = <String, List<db_user.User>>{};
    for (final grade in allowedGrades) {
      map[grade] = students.where((student) => _gradeMatches(student.grade, grade)).toList();
    }
    return map;
  }

  bool _gradeMatches(String? studentGrade, String allowedGrade) {
    final normalizedStudent = _normalizeGrade(studentGrade);
    final normalizedAllowed = _normalizeGrade(allowedGrade);
    return normalizedStudent.contains(normalizedAllowed) || normalizedAllowed.contains(normalizedStudent);
  }

  String _normalizeGrade(String? grade) {
    return (grade ?? '')
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  Widget _buildWelcomeCard(String teacherName, List<String> allowedGrades) {
    return CardPrimary(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: DesignTokens.primary,
                child: Text(
                  teacherName.isNotEmpty ? teacherName[0].toUpperCase() : 'P',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bem-vindo,',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      teacherName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final grade in allowedGrades) ...[
                _buildInfoChip(Icons.school, grade),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(child: _buildInfoChip(Icons.menu_book, 'Português')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildInfoChip(Icons.calculate, 'Matemática')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      backgroundColor: DesignTokens.primary,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildGradeCard(
    BuildContext context, {
    required String grade,
    required List<db_user.User> students,
    required List<dynamic> ranking,
    required Map<String, db_user.User> usersByUsername,
  }) {
    final gradeRanking = _gradeRanking(grade, ranking, usersByUsername);
    final totalPoints = gradeRanking.fold<int>(0, (sum, entry) => sum + (entry['points'] as int));
    final topStudent = gradeRanking.isNotEmpty ? gradeRanking.first['name'] as String : 'Sem alunos cadastrados';
    final topThree = gradeRanking.take(3).toList();

    return CardPrimary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  grade,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RankingTabsPage(
                        currentUsername: widget.username,
                        allowedGrades: [grade],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.leaderboard),
                label: const Text('Ver ranking'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildMetricTile('${students.length}', 'Alunos', Icons.groups)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricTile('$totalPoints', 'Pontos', Icons.emoji_events)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricTile(topStudent == 'Sem alunos cadastrados' ? '-' : '1º', 'Líder', Icons.workspace_premium)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInfoChip(Icons.menu_book, 'Português')),
              const SizedBox(width: 8),
              Expanded(child: _buildInfoChip(Icons.calculate, 'Matemática')),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Líder da turma: $topStudent',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 6),
          if (topThree.isEmpty)
            const Text('Ainda não há ranking para este ano.')
          else
            Column(
              children: topThree
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          leading: CircleAvatar(
                            backgroundColor: _rankColor(entry['position'] as int),
                            child: Text(
                              '${entry['position']}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            entry['name'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${entry['points']} pontos • ${entry['stars']} ⭐',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentsListCard(
    BuildContext context, {
    required String grade,
    required List<db_user.User> students,
    required List<dynamic> ranking,
    required Map<String, db_user.User> usersByUsername,
  }) {
    final gradeRanking = _gradeRanking(grade, ranking, usersByUsername);
    final rankingByUsername = {
      for (final item in gradeRanking) item['username'] as String: item,
    };
    final orderedStudents = [...students]
      ..sort((a, b) {
        final rankA = rankingByUsername[a.username]?['position'] as int? ?? 9999;
        final rankB = rankingByUsername[b.username]?['position'] as int? ?? 9999;
        return rankA.compareTo(rankB);
      });

    return CardPrimary(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 12),
        title: Text(
          grade,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${students.length} aluno(s) disponíveis'),
        children: [
          if (students.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Nenhum aluno cadastrado neste ano.'),
              ),
            )
          else
            ...orderedStudents.map((student) {
              final studentRank = gradeRanking.firstWhere(
                (item) => item['username'] == student.username,
                orElse: () => {'position': '-', 'points': 0},
              );
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(_getStudentDisplayName(student)),
                subtitle: Text(
                  student.classGroup != null && student.classGroup!.trim().isNotEmpty
                      ? student.classGroup!
                      : 'Sem turma definida',
                ),
                trailing: Text(
                  '#${studentRank['position']} • ${studentRank['points']} pts',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: DesignTokens.primary, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _getStudentDisplayName(db_user.User student) {
    if (student.nickname != null && student.nickname!.trim().isNotEmpty) return student.nickname!.trim();
    return student.fullName;
  }

  List<Map<String, dynamic>> _gradeRanking(
    String grade,
    List<dynamic> ranking,
    Map<String, db_user.User> usersByUsername,
  ) {
    final items = <Map<String, dynamic>>[];

    for (final entry in ranking) {
      final username = (entry.username as String).toLowerCase();
      final student = usersByUsername[username];
      if (student == null || student.role != 'student' || !_gradeMatches(student.grade, grade)) continue;

      final quizPoints = (entry.pontosPorMateria as Map<String, int>).values.fold<int>(0, (sum, val) => sum + val);
      items.add({
        'position': items.length + 1,
        'username': student.username,
        'name': _getStudentDisplayName(student),
        'points': quizPoints,
        'stars': entry.estrelasTotal as int,
      });
    }

    return items;
  }

  Color _rankColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber[700]!;
      case 2:
        return Colors.grey[600]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return DesignTokens.primary;
    }
  }
}