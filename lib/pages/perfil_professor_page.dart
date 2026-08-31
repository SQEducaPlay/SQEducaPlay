import 'package:flutter/material.dart';

import '../database/app_database.dart';
import 'access_choice_page.dart';
import '../models/teacher_assignment_model.dart';
import '../models/user_model.dart';
import '../pages/ranking_tabs_page.dart';
import '../services/progresso_service.dart';
import '../services/background_audio_service.dart';
import '../school_service.dart';
import '../theme/design_tokens.dart';
import '../services/user_service.dart';
import '../services/session_service.dart';
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
  late Future<List<User>> _usersFuture;
  List<TeacherAssignment> _teacherAssignments = [];

  @override
  void initState() {
    super.initState();
    _usersFuture = AppDatabase.instance.getAllUsers();
    _loadTeacherAssignments();
  }

  Future<void> _loadTeacherAssignments() async {
    final teacher = UserService().getUserByUsername(widget.username) ?? UserService().currentUser;
    if (teacher?.id == null) return;

    final assignments = await AppDatabase.instance.getTeacherAssignments(teacher!.id!);
    if (!mounted) return;
    setState(() => _teacherAssignments = assignments);
  }

  void _reloadUsers() {
    setState(() {
      _usersFuture = AppDatabase.instance.getAllUsers();
    });
  }

  Future<void> _openStudentsPage(
    BuildContext context,
    List<String> allowedGrades,
    Map<String, List<User>> studentsByGrade,
    Map<String, User> usersByUsername,
    List<dynamic> ranking,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => Scaffold(
          backgroundColor: DesignTokens.surface,
          appBar: const AppTopBar(title: 'Alunos'),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CardPrimary(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Seus alunos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Selecione uma turma para ver os alunos cadastrados.',
                      style: TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...allowedGrades.map(
                (grade) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildStudentsListCard(
                    pageContext,
                    accentColor: _gradeAccentColor(grade),
                    grade: grade,
                    students: studentsByGrade[grade] ?? const [],
                    ranking: ranking,
                    usersByUsername: usersByUsername,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openGradesPage(
    BuildContext context,
    List<String> allowedGrades,
    Map<String, List<User>> studentsByGrade,
    Map<String, User> usersByUsername,
    List<dynamic> ranking,
  ) async {
    String selectedRange = 'all';

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => StatefulBuilder(
          builder: (context, setLocalState) {
            return Scaffold(
              backgroundColor: DesignTokens.surface,
              appBar: const AppTopBar(title: 'Turmas'),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  CardPrimary(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Minhas turmas',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Veja o desempenho e o ranking de cada turma liberada.',
                          style: TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  CardPrimary(
                    padding: const EdgeInsets.all(14),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Tudo'),
                          selected: selectedRange == 'all',
                          onSelected: (_) => setLocalState(() => selectedRange = 'all'),
                        ),
                        ChoiceChip(
                          label: const Text('Hoje'),
                          selected: selectedRange == 'today',
                          onSelected: (_) => setLocalState(() => selectedRange = 'today'),
                        ),
                        ChoiceChip(
                          label: const Text('7 dias'),
                          selected: selectedRange == '7d',
                          onSelected: (_) => setLocalState(() => selectedRange = '7d'),
                        ),
                        ChoiceChip(
                          label: const Text('1 mês'),
                          selected: selectedRange == '30d',
                          onSelected: (_) => setLocalState(() => selectedRange = '30d'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...allowedGrades.map(
                    (grade) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: AppDatabase.instance.buscarTentativasPorAno(grade),
                        builder: (context, snapshot) {
                          final rawAttempts = snapshot.data ?? const <Map<String, dynamic>>[];
                          final attempts = _filterAttemptsByRange(rawAttempts, selectedRange);
                          final total = attempts.length;
                          final correct = attempts.where((item) => (item['acertou'] as int?) == 1).length;
                          final wrong = total - correct;
                          final uniqueStudents = attempts.map((item) => item['usuario_id']).whereType<int>().toSet().length;
                          final accuracy = total > 0 ? (correct / total * 100).toStringAsFixed(1) : '0.0';
                          final errorRate = total > 0 ? (wrong / total * 100).toStringAsFixed(1) : '0.0';
                          final topWrongQuestions = _topWrongQuestions(attempts, limit: 3);
                          final subjectBreakdown = _aggregateByField(attempts, 'materia', labelFallback: 'Sem matéria');

                          return CardPrimary(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        grade,
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _gradeAccentColor(grade)),
                                      ),
                                    ),
                                    if (snapshot.connectionState == ConnectionState.waiting)
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    SizedBox(width: 150, child: _buildMetricTile(accuracy, 'Acertos %', Icons.check_circle_outline)),
                                    SizedBox(width: 150, child: _buildMetricTile(errorRate, 'Erros %', Icons.highlight_off_outlined)),
                                    SizedBox(width: 150, child: _buildMetricTile('$total', 'Tentativas', Icons.quiz_outlined)),
                                    SizedBox(width: 150, child: _buildMetricTile('$uniqueStudents', 'Alunos', Icons.groups_outlined)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildAccuracyRing(
                                      accuracy: double.tryParse(accuracy) ?? 0,
                                      accentColor: _gradeAccentColor(grade),
                                      label: 'Acertos',
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildProgressBar(
                                            label: 'Acertos',
                                            value: double.tryParse(accuracy) ?? 0,
                                            color: Colors.green,
                                            trailing: '$accuracy%',
                                          ),
                                          const SizedBox(height: 10),
                                          _buildProgressBar(
                                            label: 'Erros',
                                            value: double.tryParse(errorRate) ?? 0,
                                            color: Colors.red,
                                            trailing: '$errorRate%',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  wrong == 0
                                      ? 'Nenhum erro registrado nessa turma ainda.'
                                      : 'Questões que mais apareceram como erro nesta turma:',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                if (subjectBreakdown.isNotEmpty) ...[
                                  const Text(
                                    'Matérias com mais erro',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 8),
                                  ...subjectBreakdown.map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: _buildProgressBar(
                                        label: item['label'] as String? ?? '',
                                        value: wrong == 0 ? 0 : ((item['count'] as int?) ?? 0) / wrong * 100,
                                        color: Colors.orange.shade700,
                                        trailing: '${item['count']}x',
                                        compact: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                if (topWrongQuestions.isEmpty)
                                  const Text('Sem dados suficientes por enquanto.')
                                else
                                  ...topWrongQuestions.map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: _buildProgressBar(
                                        label: item['pergunta'] as String? ?? '',
                                        value: wrong == 0 ? 0 : ((item['total_erros'] as int?) ?? 0) / wrong * 100,
                                        color: _gradeAccentColor(grade),
                                        trailing: '${item['total_erros']}x',
                                        compact: true,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
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
        title: 'Perfil do Educador',
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
              try {
                await BackgroundAudioService.instance.stopForTopic();
              } catch (_) {}

              if (!context.mounted) return;

              await SessionService.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AccessChoicePage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<User>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? const <User>[];
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
                _buildWelcomeCard(
                  context,
                  teacherName,
                  allowedGrades,
                  _teacherAssignments,
                  studentsByGrade.values.fold<int>(0, (sum, list) => sum + list.length),
                  studentsByGrade,
                  usersByUsername,
                  ranking,
                ),
                const SizedBox(height: 24),
                _buildQuickActionsCard(context, allowedGrades),
                const SizedBox(height: 24),
                const SectionHeader(title: 'Alunos por ano'),
                const SizedBox(height: 12),
                ...allowedGrades.map(
                  (grade) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildStudentsListCard(
                      context,
                      accentColor: _gradeAccentColor(grade),
                      grade: grade,
                      students: studentsByGrade[grade] ?? const [],
                      ranking: ranking,
                      usersByUsername: usersByUsername,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const SectionHeader(title: 'Minhas turmas'),
                const SizedBox(height: 12),
                if (_teacherAssignments.isNotEmpty)
                  ..._teacherAssignments.map(
                    (assignment) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildGradeCard(
                        context,
                        accentColor: _gradeAccentColor(assignment.grade),
                        grade: assignment.grade,
                        classGroup: assignment.classGroup,
                        shift: assignment.shift,
                        schoolName: _schoolName(assignment.schoolId),
                        students: _studentsForAssignment(students, assignment),
                        ranking: ranking,
                        usersByUsername: usersByUsername,
                      ),
                    ),
                  )
                else
                  ...allowedGrades.map(
                    (grade) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildGradeCard(
                        context,
                        accentColor: _gradeAccentColor(grade),
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

  User? _currentUser() {
    return UserService().getUserByUsername(widget.username) ?? UserService().currentUser;
  }

  String _displayName(User? user) {
    final fullName = user?.fullName.trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;
    return 'Educador';
  }

  String _schoolName(String schoolId) {
    return SchoolService().getSchoolById(schoolId)?.name ?? 'Escola não identificada';
  }

  List<String> _allowedGrades(User? user) {
    if (user?.role == 'teacher') {
      final assignedGrades = _teacherAssignments.map((item) => item.grade).toSet().toList();
      if (assignedGrades.isNotEmpty) return assignedGrades;

      final profileGrade = user?.grade?.trim();
      if (profileGrade != null && profileGrade.isNotEmpty) {
        return [profileGrade];
      }

      return const [
        '2º Ano Fundamental',
        '3º Ano Fundamental',
        '4º Ano Fundamental',
        '5º Ano Fundamental',
      ];
    }

    final grade = user?.grade?.trim();
    if (grade != null && grade.isNotEmpty) {
      return [grade];
    }

    return const ['2º Ano Fundamental', '3º Ano Fundamental'];
  }

  Map<String, List<User>> _groupStudentsByGrade(List<User> students, List<String> allowedGrades) {
    final map = <String, List<User>>{};
    for (final grade in allowedGrades) {
      map[grade] = students.where((student) {
        if (!_gradeMatches(student.grade, grade)) return false;
        if (_teacherAssignments.isEmpty) return true;

        return _teacherAssignments.any(
          (assignment) =>
              assignment.grade == grade &&
              assignment.schoolId == student.schoolId &&
              _normalizeClassGroup(assignment.classGroup) == _normalizeClassGroup(student.classGroup),
        );
      }).toList();
    }
    return map;
  }

  String _normalizeClassGroup(String? classGroup) {
    return (classGroup ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  List<User> _studentsForAssignment(List<User> students, TeacherAssignment assignment) {
    return students.where((student) {
      return _gradeMatches(student.grade, assignment.grade) &&
          student.schoolId == assignment.schoolId &&
          _normalizeClassGroup(student.classGroup) == _normalizeClassGroup(assignment.classGroup);
    }).toList();
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
  Future<void> _openStudentErrorsPage(
    BuildContext context,
    User student,
    String grade,
    List<dynamic> ranking,
  ) async {
    final studentId = student.id;
    if (studentId == null) return;
    String selectedRange = 'all';

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StatefulBuilder(
          builder: (context, setLocalState) {
            return Scaffold(
              backgroundColor: DesignTokens.surface,
              appBar: AppBar(title: Text(_getStudentDisplayName(student))),
              body: FutureBuilder<List<Map<String, dynamic>>>(
                future: AppDatabase.instance.buscarTentativasUsuario(studentId, somenteErros: false, limit: 500),
                builder: (context, totalSnapshot) {
                  if (totalSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allAttempts = _filterAttemptsByRange(totalSnapshot.data ?? const <Map<String, dynamic>>[], selectedRange);
                  final wrongAttempts = allAttempts.where((item) => (item['acertou'] as int?) == 0).toList();
                  final total = allAttempts.length;
                  final correct = allAttempts.where((item) => (item['acertou'] as int?) == 1).length;
                  final accuracy = total > 0 ? (correct / total * 100).toStringAsFixed(1) : '0.0';
                  final subjectBreakdown = _aggregateByField(wrongAttempts, 'materia', labelFallback: 'Sem matéria');
                  final topicBreakdown = _aggregateByField(wrongAttempts, 'topico', labelFallback: 'Sem tópico');

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      CardPrimary(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              grade,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _gradeAccentColor(grade)),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('Tudo'),
                                  selected: selectedRange == 'all',
                                  onSelected: (_) => setLocalState(() => selectedRange = 'all'),
                                ),
                                ChoiceChip(
                                  label: const Text('Hoje'),
                                  selected: selectedRange == 'today',
                                  onSelected: (_) => setLocalState(() => selectedRange = 'today'),
                                ),
                                ChoiceChip(
                                  label: const Text('7 dias'),
                                  selected: selectedRange == '7d',
                                  onSelected: (_) => setLocalState(() => selectedRange = '7d'),
                                ),
                                ChoiceChip(
                                  label: const Text('1 mês'),
                                  selected: selectedRange == '30d',
                                  onSelected: (_) => setLocalState(() => selectedRange = '30d'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                SizedBox(width: 150, child: _buildMetricTile(accuracy, 'Acertos %', Icons.check_circle_outline)),
                                SizedBox(width: 150, child: _buildMetricTile('${wrongAttempts.length}', 'Erros', Icons.highlight_off_outlined)),
                                SizedBox(width: 150, child: _buildMetricTile('$total', 'Tentativas', Icons.quiz_outlined)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      CardPrimary(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mapa de erros',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildAccuracyRing(
                                  accuracy: double.tryParse(accuracy) ?? 0,
                                  accentColor: Colors.orange.shade700,
                                  label: 'Acertos',
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    children: [
                                      _buildProgressBar(
                                        label: 'Perguntas erradas',
                                        value: total > 0 ? (wrongAttempts.length / total) * 100 : 0,
                                        color: Colors.red,
                                        trailing: '${wrongAttempts.length}x',
                                      ),
                                      const SizedBox(height: 10),
                                      _buildProgressBar(
                                        label: 'Perguntas corretas',
                                        value: total > 0 ? (correct / total) * 100 : 0,
                                        color: Colors.green,
                                        trailing: '$accuracy%',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (subjectBreakdown.isNotEmpty) ...[
                              const Text(
                                'Erros por matéria',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              ...subjectBreakdown.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildProgressBar(
                                    label: item['label'] as String? ?? '',
                                    value: total == 0 ? 0 : ((item['count'] as int?) ?? 0) / wrongAttempts.length * 100,
                                    color: Colors.orange.shade700,
                                    trailing: '${item['count']}x',
                                    compact: true,
                                  ),
                                ),
                              ),
                            ],
                            if (topicBreakdown.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              const Text(
                                'Erros por tema',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              ...topicBreakdown.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildProgressBar(
                                    label: item['label'] as String? ?? '',
                                    value: wrongAttempts.isEmpty ? 0 : ((item['count'] as int?) ?? 0) / wrongAttempts.length * 100,
                                    color: Colors.blue.shade700,
                                    trailing: '${item['count']}x',
                                    compact: true,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const SectionHeader(title: 'Perguntas erradas'),
                      const SizedBox(height: 12),
                      if (wrongAttempts.isEmpty)
                        const CardPrimary(
                          padding: EdgeInsets.all(16),
                          child: Text('Esse aluno ainda não possui erros registrados.'),
                        )
                      else
                        ...wrongAttempts.map(
                          (attempt) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CardPrimary(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    attempt['pergunta'] as String? ?? '',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Resposta marcada: ${attempt['resposta_selecionada'] ?? '-'}'),
                                  Text('Resposta correta: ${attempt['resposta_correta'] ?? '-'}'),
                                  Text('Matéria: ${attempt['materia'] ?? '-'}'),
                                  Text('Tópico: ${attempt['topico'] ?? '-'}'),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Data: ${attempt['data_tentativa'] ?? '-'}',
                                          style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _showQuestionReviewDialog(context, attempt),
                                        icon: const Icon(Icons.menu_book_outlined, size: 18),
                                        label: const Text('Revisar questão'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(
    BuildContext context,
    String teacherName,
    List<String> allowedGrades,
    List<TeacherAssignment> assignments,
    int totalStudents,
    Map<String, List<User>> studentsByGrade,
    Map<String, User> usersByUsername,
    List<dynamic> ranking,
  ) {
    return CardPrimary(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.primary,
                  DesignTokens.primary.withValues(alpha: 0.84),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -14,
                  top: -18,
                  child: Container(
                    width: 106,
                    height: 106,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  right: 18,
                  top: 18,
                  child: Icon(Icons.auto_awesome, color: Colors.white.withValues(alpha: 0.18), size: 54),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _teacherInitial(teacherName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Área do educador',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Perfil de acompanhamento',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.school_outlined, color: Colors.white.withValues(alpha: 0.92), size: 28),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Olá, $teacherName',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Acompanhe turmas, alunos e o ranking de forma rápida.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniSummaryCard(
                            '$totalStudents',
                            'Alunos',
                            Icons.groups,
                            onTap: () => _openStudentsPage(
                              context,
                              allowedGrades,
                              studentsByGrade,
                              usersByUsername,
                              ranking,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMiniSummaryCard(
                            '${assignments.isEmpty ? allowedGrades.length : assignments.length}',
                            'Atribuições',
                            Icons.class_outlined,
                            onTap: () => _openGradesPage(
                              context,
                              allowedGrades,
                              studentsByGrade,
                              usersByUsername,
                              ranking,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified_outlined, color: Colors.white.withValues(alpha: 0.95), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              allowedGrades.isEmpty
                                  ? 'Nenhuma turma liberada para este perfil.'
                                  : 'Turmas ativas para acompanhamento e leitura de ranking.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (assignments.isNotEmpty) ...[
                      Text(
                        'Escola: ${_schoolName(assignments.first.schoolId)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: assignments
                            .map(
                              (assignment) => _buildGradeBadge(
                                assignment.grade.replaceAll(' Fundamental', ''),
                                'Turma ${assignment.classGroup} • ${assignment.shift}',
                              ),
                            )
                            .toList(),
                      ),
                    ] else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: allowedGrades
                            .map(
                              (grade) => _buildGradeBadge(
                                grade.replaceAll(' Fundamental', ''),
                                'Série disponível',
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context, List<String> allowedGrades) {
    return CardPrimary(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acessos rápidos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Atalhos para acompanhar ranking e atualizar os dados da turma.',
            style: TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
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
                    icon: const Icon(Icons.leaderboard_outlined, size: 22),
                    label: const Text(
                      'Ranking geral',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.primary,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: DesignTokens.primary.withValues(alpha: 0.28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _reloadUsers,
                    icon: const Icon(Icons.refresh, size: 22),
                    label: const Text(
                      'Atualizar dados',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: Colors.orange.withValues(alpha: 0.28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSummaryCard(String value, String label, IconData icon, {VoidCallback? onTap}) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }

  String _teacherInitial(String teacherName) {
    final trimmed = teacherName.trim();
    if (trimmed.isEmpty) return 'P';
    return trimmed.characters.first.toUpperCase();
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

  Widget _buildGradeBadge(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeCard(
    BuildContext context, {
    required Color accentColor,
    required String grade,
    String? classGroup,
    String? shift,
    String? schoolName,
    required List<User> students,
    required List<dynamic> ranking,
    required Map<String, User> usersByUsername,
  }) {
    final gradeRanking = _gradeRanking(grade, ranking, usersByUsername);
    final totalPoints = gradeRanking.fold<int>(0, (sum, entry) => sum + (entry['points'] as int));
    final topStudent = gradeRanking.isNotEmpty ? gradeRanking.first['name'] as String : 'Sem alunos cadastrados';
    final topThree = gradeRanking.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.28), width: 1.2),
        gradient: LinearGradient(
          colors: [accentColor.withValues(alpha: 0.12), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CardPrimary(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    classGroup == null ? grade : '$grade • Turma $classGroup',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accentColor),
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
                  icon: Icon(Icons.leaderboard, color: accentColor),
                  label: Text('Ver ranking', style: TextStyle(color: accentColor)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (schoolName != null || shift != null)
              Text(
                [?schoolName, ?shift].join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.blueGrey.shade700, fontWeight: FontWeight.w600),
              ),
            if (schoolName != null || shift != null) const SizedBox(height: 8),
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
                          child: Material(
                            color: Colors.transparent,
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
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsListCard(
    BuildContext context, {
    required Color accentColor,
    required String grade,
    required List<User> students,
    required List<dynamic> ranking,
    required Map<String, User> usersByUsername,
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.22), width: 1.1),
        color: accentColor.withValues(alpha: 0.05),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: 12),
            collapsedIconColor: accentColor,
            iconColor: accentColor,
            title: Text(
              grade,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor),
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
                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => _openStudentErrorsPage(context, student, grade, ranking),
                      leading: CircleAvatar(
                        backgroundColor: accentColor.withValues(alpha: 0.92),
                        child: const Icon(Icons.person, color: Colors.white),
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
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Color _gradeAccentColor(String grade) {
    final normalized = _normalizeGrade(grade);
    const palette = [
      Color(0xFF1E88E5),
      Color(0xFF00897B),
      Color(0xFFF57C00),
      Color(0xFF8E24AA),
    ];
    final index = normalized.hashCode.abs() % palette.length;
    return palette[index];
  }

  List<Map<String, dynamic>> _topWrongQuestions(List<Map<String, dynamic>> attempts, {int limit = 3}) {
    final grouped = <String, Map<String, dynamic>>{};
    for (final attempt in attempts.where((item) => (item['acertou'] as int?) == 0)) {
      final pergunta = attempt['pergunta'] as String? ?? '';
      if (pergunta.isEmpty) continue;
      final entry = grouped.putIfAbsent(pergunta, () => {
        'pergunta': pergunta,
        'materia': attempt['materia'] as String? ?? '-',
        'topico': attempt['topico'] as String? ?? '',
        'total_erros': 0,
      });
      entry['total_erros'] = (entry['total_erros'] as int) + 1;
    }

    final result = grouped.values.toList()
      ..sort((a, b) => (b['total_erros'] as int).compareTo(a['total_erros'] as int));
    return result.take(limit).toList();
  }

  List<Map<String, dynamic>> _filterAttemptsByRange(List<Map<String, dynamic>> attempts, String range) {
    if (range == 'all') return attempts;

    final now = DateTime.now();
    DateTime start;
    switch (range) {
      case 'today':
        start = DateTime(now.year, now.month, now.day);
        break;
      case '7d':
        start = now.subtract(const Duration(days: 7));
        break;
      case '30d':
        start = now.subtract(const Duration(days: 30));
        break;
      default:
        return attempts;
    }

    return attempts.where((attempt) {
      final date = DateTime.tryParse(attempt['data_tentativa'] as String? ?? '');
      return date != null && !date.isBefore(start);
    }).toList();
  }

  List<Map<String, dynamic>> _aggregateByField(
    List<Map<String, dynamic>> attempts,
    String field, {
    required String labelFallback,
    int limit = 5,
  }) {
    final grouped = <String, int>{};
    for (final attempt in attempts.where((item) => (item['acertou'] as int?) == 0)) {
      final rawLabel = (attempt[field] as String?)?.trim();
      final label = (rawLabel == null || rawLabel.isEmpty) ? labelFallback : rawLabel;
      grouped[label] = (grouped[label] ?? 0) + 1;
    }

    final items = grouped.entries
        .map((entry) => {'label': entry.key, 'count': entry.value})
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return items.take(limit).toList();
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

  Widget _buildAccuracyRing({
    required double accuracy,
    required Color accentColor,
    required String label,
  }) {
    final clamped = accuracy.clamp(0, 100);
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 112,
            height: 112,
            child: CircularProgressIndicator(
              value: clamped / 100,
              strokeWidth: 10,
              backgroundColor: Colors.blueGrey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${clamped.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required String label,
    required double value,
    required Color color,
    required String trailing,
    bool compact = false,
  }) {
    final clamped = value.clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              trailing,
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: compact ? 10 : 12,
            value: clamped / 100,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  void _showQuestionReviewDialog(BuildContext context, Map<String, dynamic> attempt) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Revisar questão'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attempt['pergunta'] as String? ?? '',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text('Resposta marcada: ${attempt['resposta_selecionada'] ?? '-'}'),
                Text('Resposta correta: ${attempt['resposta_correta'] ?? '-'}'),
                Text('Matéria: ${attempt['materia'] ?? '-'}'),
                Text('Tópico: ${attempt['topico'] ?? '-'}'),
                const SizedBox(height: 8),
                Text(
                  'Data: ${attempt['data_tentativa'] ?? '-'}',
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  String _getStudentDisplayName(User student) {
    if (student.nickname != null && student.nickname!.trim().isNotEmpty) return student.nickname!.trim();
    return student.fullName;
  }

  List<Map<String, dynamic>> _gradeRanking(
    String grade,
    List<dynamic> ranking,
    Map<String, User> usersByUsername,
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