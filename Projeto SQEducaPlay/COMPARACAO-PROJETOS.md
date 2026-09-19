# Diff do meu projeto SQEducaPlay: versão antiga x versão atual

Este documento mostra o trabalho realizado no meu projeto
`douglasmaycon120-lgtm/Projet-SQEducaPlay`. O diff foi calculado comparando o
estado antigo do projeto (`c585150`) com a versão atual (`229ff68`), em
18/09/2026. Assim, o documento não compara o projeto do Keinan e não usa o
primeiro commit como base; ele mostra somente as alterações feitas depois da
versão antiga escolhida.

O projeto `SQEducaPlay/SQEducaPlay`, atualizado pelo Keinan, não foi alterado.
Ele foi consultado separadamente apenas para esclarecer que existem duas
evoluções independentes.

## Contexto do repositório compartilhado

O repositório `SQEducaPlay/SQEducaPlay` é privado, está na branch `main` e lista
cinco colaboradores: KeinanSZ (administrador), LaisBordallo (professora, com
permissão de escrita), LeoBravoDev, douglasmaycon120-lgtm e
vanessabarbosaaa-rgb. Todos fazem parte do grupo.

Na `main` do repositório compartilhado, o histórico consultado registra commits
do Keinan. Isso explica por que a versão disponível nesse repositório aparece
mais atualizada, mesmo havendo outros colaboradores listados. A lista de
colaboradores não deve ser confundida com a autoria de cada alteração: o diff
deste documento registra somente o trabalho feito no meu repositório
`douglasmaycon120-lgtm/Projet-SQEducaPlay`.

## Resumo técnico do diff

- **18 arquivos** de código, configuração e testes alterados ou adicionados;
- **928 linhas adicionadas**;
- **43 linhas removidas**;
- **2 commits** realizados no período de evolução comparado;
- o banco de perguntas não faz parte deste diff específico;
- foram adicionados testes automatizados em `test/`.

## Commits que registram meu trabalho

| Commit | Alteração |
|---|---|
| `c09c23d` | Atualização de autenticação e fluxos do aplicativo |
| `229ff68` | Adição de convites seguros para professores |

## Principais alterações realizadas

### Quiz e conteúdo

- O banco de perguntas e o fluxo principal do jogo permanecem fora deste diff;
- o foco desta etapa foi autenticação, segurança, aprovação, privacidade e
  convites de professores.

### Acesso e autenticação

- criação da tela de escolha entre acesso de aluno e professor;
- melhorias no login e no cadastro;
- senhas novas protegidas com bcrypt;
- compatibilidade e migração de senhas antigas;
- remoção do armazenamento da senha nas preferências locais;
- separação do fluxo de primeiro acesso do professor.

### Aprovação e controle de professores

- cadastro de aluno com aprovação pendente;
- bloqueio de aluno ainda não aprovado;
- aprovação de alunos pelo professor;
- convite de professor com código aleatório;
- convite associado à escola;
- expiração e uso único do convite;
- validação contra escola incorreta e convite já utilizado.

### Privacidade e dados

- registro da data e versão do consentimento;
- exportação dos dados sem incluir senha;
- exclusão dos dados com confirmação explícita;
- migração do banco SQLite para suportar os novos campos e convites.

### Testes

Foram adicionados testes para:

- criação e validação de hash bcrypt;
- serialização de consentimento e aprovação;
- ausência de senha na exportação pública;
- formato, expiração, escola vinculada e uso único dos convites.

Arquivos de teste adicionados:

- `test/password_utils_test.dart`;
- `test/user_model_test.dart`;
- `test/teacher_invite_test.dart`.

## Arquivos mais relevantes do diff

### Adicionados

- `lib/access_choice_page.dart`;
- `lib/models/teacher_invite_model.dart`;
- `lib/services/teacher_invite_service.dart`;
- `lib/teacher_setup_page.dart`;
- `lib/utils/password_utils.dart`;
- arquivos de teste em `test/`.

### Modificados

- `lib/main.dart`;
- `lib/login_page.dart`;
- `lib/register_page.dart`;
- `lib/database/app_database.dart`;
- modelos e serviços de usuário;
- perfil do professor;
- configurações de privacidade;
- `pubspec.yaml` e `pubspec.lock`.

## Validação

Depois das alterações:

- `flutter analyze`: aprovado;
- `flutter test`: **7 testes aprovados**;
- `flutter build web --release`: concluído com sucesso.

## Conclusão

Este é o diff do trabalho desenvolvido no meu repositório. Ele mostra as
alterações que fiz desde a versão antiga `c585150`, incluindo autenticação,
aprovação de alunos, consentimento, privacidade, convites de professores e
testes. O banco de perguntas não foi incluído nesta comparação porque não
mudou entre a versão antiga escolhida e a atual.

O projeto atualizado pelo Keinan é uma linha de evolução separada e não foi
misturado a este diff.
