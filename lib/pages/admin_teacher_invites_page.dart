import 'package:flutter/material.dart';

import '../models/teacher_invite_model.dart';
import '../school_service.dart';
import '../services/teacher_invite_service.dart';
import '../services/user_service.dart';
import '../widgets/app_bar.dart';

/// Tela restrita a administradores para emitir convites de uso único de
/// educador (P0-03). Sem um código gerado aqui, ninguém consegue criar uma
/// conta de educador em `TeacherSetupPage`.
class AdminTeacherInvitesPage extends StatefulWidget {
  const AdminTeacherInvitesPage({super.key});

  @override
  State<AdminTeacherInvitesPage> createState() => _AdminTeacherInvitesPageState();
}

class _AdminTeacherInvitesPageState extends State<AdminTeacherInvitesPage> {
  final _schools = SchoolService().getAllSchools();
  final _inviteService = TeacherInviteService();
  String? _selectedSchoolId;
  bool _issuing = false;
  List<TeacherInvite> _invites = [];
  bool _loadingList = false;

  @override
  void initState() {
    super.initState();
    if (_schools.isNotEmpty) {
      _selectedSchoolId = _schools.first.id;
      _loadInvites();
    }
  }

  Future<void> _loadInvites() async {
    if (_selectedSchoolId == null) return;
    setState(() => _loadingList = true);
    final invites = await _inviteService.listInvites(schoolId: _selectedSchoolId);
    if (!mounted) return;
    setState(() {
      _invites = invites;
      _loadingList = false;
    });
  }

  Future<void> _issueInvite() async {
    final schoolId = _selectedSchoolId;
    if (schoolId == null) return;

    setState(() => _issuing = true);
    try {
      final admin = UserService().currentUser;
      final invite = await _inviteService.issueInvite(
        schoolId: schoolId,
        createdByUsername: admin?.username,
      );
      if (!mounted) return;
      await _loadInvites();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Convite gerado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Repasse este código ao educador. Ele vale por 14 dias e só pode ser usado uma vez:'),
              const SizedBox(height: 12),
              SelectableText(
                invite.code,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível gerar o convite. Tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => _issuing = false);
    }
  }

  String _schoolName(String schoolId) {
    for (final school in _schools) {
      if (school.id == schoolId) return school.name;
    }
    return schoolId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Convites de educador', showProfileAvatar: false),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Cada convite autoriza a criação de UMA conta de educador para a escola escolhida. '
              'Depois de usado (ou vencido), o código deixa de funcionar.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedSchoolId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Escola',
                border: OutlineInputBorder(),
              ),
              items: _schools
                  .map((school) => DropdownMenuItem(value: school.id, child: Text(school.name, maxLines: 1, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedSchoolId = value);
                _loadInvites();
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _issuing ? null : _issueInvite,
              icon: _issuing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add_moderator_outlined),
              label: const Text('Gerar novo convite'),
            ),
            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text('Convites desta escola', style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            Expanded(
              child: _loadingList
                  ? const Center(child: CircularProgressIndicator())
                  : _invites.isEmpty
                      ? const Center(child: Text('Nenhum convite gerado ainda.'))
                      : ListView.builder(
                          itemCount: _invites.length,
                          itemBuilder: (context, index) {
                            final invite = _invites[index];
                            final now = DateTime.now();
                            final status = invite.isUsed
                                ? 'Usado'
                                : invite.isExpiredAt(now)
                                    ? 'Expirado'
                                    : 'Ativo';
                            return ListTile(
                              title: Text(invite.code),
                              subtitle: Text('${_schoolName(invite.schoolId)} • válido até ${invite.expiresAt.day}/${invite.expiresAt.month}/${invite.expiresAt.year}'),
                              trailing: Chip(label: Text(status)),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
