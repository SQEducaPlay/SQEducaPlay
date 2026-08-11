import 'package:flutter/material.dart';
import '../school_service.dart';
import '../school_model.dart';
import '../services/class_group_service.dart';
import '../widgets/app_bar.dart';

class ManageClassGroupsPage extends StatefulWidget {
  const ManageClassGroupsPage({super.key});

  @override
  State<ManageClassGroupsPage> createState() => _ManageClassGroupsPageState();
}

class _ManageClassGroupsPageState extends State<ManageClassGroupsPage> {
  final _schoolService = SchoolService();
  final _classService = ClassGroupService();

  School? _selectedSchool;
  String? _selectedSerie;
  final _series = const ['2º Ano', '3º Ano', '4º Ano', '5º Ano'];
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final schools = _schoolService.getAllSchools();
    final groups = (_selectedSchool != null && _selectedSerie != null)
        ? _classService.getBySchoolAndGrade(_selectedSchool!.id, _selectedSerie!)
        : _classService.getAll();

    return Scaffold(
      appBar: AppTopBar(title: 'Gerenciar Turmas'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<School>(
                    isExpanded: true,
                    initialValue: _selectedSchool,
                    decoration: const InputDecoration(
                      labelText: 'Escola',
                      border: OutlineInputBorder(),
                    ),
                    items: schools
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedSchool = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedSerie,
                    decoration: const InputDecoration(
                      labelText: 'Série',
                      border: OutlineInputBorder(),
                    ),
                    items: _series
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedSerie = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nova turma (ex.: 5ºA)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: (_selectedSchool == null || _selectedSerie == null || _nameController.text.trim().isEmpty)
                      ? null
                      : () {
                          final id = '${_selectedSchool!.id}-${_selectedSerie!}-${_nameController.text.trim()}';
                          _classService.add(ClassGroup(
                            id: id,
                            name: _nameController.text.trim(),
                            schoolId: _selectedSchool!.id,
                            grade: _selectedSerie!,
                          ));
                          setState(() {});
                          _nameController.clear();
                        },
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final g = groups[index];
                  final school = _schoolService.getSchoolById(g.schoolId);
                  return Card(
                    child: ListTile(
                      title: Text(g.name),
                      subtitle: Text('${g.grade} • ${school?.name ?? g.schoolId}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _classService.remove(g.id);
                          setState(() {});
                        },
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
