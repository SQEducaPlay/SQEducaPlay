import 'package:flutter/material.dart';
import 'user_model.dart';
import 'user_service.dart';
import 'school_model.dart';
import 'school_service.dart';
import 'services/class_group_service.dart';
import 'database/app_database.dart';
import 'package:sqeducaplay/models/user_model.dart' as db_model;
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/logger.dart';
import 'widgets/app_bar.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _classGroupController = TextEditingController();
  final _userService = UserService();
  final _schoolService = SchoolService();
  final _classService = ClassGroupService();
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;

  final List<String> _series = ['2º Ano', '3º Ano', '4º Ano', '5º Ano'];
  String? _selectedSerie;
  School? _selectedSchool;
  String? _selectedClassGroupId; // quando admin cadastrou turmas

  String _canonicalGrade(String? grade) {
    final value = grade?.trim();
    if (value == null || value.isEmpty) return '2º Ano Fundamental';
    if (value.endsWith('Fundamental')) return value;
    return '$value Fundamental';
  }

  @override
  void initState() {
    super.initState();
    _selectedSerie = _series.first;
    // Não pré-seleciona escola para forçar o aluno a informar
    _selectedSchool = null;
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        final newUser = User(
          username: _usernameController.text,
          password: _passwordController.text,
          fullName: _fullNameController.text,
          nickname: _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim(),
          profilePhotoPath: _pickedImage?.path,
          grade: _canonicalGrade(_selectedSerie),
          classGroup: _resolveClassGroupName(),
          schoolId: _selectedSchool?.id,
        );
        _userService.register(newUser);

        // Também criar usuário no banco (AppDatabase) e persistir série em SharedPreferences
        try {
          // Buscar por username no DB (case-insensitive)
          final existing = await AppDatabase.instance.getUserByUsername(_usernameController.text);
          late db_model.User created;
          if (existing == null) {
            created = await AppDatabase.instance.createUser(db_model.User(
              username: _usernameController.text,
              password: _passwordController.text,
              fullName: _fullNameController.text.trim(),
              nickname: _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim(),
              grade: _canonicalGrade(_selectedSerie),
              classGroup: _resolveClassGroupName(),
              schoolId: _selectedSchool?.id,
              profilePhotoPath: _pickedImage?.path,
              role: 'student',
            ));
            Logger.d('Usuário criado no DB com ID: ${created.id}');
          } else {
            created = existing;
            Logger.d('Usuário já existente no DB: ${existing.username} (ID: ${existing.id})');
          }

          // Salvar prefs para fluxo de login
          try {
            final prefs = await SharedPreferences.getInstance();
            if (created.id != null) await prefs.setInt('usuario_id', created.id!);
            await prefs.setString('usuario_nome', created.username);
            if (created.grade != null) await prefs.setString('usuario_grade', _canonicalGrade(created.grade));
          } catch (e) {
            Logger.d('Erro ao salvar SharedPreferences após cadastro: $e');
          }
        } catch (e) {
          Logger.d('Erro ao criar usuário no banco: $e');
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário cadastrado com sucesso!')),
        );

        Navigator.of(context).pop(); // Volta para a tela de login
      } on ArgumentError catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message.toString())),
        );
      }
    }
  }

  String? _resolveClassGroupName() {
    // Se há seleção de turma cadastrada, usa o nome; senão usa o texto livre, se existir
    if (_selectedClassGroupId != null) {
      final all = _classService.getAll();
      final found = all.firstWhere(
        (g) => g.id == _selectedClassGroupId,
        orElse: () => ClassGroup(id: '', name: '', schoolId: '', grade: ''),
      );
      return found.name.isNotEmpty ? found.name : null;
    }
    return _classGroupController.text.trim().isEmpty ? null : _classGroupController.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    final schools = _schoolService.getAllSchools();
    final availableGroups = (_selectedSchool != null && _selectedSerie != null)
        ? _classService.getBySchoolAndGrade(_selectedSchool!.id, _selectedSerie!)
        : const <ClassGroup>[];
    
    return Scaffold(
      appBar: AppTopBar(
        title: 'Cadastrar Novo Usuário',
        showProfileAvatar: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width > 600 ? 80.0 : 20.0,
              vertical: 24.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    final XFile? img = await _picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 800,
                    );
                    if (img != null) setState(() => _pickedImage = img);
                  },
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.blue.shade50,
                    child: _pickedImage == null
                        ? const Icon(Icons.person, size: 48, color: Colors.blue)
                        : ClipOval(
                            child: Image.file(
                              File(_pickedImage!.path),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final XFile? img = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
                        if (img != null) setState(() => _pickedImage = img);
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galeria'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () async {
                        final XFile? img = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1200);
                        if (img != null) setState(() => _pickedImage = img);
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Câmera'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Informe seu nome completo.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    labelText: 'Como você quer aparecer? (apelido opcional)',
                    helperText: 'Se não informar, usaremos seu primeiro nome e a inicial do sobrenome.',
                    prefixIcon: Icon(Icons.tag_faces),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (availableGroups.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _selectedClassGroupId,
                    decoration: const InputDecoration(
                      labelText: 'Turma (selecione)',
                      prefixIcon: Icon(Icons.class_),
                      border: OutlineInputBorder(),
                    ),
                    items: availableGroups
                        .map((g) => DropdownMenuItem(
                              value: g.id,
                              child: Text(g.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedClassGroupId = v),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _classGroupController,
                    decoration: const InputDecoration(
                      labelText: 'Turma (ex.: 5ºA) - opcional',
                      prefixIcon: Icon(Icons.class_),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome de Usuário',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    final text = value ?? '';
                    final normalized = _userService.normalizeUsername(text);
                    final msg = _userService.validateUsername(normalized);
                    if (msg != null) return msg;
                    if (_userService.existsUsername(normalized)) {
                      return 'Este nome de usuário já está em uso.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) => (value == null || value.isEmpty) ? 'Por favor, insira uma senha.' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSerie,
                  decoration: const InputDecoration(
                    labelText: 'Série',
                    prefixIcon: Icon(Icons.class_),
                    border: OutlineInputBorder(),
                  ),
                  items: _series.map((String serie) {
                    return DropdownMenuItem<String>(
                      value: serie,
                      child: Text(serie),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedSerie = newValue;
                      _selectedClassGroupId = null; // reset turma quando série muda
                    });
                  },
                  validator: (value) => (value == null) ? 'Por favor, selecione uma série.' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<School>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Escola',
                    prefixIcon: const Icon(Icons.account_balance),
                    border: const OutlineInputBorder(),
                    helperText: schools.isEmpty
                        ? 'Nenhuma escola cadastrada. Procure o administrador.'
                        : 'Selecione a escola onde você estuda',
                  ),
                  items: schools.map((School school) {
                    return DropdownMenuItem<School>(
                      value: school,
                      child: Text(
                        school.city != null ? '${school.name} - ${school.city}' : school.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: schools.isEmpty
                      ? null
                      : (newValue) {
                          setState(() {
                            _selectedSchool = newValue;
                            _selectedClassGroupId = null; // reset turma quando escola muda
                          });
                        },
                  validator: (value) => (value == null) ? 'Por favor, selecione uma escola.' : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: schools.isEmpty ? null : _register,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Cadastrar'),
                ),
                const SizedBox(height: 20),
              ],
            ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}