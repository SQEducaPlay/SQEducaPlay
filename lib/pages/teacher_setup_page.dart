import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/user_model.dart';
import '../models/teacher_assignment_model.dart';
import '../services/password_service.dart';
import '../school_service.dart';
import '../services/user_service.dart';
import '../widgets/app_bar.dart';

// Correção P0-03: a criação de conta de educador deixou de depender apenas
// de "ainda não existe outro educador neste aparelho" — qualquer pessoa
// conseguia se autocadastrar e escolher escola/turmas livremente. Agora é
// obrigatório um código de convite de uso único, emitido por um
// administrador para a escola selecionada (veja
// AppDatabase.createTeacherFromInvite e TeacherInviteService).

class TeacherSetupPage extends StatefulWidget {
  const TeacherSetupPage({super.key});

  @override
  State<TeacherSetupPage> createState() => _TeacherSetupPageState();
}

class _TeacherSetupPageState extends State<TeacherSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _classGroupController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _inviteCodeController = TextEditingController();

  final _schools = SchoolService().getAllSchools();
  final _grades = const [
    '2º Ano Fundamental',
    '3º Ano Fundamental',
    '4º Ano Fundamental',
    '5º Ano Fundamental',
  ];
  final _shifts = const ['Manhã', 'Tarde', 'Integral'];
  String? _selectedSchoolId;
  String? _selectedGrade;
  String? _selectedShift;
  final List<_TeacherAssignmentDraft> _assignments = [];

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _classGroupController.dispose();
    _scheduleController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  void _addAssignment() {
    if (_selectedSchoolId == null || _selectedGrade == null || _selectedShift == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe escola, série e turno da turma.')),
      );
      return;
    }

    final classGroup = _classGroupController.text.trim();
    if (classGroup.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a turma.')),
      );
      return;
    }

    final duplicate = _assignments.any(
      (item) =>
          item.schoolId == _selectedSchoolId &&
          item.grade == _selectedGrade &&
          item.classGroup.toLowerCase() == classGroup.toLowerCase() &&
          item.shift == _selectedShift,
    );
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Essa turma já foi adicionada.')),
      );
      return;
    }

    setState(() {
      _assignments.add(
        _TeacherAssignmentDraft(
          schoolId: _selectedSchoolId!,
          grade: _selectedGrade!,
          classGroup: classGroup,
          shift: _selectedShift!,
          schedule: _scheduleController.text.trim(),
        ),
      );
      _classGroupController.clear();
      _scheduleController.clear();
    });
  }

  void _removeAssignment(int index) {
    setState(() => _assignments.removeAt(index));
  }

  String _schoolName(String schoolId) {
    for (final school in _schools) {
      if (school.id == schoolId) return school.name;
    }
    return 'Escola selecionada';
  }

  String? _validatePassword(String value) {
    if (value.length < 8) {
      return 'A senha deve ter no minimo 8 caracteres.';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'A senha deve conter pelo menos uma letra.';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'A senha deve conter pelo menos um numero.';
    }
    return null;
  }

  Future<void> _createTeacher() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    if (_assignments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos uma turma.')),
      );
      return;
    }
    final primaryAssignment = _assignments.first;

    // O convite autoriza apenas UMA escola. Todas as turmas adicionadas
    // precisam pertencer a ela — caso contrário, o educador poderia usar um
    // convite de uma escola para se vincular a turmas de outra.
    final hasOtherSchool = _assignments.any((a) => a.schoolId != primaryAssignment.schoolId);
    if (hasOtherSchool) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todas as turmas devem ser da mesma escola do convite.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final userService = UserService();
      final normalizedUsername = userService.normalizeUsername(_usernameController.text);

      final usernameError = userService.validateUsername(normalizedUsername);
      if (usernameError != null) {
        throw ArgumentError(usernameError);
      }

      final user = User(
        username: normalizedUsername,
        password: PasswordService.hashPassword(_passwordController.text),
        fullName: _fullNameController.text.trim(),
        schoolId: primaryAssignment.schoolId,
        grade: primaryAssignment.grade,
        classGroup: primaryAssignment.classGroup,
        role: 'teacher',
      );

      final assignments = _assignments
          .map(
            (assignment) => TeacherAssignment(
              teacherId: 0, // preenchido pelo AppDatabase dentro da transação
              schoolId: assignment.schoolId,
              grade: assignment.grade,
              classGroup: assignment.classGroup,
              shift: assignment.shift,
              schedule: assignment.schedule.isEmpty ? null : assignment.schedule,
            ),
          )
          .toList();

      // Correção P0-03: cria a conta e consome o convite em uma única
      // operação atômica. Sem um código válido para a escola selecionada,
      // nenhuma conta é criada.
      final created = await AppDatabase.instance.createTeacherFromInvite(
        inviteCode: _inviteCodeController.text,
        teacher: user,
        assignments: assignments,
      );
      userService.addUserFromDb(created);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ArgumentError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message.toString())),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel criar a conta do educador.')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Primeiro acesso do educador',
        showProfileAvatar: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Crie sua conta e informe as turmas que você atende.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _inviteCodeController,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Código de convite',
                      helperText: 'Fornecido pela coordenação/escola. Uso único.',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o código de convite fornecido pela escola.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSchoolId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Escola',
                      border: OutlineInputBorder(),
                    ),
                    items: _schools
                        .map(
                          (school) => DropdownMenuItem<String>(
                            value: school.id,
                            child: Text(school.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    selectedItemBuilder: (context) => _schools
                        .map(
                          (school) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              school.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _selectedSchoolId = value),
                    validator: (_) => _selectedSchoolId == null ? 'Selecione a escola.' : null,
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 380;
                      final gradeField = DropdownButtonFormField<String>(
                        initialValue: _selectedGrade,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Série',
                          border: OutlineInputBorder(),
                        ),
                        items: _grades
                            .map((grade) => DropdownMenuItem(value: grade, child: Text(grade, maxLines: 1)))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedGrade = value),
                        validator: (_) => _selectedGrade == null ? 'Selecione a série.' : null,
                      );
                      final shiftField = DropdownButtonFormField<String>(
                        initialValue: _selectedShift,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Turno',
                          border: OutlineInputBorder(),
                        ),
                        items: _shifts
                            .map((shift) => DropdownMenuItem(value: shift, child: Text(shift, maxLines: 1)))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedShift = value),
                        validator: (_) => _selectedShift == null ? 'Selecione o turno.' : null,
                      );

                      if (isCompact) {
                        return Column(
                          children: [
                            gradeField,
                            const SizedBox(height: 14),
                            shiftField,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: gradeField),
                          const SizedBox(width: 12),
                          Expanded(child: shiftField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _classGroupController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Turma',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _scheduleController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Horário (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _addAssignment,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar turma'),
                  ),
                  if (_assignments.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ..._assignments.asMap().entries.map(
                          (entry) => Card(
                            child: ListTile(
                              dense: true,
                              title: Text('${entry.value.grade} - Turma ${entry.value.classGroup}'),
                              subtitle: Text(
                                '${_schoolName(entry.value.schoolId)} • ${entry.value.shift}'
                                '${entry.value.schedule.isEmpty ? '' : ' • ${entry.value.schedule}'}',
                              ),
                              trailing: IconButton(
                                tooltip: 'Remover turma',
                                onPressed: () => _removeAssignment(entry.key),
                                icon: const Icon(Icons.close),
                              ),
                            ),
                          ),
                        ),
                  ],
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _fullNameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nome completo',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o nome do educador.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nome de usuario',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe um nome de usuario.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      ),
                    ),
                    validator: (value) {
                      final v = value ?? '';
                      if (v.isEmpty) {
                        return 'Informe uma senha.';
                      }
                      return _validatePassword(v);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Confirmar senha',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _obscureConfirm = !_obscureConfirm);
                        },
                        icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                      ),
                    ),
                    validator: (value) {
                      if ((value ?? '').isEmpty) {
                        return 'Confirme a senha.';
                      }
                      if (value != _passwordController.text) {
                        return 'As senhas nao conferem.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saving ? null : _createTeacher,
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Criar conta do educador'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TeacherAssignmentDraft {
  final String schoolId;
  final String grade;
  final String classGroup;
  final String shift;
  final String schedule;

  const _TeacherAssignmentDraft({
    required this.schoolId,
    required this.grade,
    required this.classGroup,
    required this.shift,
    required this.schedule,
  });
}
