import 'backend_service.dart';

abstract final class InstitutionalProvisioningService {
  static Future<void> createUser({
    required String role,
    required String schoolCode,
    required String loginAlias,
    required String displayName,
    required String password,
    String? email,
    String? classroomId,
    String? consentStatus,
    String? lawfulBasis,
    String? evidenceReference,
  }) async {
    final backend = BackendService.instance;
    if (!backend.isInitialized || backend.client.auth.currentUser == null) {
      throw StateError('Sessao administrativa indisponivel.');
    }
    final response = await backend.client.functions.invoke(
      'provision-school-user',
      body: {
        'role': role,
        'schoolCode': schoolCode,
        'loginAlias': loginAlias,
        'displayName': displayName,
        'password': password,
        'email': ?email,
        'classroomId': ?classroomId,
        if (role == 'student') ...{
          'policyVersion': '2026-08-25-pilot',
          'consentStatus': consentStatus,
          'lawfulBasis': lawfulBasis,
          'evidenceReference': evidenceReference,
        },
      },
    );
    if (response.status < 200 || response.status >= 300) {
      throw StateError(
        'O servidor recusou o cadastro. Confira os dados e permissoes.',
      );
    }
  }
}
