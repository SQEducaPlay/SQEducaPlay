import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../services/progresso_service.dart';
import '../models/user_model.dart' as db_user;
import '../user_model.dart' as legacy_user;
import '../user_service.dart';
import '../school_service.dart';
import '../services/privacy_settings_service.dart';
import '../widgets/app_bar.dart';

class RankingTabsPage extends StatefulWidget {
  final String? currentUsername;
  final int initialTabIndex;
  final List<String>? allowedGrades;

  const RankingTabsPage({super.key, this.currentUsername, this.initialTabIndex = 0, this.allowedGrades});

  @override
  State<RankingTabsPage> createState() => _RankingTabsPageState();
}

class _RankingTabsPageState extends State<RankingTabsPage> with SingleTickerProviderStateMixin {
  final _progressoService = ProgressoService();
  final _userService = UserService();
  final _schoolService = SchoolService();
  Future<List<db_user.User>> _dbUsersFuture = Future.value(const <db_user.User>[]);

  String? _selectedSerie; // null = Todas
  String? _selectedSchoolId; // null = Todas
  StudentScope _studentScope = StudentScope.turma; // Escopo para visão do aluno (chips)
  String? _selectedAdminClassGroup; // filtro de turma para admin, opcional

  @override
  void initState() {
    super.initState();
    _dbUsersFuture = AppDatabase.instance.getAllUsers();
    final currentUser = _currentUser();
    final privacy = PrivacySettingsService();
    if (privacy.studentDefaultToOwnSchool && widget.currentUsername != null) {
      final user = currentUser;
      // Prioriza turma (classGroup) como filtro de série quando possível
      if (user?.grade != null) {
        _selectedSerie = user!.grade;
      }
      // E filtra pela própria escola como fallback
      _selectedSchoolId = user?.schoolId;
      // Define escopo padrão para estudantes
      if (user != null) {
        if (user.classGroup != null && user.classGroup!.trim().isNotEmpty) {
          _studentScope = StudentScope.turma;
        } else if (user.schoolId != null && user.schoolId!.isNotEmpty) {
          _studentScope = StudentScope.escola;
        } else {
          _studentScope = StudentScope.global;
        }
      }
    }

    if (currentUser?.role == 'teacher' && widget.allowedGrades != null && widget.allowedGrades!.isNotEmpty) {
      _selectedSerie = widget.allowedGrades!.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<db_user.User>>(
      future: _dbUsersFuture,
      builder: (context, snapshot) {
        final dbUsers = snapshot.data ?? const <db_user.User>[];
        final series = _seriesOptions(dbUsers);
        final schools = _schoolService.getAllSchools();
        final teacherScopedRanking = _isTeacherScopedRanking();

        return DefaultTabController(
          initialIndex: widget.initialTabIndex,
          length: 2,
          child: Scaffold(
            appBar: AppTopBar(
              title: 'Ranking',
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.leaderboard), text: 'Alunos'),
                  Tab(icon: Icon(Icons.apartment), text: 'Escolas'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                Column(
                  children: [
                    if (!_showFiltersForCurrentUser()) Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Minha Turma'),
                              selected: _studentScope == StudentScope.turma,
                              onSelected: (sel) => setState(() => _studentScope = StudentScope.turma),
                            ),
                            ChoiceChip(
                              label: const Text('Minha Escola'),
                              selected: _studentScope == StudentScope.escola,
                              onSelected: (sel) => setState(() => _studentScope = StudentScope.escola),
                            ),
                            ChoiceChip(
                              label: const Text('Global'),
                              selected: _studentScope == StudentScope.global,
                              onSelected: (sel) => setState(() => _studentScope = StudentScope.global),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showFiltersForCurrentUser()) Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: Column(
                        children: [
                          if (teacherScopedRanking)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final grade in series)
                                    ChoiceChip(
                                      label: Text(grade),
                                      selected: _selectedSerie == grade,
                                      onSelected: (_) => setState(() {
                                        _selectedSerie = grade;
                                        _selectedAdminClassGroup = null;
                                      }),
                                    ),
                                ],
                              ),
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String?>(
                                    initialValue: _selectedSerie,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'Série',
                                    ),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('Todas as séries'),
                                      ),
                                      ...series.map((s) => DropdownMenuItem<String?>(value: s, child: Text(s)))
                                    ],
                                    onChanged: (value) => setState(() { _selectedSerie = value; _selectedAdminClassGroup = null; }),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String?>(
                                    initialValue: _selectedSchoolId,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'Escola',
                                    ),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('Todas as escolas'),
                                      ),
                                      ...schools.map((sch) => DropdownMenuItem<String?>(value: sch.id, child: Text(sch.name)))
                                    ],
                                    onChanged: (value) => setState(() { _selectedSchoolId = value; _selectedAdminClassGroup = null; }),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          if (_selectedSchoolId != null && _selectedSerie != null)
                            _buildAdminClassGroupFilter(schoolId: _selectedSchoolId!, grade: _selectedSerie!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(child: _buildRankingAlunos(dbUsers)),
                  ],
                ),
                _buildRankingEscolas(dbUsers),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _showFiltersForCurrentUser() {
    final currentUser = _currentUser();
    if (currentUser == null) return widget.currentUsername == null;
    return currentUser.role == 'admin' || currentUser.role == 'teacher';
  }

  bool _isTeacherScopedRanking() {
    final allowed = widget.allowedGrades;
    return allowed != null && allowed.isNotEmpty;
  }

  List<String> _seriesOptions(List<db_user.User> users) {
    final set = <String>{};
    for (final u in users) {
      if (u.role == 'student' && u.grade != null) set.add(u.grade!);
    }
    final series = set.toList()..sort();
    if (widget.allowedGrades == null || widget.allowedGrades!.isEmpty) {
      return series;
    }
    return series.where((grade) => widget.allowedGrades!.any((allowed) => _gradeMatches(grade, allowed))).toList();
  }

  bool _gradeMatches(String? a, String? b) {
    final left = _normalizeGrade(a);
    final right = _normalizeGrade(b);
    return left == right || left.contains(right) || right.contains(left);
  }

  String _normalizeGrade(String? value) {
    return (value ?? '')
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  legacy_user.User? _currentUser() {
    if (widget.currentUsername != null) {
      return _userService.getUserByUsername(widget.currentUsername!);
    }
    return _userService.currentUser;
  }

  Widget _buildRankingAlunos(List<db_user.User> dbUsers) {
    final ranking = _progressoService.getRanking();
    final filtered = <_AlunoRank>[];
    final privacy = PrivacySettingsService();
    final isStudentView = !_showFiltersForCurrentUser();
    final currentUser = _currentUser();

    final Map<String, db_user.User> usersByUsername = {
      for (final user in dbUsers) user.username.toLowerCase(): user,
    };

    for (var prog in ranking) {
      final user = usersByUsername[prog.username.toLowerCase()];
      if (user == null || user.role != 'student') continue;
      // Filtros: visão admin usa Série/Escola (e Turma opcional); visão aluno usa escopo (chips)
      if (!isStudentView) {
        if (_selectedSerie != null && !_gradeMatches(user.grade, _selectedSerie)) continue;
        if (_selectedSchoolId != null && user.schoolId != _selectedSchoolId) continue;
        if (_selectedAdminClassGroup != null && _selectedAdminClassGroup!.isNotEmpty) {
          if (user.classGroup != _selectedAdminClassGroup) continue;
        }
      } else {
        // Student scope filtering
        if (currentUser != null) {
          switch (_studentScope) {
            case StudentScope.turma:
              // se aluno não tem turma, cai para escola
              if (currentUser.classGroup == null || currentUser.classGroup!.trim().isEmpty) {
                if (currentUser.schoolId != null) {
                  if (user.schoolId != currentUser.schoolId) continue;
                }
              } else {
                // Match por escola + série + nome da turma
                if (user.schoolId != currentUser.schoolId) continue;
                if (!_gradeMatches(user.grade, currentUser.grade)) continue;
                if (user.classGroup != currentUser.classGroup) continue;
              }
              break;
            case StudentScope.escola:
              if (currentUser.schoolId != null) {
                if (user.schoolId != currentUser.schoolId) continue;
              }
              break;
            case StudentScope.global:
              // sem filtro adicional
              break;
          }
        }
      }
      // Futuro: quando houver gestão de turmas, poderemos filtrar por turma específica aqui.
      final schoolName = (user.schoolId != null && privacy.showSchoolInStudentRanking)
          ? (_schoolService.getSchoolById(user.schoolId!)?.name)
          : null;
      final displayName = _publicName(user.fullName, user.nickname, privacy.anonymizeStudentNames);
      final quizPoints = prog.pontosPorMateria.values.fold<int>(0, (sum, value) => sum + value);
      filtered.add(_AlunoRank(
        username: prog.username,
        pontos: quizPoints,
        estrelas: prog.estrelasTotal,
        quizes: prog.quizesCompletados,
        nivel: prog.nivel,
        schoolName: schoolName,
        displayName: displayName,
      ));
    }

    // Já vem em ordem do getRanking. Posição é o índice + 1
    final myIndex = widget.currentUsername != null
        ? filtered.indexWhere((a) => a.username == widget.currentUsername)
        : -1;

    return filtered.isEmpty
        ? const Center(
            child: Text('Nenhum aluno encontrado com os filtros selecionados.'),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length + (myIndex >= 0 ? 1 : 0),
            itemBuilder: (context, index) {
              // Insere o destaque do aluno logado fixo no topo
              if (myIndex >= 0 && index == 0) {
                final aluno = filtered[myIndex];
                return _buildAlunoCard(
                  aluno: aluno,
                  posicao: myIndex + 1,
                  destaque: true,
                );
              }

              final realIndex = (myIndex >= 0) ? index - 1 : index;
              final aluno = filtered[realIndex];

              // Evita repetir o aluno destacado na lista
              if (myIndex >= 0 && aluno.username == widget.currentUsername) {
                return const SizedBox.shrink();
              }

              return _buildAlunoCard(
                aluno: aluno,
                posicao: realIndex + 1,
                destaque: false,
              );
            },
          );
  }

  Widget _buildAlunoCard({required _AlunoRank aluno, required int posicao, required bool destaque}) {
    final isTop3 = posicao <= 3;
    final color = isTop3
        ? (posicao == 1
            ? Colors.amber[700]!
            : posicao == 2
                ? Colors.grey[600]!
                : Colors.brown[400]!)
        : Colors.white;

    return Card(
      elevation: isTop3 || destaque ? 8 : 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: destaque ? Colors.blue[400] : color,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildPosicaoWidget(posicao),
        title: Text(
          aluno.displayName ?? aluno.username,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: (isTop3 || destaque) ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (aluno.schoolName != null)
              Row(
                children: [
                  Icon(
                    Icons.school,
                    size: 15,
                    color: (isTop3 || destaque) ? Colors.white : Colors.blueGrey.shade800,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      aluno.schoolName!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: (isTop3 || destaque) ? Colors.white : Colors.blueGrey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            Text(
              aluno.nivel,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: (isTop3 || destaque) ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.stars,
                      size: 17,
                      color: (isTop3 || destaque) ? Colors.yellow[200] : Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${aluno.estrelas} estrelas',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: (isTop3 || destaque) ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 17,
                      color: (isTop3 || destaque) ? Colors.green[200] : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${aluno.quizes} quizes',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: (isTop3 || destaque) ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 76,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: (isTop3 || destaque) ? Colors.yellow[200] : Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${aluno.pontos}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: (isTop3 || destaque) ? Colors.white : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminClassGroupFilter({required String schoolId, required String grade}) {
    // Lista turmas a partir dos usuários existentes (fallback simples)
    final users = _userService.getAllUsers().where((u) =>
        u.role == 'student' && u.schoolId == schoolId && u.grade == grade && (u.classGroup != null && u.classGroup!.trim().isNotEmpty));
    final set = <String>{}..addAll(users.map((u) => u.classGroup!.trim()));
    final turmas = set.toList()..sort();
    if (turmas.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String?>(
            initialValue: _selectedAdminClassGroup,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Turma',
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Todas as turmas'),
              ),
              ...turmas.map((t) => DropdownMenuItem<String?>(value: t, child: Text(t)))
            ],
            onChanged: (value) => setState(() => _selectedAdminClassGroup = value),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingEscolas(List<db_user.User> dbUsers) {
    final rankingAlunos = _progressoService.getRanking();
    final Map<String, int> pontosPorEscola = {};
    final Map<String, int> alunosPorEscola = {};

    final Map<String, db_user.User> usersByUsername = {
      for (final user in dbUsers) user.username.toLowerCase(): user,
    };

    for (final prog in rankingAlunos) {
      final user = usersByUsername[prog.username.toLowerCase()];
      final schoolId = user?.schoolId;
      if (schoolId == null) continue;
      final quizPoints = prog.pontosPorMateria.values.fold<int>(0, (sum, value) => sum + value);
      pontosPorEscola[schoolId] = (pontosPorEscola[schoolId] ?? 0) + quizPoints;
      alunosPorEscola[schoolId] = (alunosPorEscola[schoolId] ?? 0) + 1;
    }

    final entries = pontosPorEscola.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return const Center(
        child: Text('Ainda não há escolas com pontuação.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final posicao = index + 1;
        final schoolId = entries[index].key;
        final totalPontos = entries[index].value;
        final qtdAlunos = alunosPorEscola[schoolId] ?? 0;
        final school = _schoolService.getSchoolById(schoolId);
        final schoolName = school?.name ?? 'Escola $schoolId';
        final city = school?.city;

        final isTop3 = posicao <= 3;
        final color = isTop3
            ? (posicao == 1
                ? Colors.indigo[400]!
                : posicao == 2
                    ? Colors.indigo[200]!
                    : Colors.indigo[100]!)
            : Colors.white;

        return Card(
          elevation: isTop3 ? 8 : 2,
          margin: const EdgeInsets.only(bottom: 12),
          color: color,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            leading: _buildPosicaoWidget(posicao),
            title: Text(
              schoolName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: isTop3 ? Colors.white : Colors.black,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (city != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: isTop3 ? Colors.white : Colors.blueGrey.shade800,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          city,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isTop3 ? Colors.white : Colors.blueGrey.shade800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    Icon(Icons.group, size: 14, color: isTop3 ? Colors.white : Colors.blueGrey.shade800),
                    const SizedBox(width: 4),
                    Text(
                      '$qtdAlunos aluno(s)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isTop3 ? Colors.white : Colors.blueGrey.shade800),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 78,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.yellow, size: 22),
                        const SizedBox(width: 4),
                        Text(
                          '$totalPontos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isTop3 ? Colors.white : Colors.indigo.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPosicaoWidget(int posicao) {
    if (posicao == 1) {
      return const CircleAvatar(radius: 24, child: Text('🥇', style: TextStyle(fontSize: 22)));
    } else if (posicao == 2) {
      return const CircleAvatar(radius: 24, child: Text('🥈', style: TextStyle(fontSize: 22)));
    } else if (posicao == 3) {
      return const CircleAvatar(radius: 24, child: Text('🥉', style: TextStyle(fontSize: 22)));
    }
    return CircleAvatar(
      backgroundColor: Colors.blue,
      radius: 24,
      child: Text(
        '$posicao',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _publicName(String fullName, String? nickname, bool anonymize) {
    if (!anonymize) return nickname?.trim().isNotEmpty == true ? nickname! : fullName;
    if (nickname != null && nickname.trim().isNotEmpty) return nickname.trim();
    // Usa PrimeiroNome + inicial do sobrenome
    final parts = fullName.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return fullName;
    if (parts.length == 1) return parts.first; // apenas primeiro nome
    final first = parts.first;
    final lastInitial = parts.last.isNotEmpty ? parts.last[0].toUpperCase() : '';
    return '$first $lastInitial.';
  }
}

class _AlunoRank {
  final String username;
  final int pontos;
  final int estrelas;
  final int quizes;
  final String nivel;
  final String? schoolName;
  final String? displayName;

  _AlunoRank({
    required this.username,
    required this.pontos,
    required this.estrelas,
    required this.quizes,
    required this.nivel,
    this.schoolName,
    this.displayName,
  });
}

enum StudentScope { turma, escola, global }
