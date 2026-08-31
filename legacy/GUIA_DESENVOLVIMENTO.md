# 🚀 GUIA DE DESENVOLVIMENTO - SQEducaPlay

## 1. CONFIGURAÇÃO DO AMBIENTE

### 1.1 Pré-requisitos
- **Windows/Mac/Linux** com Git instalado
- **Flutter SDK 3.43.0** (beta channel) — [Instalar](https://flutter.dev/docs/get-started/install)
- **Dart 3.12.0** (incluído no Flutter)
- **Android Studio** ou **Xcode** (para rodar em emulador/dispositivo) — [Instalar](https://developer.android.com/studio?hl=pt-br)
- **VS Code** com extensão Flutter/Dart (recomendado) — [Instalar](https://code.visualstudio.com/)

### 1.2 Clonar Repositório
```bash
cd d:\
git clone https://github.com/KeinanSZ/SQEducaPlay.git
cd SQEducaPlay
```

### 1.3 Instalar Dependências
```bash
flutter pub get
```

### 1.4 Verificar Setup
```bash
flutter doctor
```
Certifique-se que todos os checkmarks ✅ estão presentes

### 1.5 Rodar em Emulador/Dispositivo

**Android (emulador):**
```bash
flutter emulators --launch Pixel_4_API_30
flutter run
```

**iOS (simulador - Mac apenas):**
```bash
open -a Simulator
flutter run
```

**Web (navegador):**
```bash
flutter run -d chrome
```

---

## 2. ESTRUTURA DO PROJETO

### Organização de Arquivos
```
lib/
├── main.dart                 # Entrada + configuração do app
├── database/
│   └── app_database.dart     # Singleton SQLite (⚠️ não editar schema sem backups)
├── models/
│   ├── user_model.dart
│   ├── partida_model.dart    # Resultado de quiz
│   ├── progresso_model.dart  # Estado do aluno
│   └── conquista_model.dart  # Badge
├── pages/
│   ├── login_page.dart       # Autenticação
│   ├── jogo_page.dart        # ⚠️ Lógica complexa do quiz
│   └── ...
├── services/
│   ├── progresso_service.dart # ⚠️ Crítico para gamificação
│   ├── background_audio_service.dart
│   └── ...
└── assets/
    ├── sounds/
    └── images/
```

### Arquivos Críticos (⚠️ cuidado ao editar)
1. **app_database.dart** — Mudanças no schema quebram builds anteriores
2. **progresso_service.dart** — Lógica de pontos/níveis/conquistas
3. **jogo_page.dart** — Cálculo de resultado do quiz
4. **main.dart** — Inicialização de serviços

---

## 3. CONVENÇÕES DE CÓDIGO

### 3.1 Nomenclatura

**Arquivos:**
```dart
// ✅ Correto
login_page.dart
user_service.dart
background_audio_service.dart

// ❌ Errado
LoginPage.dart
userService.dart
```

**Classes:**
```dart
// ✅ Correto
class UserService { }
class BackgroundAudioService { }

// ❌ Errado
class user_service { }
class bgAudioService { }
```

**Métodos:**
```dart
// ✅ Correto
void saveUser(User user) { }
Future<List<Partida>> buscarPartidas() { }

// ❌ Errado
void Save_User(User user) { }
Future<List<Partida>> BuscarPartidas() { }
```

**Variáveis:**
```dart
// ✅ Correto
int pontuacaoTotal = 0;
bool _muted = false; // privada
final List<User> usuarios = [];

// ❌ Errado
int pontuacao_total = 0;
bool Muted = false;
var usuarios = [];
```

### 3.2 Comentários

```dart
// ✅ Bom
/// Calcula o nível do aluno baseado em pontuação
/// 
/// Retorna: 1-5 (Iniciante até Mestre)
int calcularNivel(int pontos) {
  // TODO: Considerar bonus de badges
  if (pontos < 50) return 1;
  // ...
}

// ❌ Ruim
// calcula nivel
int calcularNivel(int pontos) {
  if (pontos < 50) return 1; // iniciante
}
```

### 3.3 Estrutura de Classe

```dart
// ✅ Correto (ordem):
class UserService {
  // 1. Variáveis estáticas
  static final UserService _instance = UserService._internal();
  
  // 2. Variáveis de instância
  User? usuarioAtual;
  List<User> usuarios = [];
  
  // 3. Getters/Setters
  User? get usuarioLogado => usuarioAtual;
  
  // 4. Construtores
  UserService._internal();
  
  static UserService get instance => _instance;
  
  // 5. Métodos públicos
  bool login(String username, String password) { ... }
  void logout() { ... }
  
  // 6. Métodos privados
  void _sincronizar() { ... }
}
```

---

## 4. PADRÕES DE DESENVOLVIMENTO

### 4.1 Singleton Pattern (Serviços)

```dart
// ✅ Correto para criar um service
class MyNewService {
  static final MyNewService _instance = MyNewService._internal();
  
  MyNewService._internal();
  
  static MyNewService get instance => _instance;
  
  // Seu código aqui
}

// Usar:
MyNewService.instance.meuMetodo();
```

### 4.2 Acesso ao Banco de Dados

```dart
// ✅ Correto
final db = AppDatabase.instance;
User? user = await db.buscarUsuario('keinan', 'keinan');
await db.salvarPartida(...);

// ❌ Errado (não faça)
AppDatabase database = AppDatabase();  // Nova instância!
database.salvarPartida(...);
```

### 4.3 StatefulWidget com Services

```dart
// ✅ Correto
class JogoPage extends StatefulWidget {
  const JogoPage({Key? key}) : super(key: key);
  
  @override
  State<JogoPage> createState() => _JogoPageState();
}

class _JogoPageState extends State<JogoPage> {
  late UserService _userService;
  late ProgressoService _progressoService;
  
  @override
  void initState() {
    super.initState();
    _userService = UserService.instance;
    _progressoService = ProgressoService.instance;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Usuário: ${_userService.usuarioAtual?.fullName}'))
    );
  }
}
```

### 4.4 Tratamento de Erros

```dart
// ✅ Correto
Future<void> salvarQuiz(Partida partida) async {
  try {
    await AppDatabase.instance.salvarPartida(...);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Quiz salvo com sucesso!'))
    );
  } catch (e) {
    print('Erro ao salvar quiz: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro ao salvar quiz'))
    );
  }
}

// ❌ Errado (ignora erro)
Future<void> salvarQuiz(Partida partida) async {
  await AppDatabase.instance.salvarPartida(...);
  // sem try-catch!
}
```

---

## 5. ADICIONANDO NOVAS FEATURES

### 5.1 Adicionar Nova Matéria

**Passo 1:** Editar `lib/utils/constants.dart`
```dart
const List<String> MATERIAS = ['Português', 'Matemática', 'Ciências'];
// Adicione 'Ciências'
```

**Passo 2:** Atualizar `lib/topicos_page.dart` para incluir tópicos de Ciências

**Passo 3:** Adicionar questões de Ciências em `lib/database/app_database.dart`

**Passo 4:** Testar com `flutter test`

### 5.2 Adicionar Novo Badge/Conquista

**Passo 1:** Editar `lib/models/conquista_model.dart`
```dart
static const List<Conquista> TODAS_CONQUISTAS = [
  // ... badges existentes
  Conquista(
    id: 16,
    nome: 'Novo Badge',
    descricao: 'Desbloqueie ao fazer 50 quizes',
    icone: 'assets/images/badge_50quizes.png',
  ),
];
```

**Passo 2:** Adicionar lógica em `lib/services/progresso_service.dart`
```dart
void _verificarConquistas(int usuarioId) {
  var progresso = this.progresso[usuarioId]!;
  
  // Verificar novo badge
  if (progresso.quizesCompletos == 50) {
    progresso.conquistasDesbloqueadas.add(novoConquista);
  }
}
```

**Passo 3:** Testar desbloqueio manualmente

### 5.3 Adicionar Novo Tópico

**Passo 1:** Editar `lib/banco_perguntas.dart` (ou arquivo de perguntas)
```dart
final topicos = {
  'Português': {
    '2º Ano': [
      'Leitura e Interpretação',
      'Análise Linguística',
      'Novo Tópico', // ← Adicione aqui
    ]
  }
};
```

**Passo 2:** Adicionar questões para o novo tópico

**Passo 3:** Testar carregamento em `TopicosPage`

---

## 6. TESTANDO LOCALMENTE

### 6.1 Testar Login
```
Username: Keinan
Password: keinan
(Admin)

OU

Username: aluno
Password: 123456
(Student - se registrado)
```

### 6.2 Testar Quiz Rápido
1. Login com aluno
2. MaterialasPage → Português → 2º Ano
3. TopicosPage → Seleciona tópico
4. JogoPage → Responde todas questões
5. Verificar resultado e pontos salvos

### 6.3 Testar Gamificação
1. Completar vários quizes
2. Verificar pontos acumulando
3. Ao atingir threshold → Nível muda
4. Ao completar condição → Badge desbloqueia

### 6.4 Testar Ranking
1. Criar múltiplos alunos
2. Cada um completar quizes
3. Abrir ranking
4. Verificar ordem e top 3

---

## 7. BUILD E DEPLOYMENT

### 7.1 Build APK (Android)

```bash
# Debug
flutter build apk --debug

# Release (production)
flutter build apk --release
```

APK localizado em: `build/app/outputs/flutter-apk/app-release.apk`

### 7.2 Build AAB (Google Play)

```bash
flutter build appbundle --release
```

### 7.3 Build iOS (Mac only)

```bash
flutter build ios --release --no-codesign
```

Depois assinar no Xcode ou com Fastlane.

### 7.4 Build Web

```bash
flutter build web --release
```

Arquivos estáticos em: `build/web/`

---

## 8. TROUBLESHOOTING

### Erro: "Database is locked"
```
Causa: Múltiplas instâncias de banco abertos
Solução: Garantir que AppDatabase.instance é singleton
```

### Erro: "Cannot find asset"
```
Causa: Asset não declarado em pubspec.yaml
Solução: Verificar paths em pubspec.yaml e rodar 'flutter pub get'
```

### Erro: "TTS not working"
```
Causa: Permissões não concedidas
Solução: Verificar AndroidManifest.xml e Info.plist
```

### Erro: "Nível não atualiza"
```
Causa: ProgressoService não chamou verificação de nível
Solução: Garantir que após quiz, chamar:
  ProgressoService.instance.registrarResultadoQuiz(...)
```

---

## 9. ANÁLISE DE CÓDIGO

```bash
# Verificar erros/warnings
flutter analyze

# Executar testes
flutter test

# Formato de código
dart format lib/

# Melhorias de lint
flutter pub run flutter_lints
```

---

## 10. COMMITS E GIT

### Convenção de Commits
```
[FEATURE] Adicionar novo badge
[FIX] Corrigir cálculo de nível
[REFACTOR] Reorganizar estrutura de serviços
[DOCS] Atualizar documentação
[TEST] Adicionar testes de quiz
```

### Exemplo de Commit Bom
```bash
git add lib/models/conquista_model.dart
git commit -m "[FEATURE] Adicionar badge '100 Quizes Completados'"
git push origin main
```

---

## 11. DOCUMENTAÇÃO DE CÓDIGO

### Sempre documentar métodos públicos:

```dart
/// Calcula a pontuação de um quiz baseado em acertos
/// 
/// Parameters:
///   - [acertos] número de questões respondidas corretamente
///   - [totalQuestoes] número total de questões
///   - [tempoSegundos] tempo gasto (para bônus)
/// 
/// Returns:
///   Mapa com 'pontos' e 'estrelas'
/// 
/// Example:
///   ```dart
///   var resultado = calcularPontuacao(4, 5, 120);
///   print(resultado['pontos']); // 40
///   ```
Map<String, int> calcularPontuacao(int acertos, int totalQuestoes, int tempoSegundos) {
  // ...
}
```

---

## 12. PERFORMANCE TIPS

### Usar const quando possível
```dart
// ✅ Bom (rebuild otimizado)
const Text('Quiz Completo')

// ❌ Ruim (rebuild a cada frame)
Text('Quiz Completo')
```

### Lazy load de dados
```dart
// ✅ Bom (carrega sob demanda)
Future<List<Partida>> buscarUltimasPartidas() async {
  return await db.query(limite: 10);
}

// ❌ Ruim (carrega tudo)
Future<List<Partida>> buscarTodasPartidas() async {
  return await db.query();
}
```

---

## 13. ÚTEIS

**Links:**
- [Flutter Docs](https://flutter.dev/docs)
- [Dart Docs](https://dart.dev/guides)
- [SQLite Docs](https://www.sqlite.org/docs.html)
- [BNCC](https://www.gov.br/cidadania/pt-br/acesso-a-informacao/participacao-social/consultas-publicas/educacao/bncc)

**Comandos Úteis:**
```bash
flutter pub get                 # Instalar dependências
flutter clean                   # Limpar build
flutter pub upgrade             # Atualizar packages
flutter doctor                  # Diagnosticar setup
flutter packages pub publish    # Publicar seu próprio package
```

---

## 14. CHECKLIST ANTES DE COMMIT

- [ ] Código sem syntax errors (`flutter analyze`)
- [ ] Métodos públicos documentados (///)
- [ ] Testes passando (se aplicável)
- [ ] Nenhum `print()` no código final
- [ ] Sem hardcoded values (use constants.dart)
- [ ] Tratamento de erros com try-catch
- [ ] Nomes descritivos de variáveis
- [ ] Commit message significativa

---

**Versão:** 1.0
**Última atualização:** 15/05/2026
**Mantido por:** Keinan
