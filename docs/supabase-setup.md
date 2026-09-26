# Configuracao segura do Supabase

O projeto SQEducaPlay tem dependencias e inicializacao opcionais do Supabase,
mas a aplicacao ainda usa os fluxos locais de cadastro e login. Esta migracao
cria a base remota com isolamento por Row Level Security (RLS); ela nao migra
contas/dados locais nem ativa a autenticacao remota no app.

## Aplicar as migracoes

1. Abra o projeto no painel Supabase e entre em **SQL Editor**.
2. Execute somente uma vez a migracao inicial:
   `supabase/migrations/20260926160000_initial_secure_schema.sql`.
3. Depois execute a migracao incremental:
   `supabase/migrations/20260926170000_guardian_online_flows.sql`.
4. Para cada arquivo, copie todo o conteudo para uma consulta nova no SQL
   Editor e execute. Nao execute novamente uma migracao que ja terminou sem
   erros: `CREATE TABLE` inicial nao e idempotente.
5. Se a migracao inicial ja foi executada com sucesso, execute apenas a
   migracao incremental.

O esquema cria contas autenticadas como responsaveis por padrao. Um responsavel
pode ter varios perfis de aluno ligados a mesma conta. Educadores so podem
consultar alunos de turmas nas quais tenham uma associacao ativa; administradores
de projeto podem gerenciar o cadastro institucional.

## Criar o primeiro administrador

1. Primeiro crie uma conta de responsavel pelo fluxo de autenticacao do
   Supabase (quando a interface do app estiver conectada) ou em **Authentication
   > Users** no painel.
2. Copie o UUID dessa conta.
3. No SQL Editor do Supabase, execute, substituindo o UUID:

   ```sql
   update public.profiles
   set role = 'admin'
   where id = 'UUID-DA-CONTA';
   ```

Alteracoes de papel por usuarios autenticados sao bloqueadas no banco. A
promocao inicial deve ser feita apenas no SQL Editor da organizacao/projeto.

## Credenciais do cliente e builds

- `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY` sao configuracoes publicas do
  cliente. O app ja le esses valores por `--dart-define`.
- Nunca inclua `sb_secret_*`, `service_role` ou a senha do banco no Flutter,
  no site, em variaveis Dart ou no repositorio.
- A chave publicavel nao substitui RLS. Todas as tabelas com dados de usuario
  devem permanecer com RLS habilitado.
- Para builds locais:

  ```powershell
  flutter run --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=SUA_CHAVE_PUBLICAVEL
  ```

- O workflow de GitHub Actions ainda precisa receber a URL e a chave
  publicavel como variaveis do repositorio antes de gerar builds conectados:
  **Settings > Secrets and variables > Actions > Variables**:
  `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY`. Sao valores publicos; nao crie
  variaveis nem secrets para `sb_secret_*` ou `service_role`.
- Publique a funcao de exclusao de conta com a Supabase CLI depois de vincular
  o projeto: `supabase functions deploy delete-account`. A chave
  `SUPABASE_SERVICE_ROLE_KEY` fica somente no ambiente gerenciado da Edge
  Function e nunca no app ou em variaveis do GitHub Actions.

## Limites atuais e proxima etapa

As telas online usam autenticacao por e-mail do responsavel, criacao de varios
perfis, sincronizacao de quizzes com fila local de reenvio e importacao do
historico remoto. O acesso online de educadores e o provisionamento institucional
ainda precisam ser concluidos. Contas antigas locais nao sao enviadas
automaticamente; devem ser vinculadas e importadas com revisao do responsavel.
Use somente dados ficticios ate concluir a validacao e a revisao institucional.

RLS protege o acesso aos registros; nao e criptografia ponta a ponta. O
Supabase usa HTTPS e criptografia de infraestrutura, mas pontuacoes enviadas
pelo cliente ainda nao devem ser consideradas prova inviolavel de desempenho.
