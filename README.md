# SQEducaPlay

<div align="center">

<img src="assets/images/logo_full.png" alt="Logo SQEducaPlay" width="420" />

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Web](https://img.shields.io/badge/web-online-brightgreen)
![Status](https://img.shields.io/badge/status-em%20desenvolvimento-orange)

</div>

Aplicativo educacional gamificado desenvolvido para apoiar o aprendizado de estudantes do Ensino Fundamental I, com foco em Português e Matemática alinhados à BNCC.

## Entrega acadêmica

### Integrantes do grupo

- Vanessa Barbosa — [@vanessabarbosaaa-rgb](https://github.com/vanessabarbosaaa-rgb)
- Keinan de Souza Cruz — [@KeinanSZ](https://github.com/KeinanSZ)
- Maycon Douglas A. Paixão — [@douglasmaycon120-lgtm](https://github.com/douglasmaycon120-lgtm)

## Visão geral

O SQEducaPlay foi pensado para oferecer uma experiência de estudo mais envolvente, com mecânicas de progressão, desafios, feedback imediato e acompanhamento do desempenho do aluno. A proposta é combinar aprendizagem, motivação e acessibilidade em uma solução mobile/web com uso prático em contextos escolares.

O projeto foi estruturado para funcionar como uma base educativa e institucional, com suporte a perfis de aluno, professor, escola e administrador, além de gestão local de usuários e convites.

## Objetivos

- estimular o aprendizado de forma lúdica e acessível;
- reforçar conteúdos do 2º ao 5º ano do Ensino Fundamental;
- apoiar o acompanhamento de progresso por aluno;
- oferecer uma experiência consistente em ambientes digitais e mobile;
- viabilizar gestão escolar básica no contexto da aplicação.

## Funcionalidades principais

- banco de questões por disciplina e ano;
- gamificação com pontuação, conquistas e progresso;
- navegação por perfil de aluno, professor e administrador;
- gestão de escolas, professores, alunos e convites;
- persistência local de dados com SQLite;
- funcionamento offline em parte do fluxo principal;
- acesso online experimental com conta de responsável, perfis familiares e sincronização de quizzes;
- suporte a web e mobile com interface responsiva.

## Tecnologias

- Flutter
- Dart
- SQLite
- Material Design
- GitHub para versionamento
- Supabase (autenticação e sincronização online experimental)

## Estrutura do projeto

```text
.
├── android/
├── assets/
├── docs/
├── ios/
├── lib/
├── test/
├── web/
├── analysis_options.yaml
├── pubspec.yaml
├── pubspec.lock
├── README.md
├── .gitignore
└── .metadata
```

## Requisitos

Antes de executar o projeto, certifique-se de que você tenha instalado:

- Flutter SDK
- Git
- VS Code ou outro editor compatível
- Android Studio, emulador Android ou dispositivo físico
- Windows: modo de desenvolvedor ativado, quando necessário

## Como executar

### 1. Clone o projeto

```bash
git clone https://github.com/SQEducaPlay/SQEducaPlay.git
cd SQEducaPlay
```

### 2. Instale as dependências

```bash
flutter pub get
```

### 3. Verifique a instalação do Flutter

```bash
flutter doctor
```

### 4. Execute o aplicativo

```bash
flutter run
```

## Demo web e builds de release

A versão web está **online** e pode ser acessada por celular ou computador:

**[Abrir SQEducaPlay](https://sqeducaplay.github.io/SQEducaPlay/)**

Cada push em `main` gera a versão web e o APK Android. Para baixar a versão mais recente do APK, acesse:

**https://github.com/SQEducaPlay/SQEducaPlay/actions/workflows/release.yml**

> O APK gerado pelo workflow é destinado a testes e distribuição direta.

O acesso de responsável/Supabase está em validação. As contas antigas continuam
locais até que o responsável escolha explicitamente importar o histórico para
um perfil online. Não use dados identificáveis de crianças enquanto a revisão
institucional e do aviso de privacidade estiver pendente.

## Acesso do aluno

Para acessar o app como aluno:

1. abra o aplicativo;
2. selecione a opção de aluno;
3. faça cadastro ou login com a conta do estudante;
4. acompanhe o progresso, responda os quizzes e consulte o perfil.

## Acesso do professor

Para acessar o app como professor:

1. abra o aplicativo;
2. selecione a opção de professor;
3. faça login com a conta do professor;
4. utilize o painel para gerenciar turmas, alunos e convites de acesso.

## Conteúdo pedagógico

A aplicação foi desenvolvida para cobrir conteúdos dos anos finais do Ensino Fundamental I, com foco principal em:

- Matemática
- Português

Os conteúdos são organizados por ano escolar e alinhados a critérios pedagógicos considerados na estrutura do projeto.

## Documentação complementar

- [Índice da documentação](docs/README.md)
- [Documentação técnica](DOCUMENTACAO_TECNICA.md): arquitetura, estrutura e decisões do software.
- [Guia de contribuição](CONTRIBUTING.md): branches, commits, testes e revisão.
- [Plano de Ação Extensionista](docs/plano-de-acao-p1.md): preparação da oficina e indicadores; depende de confirmação dos dados da escola parceira.
- [Kit de oficina e evidências](docs/oficina/kit-de-evidencias.md): roteiro, checklist de dois aparelhos offline e ficha agregada pré/pós.
- [Informação ao responsável — rascunho](docs/oficina/termo-responsavel-piloto.md): requer revisão institucional e substituição pelo modelo oficial do AVA antes do uso.
- [Modelo de relatório pós-oficina](docs/oficina/relatorio-pos-oficina.md): preencher após a atividade, com dados agregados.

## Status do projeto

O projeto está em desenvolvimento contínuo, com foco em:

- refinamento da experiência do usuário;
- ajustes de gestão institucional;
- melhoria do fluxo de autenticação e perfis;
- expansão de funcionalidades pedagógicas e administrativas.

## Observações

- A versão atual prioriza o funcionamento local e a validação do fluxo principal da aplicação.
- A execução em ambiente Android pode exigir a instalação do SDK e aceitação das licenças do Android.
- O projeto pode ser usado como base para evolução em produção, com integração de backend e melhorias de segurança em etapas posteriores.

## Licença

Este projeto foi desenvolvido para fins educacionais e acadêmicos. Consulte o repositório para verificar a política de uso vigente.
