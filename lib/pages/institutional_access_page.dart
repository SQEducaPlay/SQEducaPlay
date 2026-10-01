import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../services/firebase_data_service.dart';
import '../services/firebase_service.dart';
import '../widgets/confirm_exit_scope.dart';

class InstitutionalAccessPage extends StatefulWidget {
  final bool startWithSignUp;

  const InstitutionalAccessPage({super.key, this.startWithSignUp = false});

  @override
  State<InstitutionalAccessPage> createState() =>
      _InstitutionalAccessPageState();
}

class _InstitutionalAccessPageState extends State<InstitutionalAccessPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _inviteController = TextEditingController();
  bool _creatingAccount = false;
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _memberships = [];

  @override
  void initState() {
    super.initState();
    _creatingAccount = widget.startWithSignUp;
    if (FirebaseService.instance.isInitialized &&
        FirebaseService.instance.auth.currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAccount());
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (!FirebaseService.instance.isInitialized) {
      setState(() => _error = 'O acesso institucional nao esta configurado.');
      return;
    }
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    if (!email.contains('@') || password.length < 8) {
      setState(() => _error = 'Informe e-mail e senha validos.');
      return;
    }
    if (_creatingAccount && _nameController.text.trim().isEmpty) {
      setState(() => _error = 'Informe seu nome completo.');
      return;
    }
    if (_creatingAccount && _inviteController.text.trim().isEmpty) {
      setState(() => _error = 'Informe o convite individual da escola.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_creatingAccount) {
        await FirebaseDataService.createAccount(
          email: email,
          password: password,
          fullName: _nameController.text.trim(),
          role: 'guardian',
        );
      } else {
        await FirebaseService.instance.auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      await _loadAccount(inviteCode: _inviteController.text.trim());
    } on firebase_auth.FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = switch (error.code) {
          'invalid-credential' ||
          'wrong-password' ||
          'user-not-found' => 'E-mail ou senha incorretos.',
          'email-already-in-use' => 'Esse e-mail ja tem conta. Escolha Entrar.',
          _ => 'Nao foi possivel autenticar. Confira os dados e o convite.',
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Nao foi possivel conectar. Verifique a internet.';
      });
    }
  }

  Future<void> _loadAccount({String? inviteCode}) async {
    if (!FirebaseService.instance.isInitialized) return;
    if (mounted) {
      setState(() {
        _busy = true;
        _error = null;
      });
    }
    try {
      final authUser = FirebaseService.instance.auth.currentUser;
      if (authUser == null) throw StateError('Sessao institucional encerrada.');

      var profile = await FirebaseDataService.fetchCurrentProfile();

      final role = profile['role'] as String? ?? '';
      if ((role == 'guardian' || role == 'teacher') &&
          inviteCode != null &&
          inviteCode.isNotEmpty) {
        await FirebaseDataService.redeemTeacherInvite(inviteCode);
        profile = await FirebaseDataService.fetchCurrentProfile();
      }

      final nextRole = profile['role'] as String? ?? '';
      if (!{'teacher', 'school_admin', 'admin'}.contains(nextRole)) {
        throw StateError(
          nextRole == 'guardian'
              ? 'Esta conta ainda nao recebeu um convite valido da escola.'
              : 'Este perfil nao tem acesso institucional.',
        );
      }

      final memberships = nextRole == 'admin'
          ? <Map<String, dynamic>>[]
          : await FirebaseDataService.listMemberships(authUser.uid);
      if (nextRole != 'admin' && memberships.isEmpty) {
        throw StateError('A escola ainda nao liberou o acesso institucional.');
      }

      if (!mounted) return;
      setState(() {
        _profile = Map<String, dynamic>.from(profile);
        _memberships = memberships;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error is StateError
            ? error.message.toString()
            : 'Nao foi possivel carregar o acesso da escola.';
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseService.instance.auth.signOut();
      if (!mounted) return;
      setState(() {
        _profile = null;
        _memberships = [];
        _inviteController.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Nao foi possivel sair da conta.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmExitScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Acesso da escola')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Icon(
                  Icons.workspace_premium,
                  size: 48,
                  color: Color(0xFFB46A00),
                ),
                const SizedBox(height: 12),
                Text(
                  _profile == null
                      ? 'Acesso de educador'
                      : 'Ola, ${_profile!['full_name'] ?? 'educador'}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (_profile == null) ..._buildAuthForm(),
                if (_profile != null) ...[
                  const SizedBox(height: 16),
                  _InstitutionalWorkspace(
                    isPlatformAdmin: _profile!['role'] == 'admin',
                    memberships: _memberships,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _busy ? null : _signOut,
                    child: const Text('Sair da conta da escola'),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                if (_busy) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAuthForm() => [
    if (_creatingAccount)
      TextField(
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Nome completo'),
      ),
    TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      decoration: const InputDecoration(labelText: 'E-mail institucional'),
    ),
    TextField(
      controller: _passwordController,
      obscureText: true,
      decoration: const InputDecoration(
        labelText: 'Senha (minimo 8 caracteres)',
      ),
      onSubmitted: (_) => _busy ? null : _authenticate(),
    ),
    TextField(
      controller: _inviteController,
      autocorrect: false,
      textCapitalization: TextCapitalization.characters,
      decoration: const InputDecoration(
        labelText: 'Convite individual da escola',
        helperText: 'Informe o codigo recebido da administracao escolar.',
      ),
    ),
    const SizedBox(height: 14),
    ElevatedButton(
      onPressed: _busy ? null : _authenticate,
      child: Text(
        _creatingAccount ? 'Criar conta e validar convite' : 'Entrar',
      ),
    ),
    TextButton(
      onPressed: _busy
          ? null
          : () => setState(() {
              _creatingAccount = !_creatingAccount;
              _error = null;
            }),
      child: Text(
        _creatingAccount
            ? 'Ja tenho conta; entrar'
            : 'Primeiro acesso? Criar conta com convite',
      ),
    ),
    const Text(
      'O convite e individual, vinculado a este e-mail e liberado somente para a escola que o emitiu.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12),
    ),
  ];
}

class _InstitutionalWorkspace extends StatefulWidget {
  final bool isPlatformAdmin;
  final List<Map<String, dynamic>> memberships;

  const _InstitutionalWorkspace({
    required this.isPlatformAdmin,
    required this.memberships,
  });

  @override
  State<_InstitutionalWorkspace> createState() =>
      _InstitutionalWorkspaceState();
}

class _InstitutionalWorkspaceState extends State<_InstitutionalWorkspace> {
  final _schoolNameController = TextEditingController();
  final _classNameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _shiftController = TextEditingController();
  final _inviteEmailController = TextEditingController();
  final _administratorEmailController = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _selectedSchoolId;
  List<Map<String, dynamic>> _schools = [];
  List<Map<String, dynamic>> _classrooms = [];
  List<Map<String, dynamic>> _pendingStudents = [];
  List<Map<String, dynamic>> _enrolledStudents = [];
  List<Map<String, dynamic>> _enrollments = [];
  Map<String, ({int quizzes, int points})> _studentStats = {};

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _classNameController.dispose();
    _gradeController.dispose();
    _shiftController.dispose();
    _inviteEmailController.dispose();
    _administratorEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadSchools() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final schools = await FirebaseDataService.listAuthorizedSchools(
        isPlatformAdmin: widget.isPlatformAdmin,
        memberships: widget.memberships,
      );
      final selected =
          _selectedSchoolId != null &&
              schools.any((school) => school['id'] == _selectedSchoolId)
          ? _selectedSchoolId
          : schools.isEmpty
          ? null
          : schools.first['id'] as String;
      if (mounted) {
        setState(() {
          _schools = schools;
          _selectedSchoolId = selected;
          _busy = false;
        });
      }
      if (selected != null) await _loadSchoolData(selected);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Nao foi possivel consultar as escolas autorizadas ($error).';
      });
    }
  }

  Future<void> _loadSchoolData(String schoolId) async {
    try {
      final workspace = await FirebaseDataService.loadSchoolWorkspace(schoolId);
      if (!mounted) return;
      setState(() {
        _classrooms = List<Map<String, dynamic>>.from(
          workspace['classrooms'] as List,
        );
        _pendingStudents = List<Map<String, dynamic>>.from(
          workspace['pendingStudents'] as List,
        );
        _enrolledStudents = List<Map<String, dynamic>>.from(
          workspace['enrolledStudents'] as List,
        );
        _enrollments = List<Map<String, dynamic>>.from(
          workspace['enrollments'] as List,
        );
        _studentStats = Map<String, ({int quizzes, int points})>.from(
          workspace['studentStats'] as Map,
        );
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Nao foi possivel carregar as turmas autorizadas ($error).';
      });
    }
  }

  Future<void> _createSchool() async {
    final name = _schoolNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Informe o nome da escola.');
      return;
    }
    try {
      await FirebaseDataService.createSchool(name);
      _schoolNameController.clear();
      await _loadSchools();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Nao foi possivel cadastrar a escola ($error).');
    }
  }

  Future<void> _createClassroom() async {
    final schoolId = _selectedSchoolId;
    final grade = _gradeController.text.trim();
    final name = _classNameController.text.trim();
    if (schoolId == null || grade.isEmpty || name.isEmpty) {
      setState(() => _error = 'Selecione a escola e informe serie e turma.');
      return;
    }
    try {
      await FirebaseDataService.createClassroom(
        schoolId: schoolId,
        grade: grade,
        name: name,
        shift: _shiftController.text.trim(),
      );
      _classNameController.clear();
      _gradeController.clear();
      _shiftController.clear();
      await _loadSchoolData(schoolId);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Nao foi possivel cadastrar a turma ($error).');
    }
  }

  Future<void> _issueTeacherInvite() async {
    final schoolId = _selectedSchoolId;
    final email = _inviteEmailController.text.trim().toLowerCase();
    if (schoolId == null || !email.contains('@')) {
      setState(
        () => _error = 'Selecione a escola e informe o e-mail do educador.',
      );
      return;
    }
    try {
      final code = await FirebaseDataService.issueTeacherInvite(
        schoolId: schoolId,
        email: email,
      );
      _inviteEmailController.clear();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Convite individual criado'),
          content: SelectableText(
            'Envie este codigo somente para $email. Ele expira em 14 dias e so pode ser usado uma vez:\n\n$code',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error =
            'Sua conta nao pode emitir convite para esta escola ($error).',
      );
    }
  }

  Future<void> _assignSchoolAdministrator() async {
    final schoolId = _selectedSchoolId;
    final email = _administratorEmailController.text.trim().toLowerCase();
    if (schoolId == null || !email.contains('@')) {
      setState(
        () =>
            _error = 'Selecione a escola e informe o e-mail do administrador.',
      );
      return;
    }
    try {
      await FirebaseDataService.assignSchoolAdministrator(
        schoolId: schoolId,
        email: email,
      );
      _administratorEmailController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Administrador escolar autorizado.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error =
            'Crie primeiro a conta deste usuario e confira o e-mail informado ($error).',
      );
    }
  }

  Future<void> _approveStudent(String studentId, String classroomId) async {
    try {
      await FirebaseDataService.approveStudent(
        studentId: studentId,
        classroomId: classroomId,
      );
      final schoolId = _selectedSchoolId;
      if (schoolId != null) await _loadSchoolData(schoolId);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error =
            'Nao foi possivel matricular o perfil. Confira sua autorizacao e a turma ($error).',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedSchool = _schools
        .where((school) => school['id'] == _selectedSchoolId)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.isPlatformAdmin) ...[
          const Text(
            'Administracao institucional',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextField(
            controller: _schoolNameController,
            decoration: const InputDecoration(labelText: 'Nova escola'),
          ),
          ElevatedButton(
            onPressed: _busy ? null : _createSchool,
            child: const Text('Cadastrar escola'),
          ),
        ],
        if (_schools.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            initialValue: _selectedSchoolId,
            decoration: const InputDecoration(labelText: 'Escola autorizada'),
            items: _schools
                .map(
                  (school) => DropdownMenuItem(
                    value: school['id'] as String,
                    child: Text(school['name'] as String),
                  ),
                )
                .toList(),
            onChanged: _busy
                ? null
                : (id) async {
                    if (id == null) return;
                    setState(() => _selectedSchoolId = id);
                    await _loadSchoolData(id);
                  },
          ),
          if (widget.isPlatformAdmin ||
              widget.memberships.any(
                (row) =>
                    row['school_id'] == _selectedSchoolId &&
                    row['role'] == 'school_admin',
              )) ...[
            TextField(
              controller: _gradeController,
              decoration: const InputDecoration(
                labelText: 'Serie/ano da turma',
              ),
            ),
            TextField(
              controller: _classNameController,
              decoration: const InputDecoration(labelText: 'Nome da turma'),
            ),
            TextField(
              controller: _shiftController,
              decoration: const InputDecoration(labelText: 'Turno (opcional)'),
            ),
            ElevatedButton(
              onPressed: _busy ? null : _createClassroom,
              child: const Text('Cadastrar turma'),
            ),
            TextField(
              controller: _inviteEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail do educador para convidar',
              ),
            ),
            ElevatedButton(
              onPressed: _busy ? null : _issueTeacherInvite,
              child: const Text('Gerar convite individual'),
            ),
          ],
          if (widget.isPlatformAdmin) ...[
            TextField(
              controller: _administratorEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail de administrador escolar',
              ),
            ),
            OutlinedButton(
              onPressed: _busy ? null : _assignSchoolAdministrator,
              child: const Text('Autorizar administrador escolar'),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Turmas de ${selectedSchool?['name'] ?? 'escola'}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (_classrooms.isEmpty)
            const Text('Ainda nao ha turmas cadastradas.')
          else
            ..._classrooms.map((classroom) {
              final classroomId = classroom['id'] as String;
              final classroomStudentIds = _enrollments
                  .where((row) => row['classroom_id'] == classroomId)
                  .map((row) => row['student_id'] as String)
                  .toSet();
              final students = _enrolledStudents
                  .where(
                    (student) => classroomStudentIds.contains(student['id']),
                  )
                  .toList();
              return ExpansionTile(
                leading: const Icon(Icons.class_),
                title: Text('${classroom['grade']} - ${classroom['name']}'),
                subtitle: Text(
                  '${classroom['shift'] ?? ''} • ${students.length} perfis matriculados',
                ),
                children: students.isEmpty
                    ? const [ListTile(title: Text('Ainda sem estudantes.'))]
                    : students.map((student) {
                        final stats =
                            _studentStats[student['id'] as String] ??
                            (quizzes: 0, points: 0);
                        return ListTile(
                          leading: const Icon(Icons.face),
                          title: Text(
                            (student['nickname'] as String?)
                                        ?.trim()
                                        .isNotEmpty ==
                                    true
                                ? student['nickname'] as String
                                : student['full_name'] as String,
                          ),
                          subtitle: Text(
                            '${stats.quizzes} quizzes • ${stats.points} pontos',
                          ),
                        );
                      }).toList(),
              );
            }),
          if (_pendingStudents.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Perfis aguardando aprovacao',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ..._pendingStudents.map(
              (student) => _PendingStudentTile(
                student: student,
                classrooms: _classrooms,
                onApprove: _approveStudent,
              ),
            ),
          ],
          if (!widget.isPlatformAdmin &&
              widget.memberships.any((row) => row['role'] == 'teacher')) ...[
            const SizedBox(height: 12),
            const Text(
              'Acesso de educador limitado a turmas e estudantes autorizados pela escola.',
              textAlign: TextAlign.center,
            ),
          ],
        ] else if (!widget.isPlatformAdmin)
          const Text('A conta ainda nao esta vinculada a uma escola.'),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
      ],
    );
  }
}

class _PendingStudentTile extends StatefulWidget {
  final Map<String, dynamic> student;
  final List<Map<String, dynamic>> classrooms;
  final Future<void> Function(String studentId, String classroomId) onApprove;

  const _PendingStudentTile({
    required this.student,
    required this.classrooms,
    required this.onApprove,
  });

  @override
  State<_PendingStudentTile> createState() => _PendingStudentTileState();
}

class _PendingStudentTileState extends State<_PendingStudentTile> {
  String? _classroomId;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final studentName =
        (widget.student['nickname'] as String?)?.trim().isNotEmpty == true
        ? widget.student['nickname'] as String
        : widget.student['full_name'] as String? ?? 'Perfil de aluno';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('$studentName • ${widget.student['grade']}'),
            DropdownButtonFormField<String>(
              initialValue: _classroomId,
              decoration: const InputDecoration(
                labelText: 'Matricular na turma',
              ),
              items: widget.classrooms
                  .map(
                    (classroom) => DropdownMenuItem(
                      value: classroom['id'] as String,
                      child: Text(
                        '${classroom['grade']} - ${classroom['name']}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _busy
                  ? null
                  : (id) => setState(() => _classroomId = id),
            ),
            ElevatedButton(
              onPressed: _busy || _classroomId == null
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      await widget.onApprove(
                        widget.student['id'] as String,
                        _classroomId!,
                      );
                      if (mounted) setState(() => _busy = false);
                    },
              child: const Text('Aprovar e matricular'),
            ),
          ],
        ),
      ),
    );
  }
}
