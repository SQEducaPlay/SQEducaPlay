# Configuracao segura do Supabase

O SQEducaPlay usa o Supabase para contas familiares, perfis de aluno, convites
institucionais, turmas e sincronizacao de quizzes. O SQLite continua como fila
local/offline. Historicos locais antigos so sao enviados quando o responsavel
seleciona a conta local, confirma a senha e autoriza a importacao.

## Aplicar as migracoes

1. Abra o projeto no painel Supabase e entre em **SQL Editor**.
2. Execute somente uma vez a migracao inicial:
   `supabase/migrations/20260926160000_initial_secure_schema.sql`.
3. Depois execute a migracao incremental:
   `supabase/migrations/20260926170000_guardian_online_flows.sql`.
4. Por fim, execute a migracao incremental:
   `supabase/migrations/20260926180000_online_school_access.sql`.
5. Para cada arquivo, copie todo o conteudo para uma consulta nova no SQL
   Editor e execute. Nao execute novamente uma migracao que ja terminou sem
   erros: `CREATE TABLE` inicial nao e idempotente.
6. Se as migracoes `20260926160000` e `20260926170000` ja foram executadas,
   execute somente a nova `20260926180000_online_school_access.sql`.

O esquema cria contas autenticadas como responsaveis por padrao. Um responsavel
pode ter varios perfis e pode solicitar matricula em uma escola ativa; o perfil
fica pendente ate a escola aprovar e escolher uma turma. Educadores precisam de
convite individual, vinculado ao e-mail, e so acessam alunos matriculados nas
escolas autorizadas. Administradores podem cadastrar escolas e administradores
escolares; estes podem gerenciar turmas e convidar educadores da propria escola.

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

## Primeiro acesso institucional

1. Entre no app com a conta que recebeu papel `admin`.
2. Abra **Educador (online)** e cadastre a escola.
3. Opcionalmente, cadastre uma conta de administrador escolar e autorize-a para
   essa escola.
4. Cadastre as turmas e gere um convite para cada educador usando o e-mail que
   ele usara no app. O codigo aparece uma unica vez; encaminhe-o em canal
   apropriado. Ele expira em 14 dias e so pode ser usado uma vez.
5. O educador cria a conta com esse e-mail e o codigo. O acesso fica limitado a
   escola do convite.
6. O responsavel pode escolher a escola ao criar um perfil. A escola ve o
   pedido pendente e precisa matricular o perfil em uma turma antes do acesso
   institucional.

Use perfis ficticios para validar o fluxo. A aprovacao na interface nao
substitui a revisao institucional do aviso de privacidade, base legal,
retencao e procedimentos para dados de criancas.

## Dados locais e limites de seguranca

Contas locais antigas nao sao convertidas automaticamente. Para um perfil
online, a importacao do historico e opcional e exige confirmacao explicita do
responsavel no aparelho de origem. SQLite permanece para uso offline e fila de
reenvio; os quizzes associados a um perfil online sincronizam apos conexao.

RLS protege o acesso aos registros; nao e criptografia ponta a ponta. O
Supabase usa HTTPS e criptografia de infraestrutura, mas pontuacoes enviadas
pelo cliente ainda nao devem ser consideradas prova inviolavel de desempenho.
