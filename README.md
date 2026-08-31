# SQEducaPlay - Alunos

Versão resumida do SQEducaPlay. Este repositório contém apenas o necessário para executar o app Flutter e não inclui build, cache do Flutter nem arquivos locais do computador.

## Como executar

### Checklist de instalação

- [ ] Instalar o Flutter SDK.
- [ ] Instalar o Git.
- [ ] Instalar o VS Code ou outro editor compatível.
- [ ] No Windows, ativar o Modo de Desenvolvedor.

### Passo a passo para rodar

1. Clonar o repositório:

```bash
git clone https://github.com/SQEducaPlay/SQEducaPlay.git
```

2. Entrar na pasta do projeto:

```bash
cd SQEducaPlay
```

3. Baixar as dependências:

```bash
flutter pub get
```

4. Verificar a instalação do Flutter:

```bash
flutter doctor
```

5. Executar o app:

```bash
flutter run
```

### Se algo der errado

- Confirme se o Flutter está no PATH.
- Confira se o dispositivo ou emulador está disponível.
- No Windows, confirme se o Modo de Desenvolvedor está ativado.
- Rode novamente `flutter pub get` se faltar alguma dependência.

## Conteúdo incluído

- `lib/`
- `assets/`
- `android/`
- `ios/`
- `web/`
- `pubspec.yaml`
- `pubspec.lock`
- `analysis_options.yaml`
- `.gitignore`
- `.metadata`

## Observação

Se alguém for executar no Android, pode ser necessário instalar o SDK e aceitar as licenças do Flutter/Android antes de rodar o app.
