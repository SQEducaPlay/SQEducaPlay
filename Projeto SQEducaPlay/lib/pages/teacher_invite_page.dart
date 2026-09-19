import 'package:flutter/material.dart';

import '../school_model.dart';
import '../school_service.dart';
import '../services/teacher_invite_service.dart';
import '../widgets/app_bar.dart';

class TeacherInvitePage extends StatefulWidget {
  final String username;
  final String? initialSchoolId;

  const TeacherInvitePage({
    super.key,
    required this.username,
    this.initialSchoolId,
  });

  @override
  State<TeacherInvitePage> createState() => _TeacherInvitePageState();
}

class _TeacherInvitePageState extends State<TeacherInvitePage> {
  final _schoolService = SchoolService();
  final _inviteService = TeacherInviteService();
  late final List<School> _schools;
  String? _schoolId;
  bool _loading = false;
  String? _generatedCode;
  DateTime? _expiresAt;

  @override
  void initState() {
    super.initState();
    _schools = _schoolService.getAllSchools();
    _schoolId = _schools.any((school) => school.id == widget.initialSchoolId)
        ? widget.initialSchoolId
        : (_schools.isNotEmpty ? _schools.first.id : null);
  }

  Future<void> _generateInvite() async {
    final schoolId = _schoolId;
    if (schoolId == null) return;
    setState(() => _loading = true);
    try {
      final invite = await _inviteService.issueInvite(
        schoolId: schoolId,
        createdByUsername: widget.username,
      );
      if (!mounted) return;
      setState(() {
        _generatedCode = invite.code;
        _expiresAt = invite.expiresAt;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível gerar o convite: $error')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    School? selectedSchool;
    for (final school in _schools) {
      if (school.id == _schoolId) {
        selectedSchool = school;
        break;
      }
    }
    return Scaffold(
      appBar: AppTopBar(title: 'Convite de educador'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Gere um código de uso único para um educador entrar na escola selecionada.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _schoolId,
            decoration: const InputDecoration(
              labelText: 'Escola vinculada',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.school_outlined),
            ),
            items: _schools
                .map(
                  (school) => DropdownMenuItem(
                    value: school.id,
                    child: Text(school.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: _loading ? null : (value) => setState(() => _schoolId = value),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading || _schools.isEmpty ? null : _generateInvite,
            icon: const Icon(Icons.add_link),
            label: Text(_loading ? 'Gerando...' : 'Gerar convite'),
          ),
          if (selectedSchool != null && _generatedCode != null) ...[
            const SizedBox(height: 28),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.verified_outlined, color: Colors.green, size: 40),
                    const SizedBox(height: 8),
                    const Text(
                      'Convite gerado',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _generatedCode!,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Escola: ${selectedSchool.name}', textAlign: TextAlign.center),
                    Text('Válido até ${_formatDate(_expiresAt!)}'),
                    const SizedBox(height: 8),
                    const Text(
                      'Compartilhe este código apenas com o educador. Ele poderá ser usado uma única vez.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_schools.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Text('Cadastre uma escola antes de gerar convites.'),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
