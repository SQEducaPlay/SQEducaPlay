/// Configuracao publica do cliente Supabase.
///
/// A publishable key pode existir no aplicativo cliente; a service-role key
/// nunca deve ser empacotada no Flutter. RLS continua sendo obrigatorio.
abstract final class BackendConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const isRequired = bool.fromEnvironment(
    'BACKEND_REQUIRED',
    defaultValue: false,
  );

  static bool get isConfigured =>
      supabaseUrl.trim().isNotEmpty && supabasePublishableKey.trim().isNotEmpty;
}
