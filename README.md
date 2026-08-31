# SQEducaPlay

<div align="center">

<img src="assets/images/logo_full.png" alt="Logo SQEducaPlay" width="420" />

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Status](https://img.shields.io/badge/status-em%20desenvolvimento-orange)

</div>

Aplicativo educacional gamificado desenvolvido para apoiar o aprendizado de estudantes do Ensino Fundamental I, com foco em Português e Matemática alinhados à BNCC.

## Entrega acadêmica

### Integrantes do grupo

- Vanessa Barbosa
- Keinan de Souza Cruz
- Maycon Douglas A. Paixão
- Leandro de O. B. Monteiro

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
- suporte a web e mobile com interface responsiva.

## Tecnologias

- Flutter
- Dart
- SQLite
- Material Design
- GitHub para versionamento

## Estrutura do projeto

```text
.
├── android/
├── assets/
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

A documentação do projeto está organizada em materiais de apoio dentro do repositório, incluindo orientações sobre banco de dados, estrutura, gestão escolar e evolução funcional.

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

