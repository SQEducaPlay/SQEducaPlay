import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../services/backend_service.dart';
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
    if (BackendService.instance.isInitialized &&
        BackendService.instance.client.auth.currentSession != null) {
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
    if (!BackendService.instance.isInitialized) {
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
      final auth = BackendService.instance.client.auth;
      if (_creatingAccount) {
        final response = await auth.signUp(
          email: email,
          password: password,
          data: {'full_name': _nameController.text.trim()},
          emailRedirectTo: kIsWeb ? Uri.base.toString() : null,
        );
        if (response.session == null) {
          setState(() {
            _creatingAccount = false;
            _busy = false;
            _error =
                'Confirme o e-mail. Depois entre com o mesmo e-mail e informe o convite da escola.';
          });
          return;
        }
      } else {
        await auth.signInWithPassword(email: email, password: password);
      }
      await _loadAccount(inviteCode: _inviteController.text.trim());
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message.toLowerCase().contains('invalid login')
            ? 'E-mail ou senha incorretos.'
            : 'Nao foi possivel autenticar. Confira os dados e o convite.';
      });
    } on PostgrestException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _friendlyBackendError(error.message);
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
    if (!BackendService.instance.isInitialized) return;
    if (mounted) {
      setState(() {
        _busy = true;
        _error = null;
      });
    }
    try {
      final client = BackendService.instance.client;
      final authUser = client.auth.currentUser;
      if (authUser == null) throw StateError('Sessao institucional encerrada.');

      var profile = await client
          .from('profiles')
          .select('id, full_name, role')
          .eq('id', authUser.id)
          .single();

      final role = profile['role'] as String? ?? '';
      if ((role == 'guardian' || role == 'teacher') &&
          inviteCode != null &&
          inviteCode.isNotEmpty) {
        await client.rpc(
          'redeem_teacher_invite',
          params: {'p_invite_token': inviteCode},
        );
        profile = await client
            .from('profiles')
            .select('id, full_name, role')
            .eq('id', authUser.id)
            .single();
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
          : List<Map<String, dynamic>>.from(
              await client
                  .from('school_memberships')
                  .select('school_id, role, status')
                  .eq('user_id', authUser.id)
                  .eq('status', 'active'),
            );
      if (nextRole != 'admin' && memberships.isEmpty) {
        throw StateError('A escola ainda nao liberou o acesso institucional.');
      }

      if (!mounted) return;
      setState(() {
        _profile = Map<String, dynamic>.from(profile);
        _memberships = memberships;
        _busy = false;
      });
    } on PostgrestException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _friendlyBackendError(error.message);
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

  String _friendlyBackendError(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('invitation') ||
        normalized.contains('invite') ||
        normalized.contains('email')) {
      return 'O convite nao e valido para este e-mail, expirou ou ja foi usado. Confira com a escola.';
    }
    return 'A operacao nao foi autorizada ou os dados da escola estao indisponiveis.';
  }

  Future<void> _signOut() async {
    try {
      await BackendService.instance.client.auth.signOut();
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

  SupabaseClient get _client => BackendService.instance.client;

  Future<void> _loadSchools() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      List<Map<String, dynamic>> schools;
      if (widget.isPlatformAdmin) {
        schools = List<Map<String, dynamic>>.from(
          await _client
              .from('schools')
              .select('id, name, active')
              .order('name'),
        );
      } else {
        final ids = widget.memberships
            .map((row) => row['school_id'] as String)
            .toSet()
            .toList();
        schools = ids.isEmpty
            ? <Map<String, dynamic>>[]
            : List<Map<String, dynamic>>.from(
                await _client
                    .from('schools')
                    .select('id, name, active')
                    .inFilter('id', ids)
                    .order('name'),
              );
      }
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
    } on PostgrestException {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Nao foi possivel consultar as escolas autorizadas.';
      });
    }
  }

  Future<void> _loadSchoolData(String schoolId) async {
    try {
      final classrooms = List<Map<String, dynamic>>.from(
        await _client
            .from('classrooms')
            .select('id, school_id, grade, name, shift, active')
            .eq('school_id', schoolId)
            .eq('active', true)
            .order('grade')
            .order('name'),
      );
      final pending = List<Map<String, dynamic>>.from(
        await _client
            .from('student_profiles')
            .select('id, full_name, nickname, grade, status')
            .eq('school_id', schoolId)
            .eq('status', 'pending')
            .order('created_at'),
      );
      final classroomIds = classrooms
          .map((row) => row['id'] as String)
          .toList();
      final enrollments = classroomIds.isEmpty
          ? <Map<String, dynamic>>[]
          : List<Map<String, dynamic>>.from(
              await _client
                  .from('student_enrollments')
                  .select('student_id, classroom_id')
                  .inFilter('classroom_id', classroomIds)
                  .eq('active', true),
            );
      final studentIds = enrollments
          .map((row) => row['student_id'] as String)
          .toSet()
          .toList();
      final students = studentIds.isEmpty
          ? <Map<String, dynamic>>[]
          : List<Map<String, dynamic>>.from(
              await _client
                  .from('student_profiles')
                  .select('id, full_name, nickname, grade, status')
                  .inFilter('id', studentIds)
                  .order('full_name'),
            );
      final sessions = studentIds.isEmpty
          ? <Map<String, dynamic>>[]
          : List<Map<String, dynamic>>.from(
              await _client
                  .from('quiz_sessions')
                  .select('student_id, score')
                  .inFilter('student_id', studentIds),
            );
      final stats = <String, ({int quizzes, int points})>{};
      for (final session in sessions) {
        final studentId = session['student_id'] as String;
        final previous = stats[studentId] ?? (quizzes: 0, points: 0);
        stats[studentId] = (
          quizzes: previous.quizzes + 1,
          points: previous.points + (session['score'] as int? ?? 0),
        );
      }
      if (!mounted) return;
      setState(() {
        _classrooms = classrooms;
        _pendingStudents = pending;
        _enrolledStudents = students;
        _enrollments = enrollments;
        _studentStats = stats;
        _error = null;
      });
    } on PostgrestException {
      if (!mounted) return;
      setState(() {
        _error = 'Nao foi possivel carregar as turmas autorizadas.';
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
      await _client.from('schools').insert({'name': name});
      _schoolNameController.clear();
      await _loadSchools();
    } on PostgrestException {
      if (!mounted) return;
      setState(() => _error = 'Nao foi possivel cadastrar a escola.');
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
      await _client.from('classrooms').insert({
        'school_id': schoolId,
        'grade': grade,
        'name': name,
        'shift': _shiftController.text.trim(),
      });
      _classNameController.clear();
      _gradeController.clear();
      _shiftController.clear();
      await _loadSchoolData(schoolId);
    } on PostgrestException {
      if (!mounted) return;
      setState(() => _error = 'Nao foi possivel cadastrar a turma.');
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
      final code = await _client.rpc(
        'create_teacher_invite',
        params: {'p_school_id': schoolId, 'p_email': email},
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
    } on PostgrestException {
      if (!mounted) return;
      setState(
        () => _error = 'Sua conta nao pode emitir convite para esta escola.',
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
      await _client.rpc(
        'assign_school_administrator',
        params: {'p_school_id': schoolId, 'p_email': email},
      );
      _administratorEmailController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Administrador escolar autorizado.')),
      );
    } on PostgrestException {
      if (!mounted) return;
      setState(
        () => _error =
            'Crie primeiro a conta deste usuario e confira o e-mail informado.',
      );
    }
  }

  Future<void> _approveStudent(String studentId, String classroomId) async {
    try {
      await _client.rpc(
        'approve_student',
        params: {'p_student_id': studentId, 'p_classroom_id': classroomId},
      );
      final schoolId = _selectedSchoolId;
      if (schoolId != null) await _loadSchoolData(schoolId);
    } on PostgrestException {
      if (!mounted) return;
      setState(
        () => _error =
            'Nao foi possivel matricular o perfil. Confira sua autorizacao e a turma.',
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
