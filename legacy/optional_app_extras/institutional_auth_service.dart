import '../database/app_database.dart';
import '../models/user_model.dart';
import 'backend_service.dart';
import 'user_service.dart';

class InstitutionalAuthException implements Exception {
  const InstitutionalAuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract final class InstitutionalAuthService {
  static String studentEmail(String schoolCode, String alias) {
    final normalizedSchool = schoolCode.trim().toLowerCase();
    final normalizedAlias = alias.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9-]{4,32}$').hasMatch(normalizedSchool) ||
        !RegExp(r'^[a-z0-9._-]{3,40}$').hasMatch(normalizedAlias)) {
      throw const InstitutionalAuthException(
        'Confira o codigo da escola e o usuario fornecido pela escola.',
      );
    }
    return '$normalizedSchool.$normalizedAlias@students.sqeducaplay.invalid';
  }

  static Future<User> signIn({
    required bool teacher,
    required String identifier,
    required String password,
    String? schoolCode,
  }) async {
    final backend = BackendService.instance;
    if (!backend.isInitialized) {
      throw const InstitutionalAuthException(
        'Backend institucional indisponivel.',
      );
    }

    final email = teacher
        ? identifier.trim().toLowerCase()
        : studentEmail(schoolCode ?? '', identifier);
    final response = await backend.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final authUser = response.user;
    if (authUser == null) {
      throw const InstitutionalAuthException('Usuario ou senha invalidos.');
    }

    Map<String, dynamic>? membership;
    String? appRole;
    if (teacher) {
      final schoolMemberships = await backend.client
          .from('school_memberships')
          .select('role, login_alias, schools!inner(id, code, legacy_id)')
          .eq('user_id', authUser.id)
          .inFilter('role', ['teacher', 'school_admin'])
          .eq('status', 'active')
          .limit(1);
      if (schoolMemberships.isNotEmpty) {
        membership = schoolMemberships.first;
        appRole = membership['role'] == 'teacher' ? 'teacher' : 'admin';
      } else {
        final orgMemberships = await backend.client
            .from('organization_memberships')
            .select('role')
            .eq('user_id', authUser.id)
            .eq('role', 'org_admin')
            .eq('status', 'active')
            .limit(1);
        if (orgMemberships.isNotEmpty) appRole = 'admin';
      }
    } else {
      final studentMemberships = await backend.client
          .from('school_memberships')
          .select('role, login_alias, schools!inner(id, code, legacy_id)')
          .eq('user_id', authUser.id)
          .eq('role', 'student')
          .eq('status', 'active')
          .limit(1);
      if (studentMemberships.isNotEmpty) {
        membership = studentMemberships.first;
        appRole = 'student';
      }
    }
    if (appRole == null) {
      await backend.client.auth.signOut();
      throw const InstitutionalAuthException(
        'Conta sem vinculo ativo para este tipo de acesso.',
      );
    }

    final profile = await backend.client
        .from('profiles')
        .select('display_name')
        .eq('id', authUser.id)
        .single();
    final school = membership?['schools'] as Map<String, dynamic>?;
    String? grade;
    String? classGroup;
    if (!teacher) {
      final enrollment = await backend.client
          .from('student_enrollments')
          .select('classrooms!inner(grade, name)')
          .eq('student_id', authUser.id)
          .eq('active', true)
          .limit(1)
          .maybeSingle();
      final classroom = enrollment?['classrooms'] as Map<String, dynamic>?;
      final gradeNumber = classroom?['grade'] as int?;
      if (gradeNumber != null) grade = '$gradeNumberº Ano Fundamental';
      classGroup = classroom?['name'] as String?;
    }

    final username = (membership?['login_alias'] as String?) ?? email;
    final remoteProfile = User(
      username: username,
      // Nao armazenamos a credencial institucional. createUser transformara
      // este identificador nao secreto em hash para o perfil offline.
      password: 'remote-session-${authUser.id}',
      fullName: profile['display_name'] as String,
      grade: grade,
      classGroup: classGroup,
      schoolId: school == null
          ? null
          : (school['legacy_id'] as String?) ?? school['code'] as String,
      role: appRole,
    );

    final existing = await AppDatabase.instance.getUserByUsername(username);
    final localProfile = existing == null
        ? await AppDatabase.instance.createUser(remoteProfile)
        : existing.copy(
            fullName: remoteProfile.fullName,
            grade: remoteProfile.grade,
            classGroup: remoteProfile.classGroup,
            schoolId: remoteProfile.schoolId,
            role: remoteProfile.role,
          );
    if (existing != null) await AppDatabase.instance.updateUser(localProfile);
    UserService().addUserFromDb(localProfile);
    return localProfile;
  }
}
