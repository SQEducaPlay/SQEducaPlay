# 🏗️ DOCUMENTAÇÃO TÉCNICA - SQEducaPlay

## 1. ARQUITETURA DO PROJETO

### 1.1 Visão Geral da Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                    UI LAYER (Flutter)                       │
│LoginPage │MaterialasPage │JogoPage │ PerfilPage |RankingPage│
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│              BUSINESS LOGIC LAYER (Services)                │
│  UserService │ ProgressoService │ SchoolService │ ClassGroup│
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│            DATA LAYER (Database + Storage)                  │
│       AppDatabase (SQLite) │ SharedPreferences              │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Padrão de Arquitetura

**Tipo:** Híbrido (MVC + Singleton Services)

- **Model**: Classes de dados (`user_model.dart`, `school_model.dart`)
- **View**: Páginas Flutter (StatefulWidget)
- **Controller**: Services singleton (UserService, ProgressoService, etc)
- **Data**: AppDatabase (SQLite)

**Por quê não Provider/BLoC?**
- Projeto simples, dados offline
- Singletons suficientes para gerenciar estado
- Reduz complexidade para app educacional

### 1.3 Dependências Principais

```yaml
# Core
flutter_tts: 4.2.3          # Text-to-Speech (leitura questões)
audioplayers: 6.5.1         # Áudio (música + efeitos)

# Database
sqflite: 2.3.3              # SQLite local
path: 1.9.0                 # Caminho do banco

# Storage
shared_preferences: 2.3.2   # Preferências locais

# UI
google_fonts: 8.0.2         # Tipografia
confetti: 0.8.0             # Celebração/confete
flutter_launcher_icons: 0.14.2
flutter_native_splash: 2.4.1

# Dev
flutter_lints: 6.0.0        # Análise de código
```

---

## 2. ESTRUTURA DE DIRETÓRIOS

```
lib/
├── main.dart                      # Entrada do app
├── login_page.dart                # Página de login
├── home_page.dart                 # Dashboard admin
├── materias_page.dart             # Seleção de matérias
├── topicos_page.dart              # Seleção de tópicos
├── jogo_page.dart                 # Quiz interativo
├── register_page.dart             # Registro de aluno
├── user_model.dart                # Modelo de usuário
├── school_model.dart              # Modelo de escola
│
├── database/
│   ├── app_database.dart          # Singleton SQLite
│   └── schema.sql                 # Schema inicial (opcional)
│
├── models/
│   ├── user_model.dart
│   ├── partida_model.dart         # Modelo de quiz completo
│   ├── progresso_model.dart       # Progresso do aluno
│   ├── conquista_model.dart       # Badge/Conquista
│   └── school_model.dart
│
├── pages/
│   ├── perfil_aluno_page.dart     # Perfil do aluno
│   ├── ranking_database_page.dart # Ranking por DB
│   ├── ranking_tabs_page.dart     # Ranking admin (tabs)
│   ├── estatisticas_page.dart     # Estatísticas/histórico
│   ├── manage_class_groups_page.dart  # Gerenciamento turmas
│   ├── manage_schools_page.dart   # Gerenciamento escolas
│   └── privacy_settings_page.dart # Configurações LGPD
│
├── services/
│   ├── user_service.dart          # Gerenciar usuários
│   ├── school_service.dart        # Gerenciar escolas
│   ├── class_group_service.dart   # Gerenciar turmas
│   ├── progresso_service.dart     # Progresso/conquistas
│   ├── background_audio_service.dart  # Música + efeitos
│   ├── privacy_settings_service.dart  # LGPD settings
│   └── celebration_service.dart   # Celebrações
│
├── utils/
│   ├── constants.dart             # Constantes do app
│   ├── theme.dart                 # Temas (cores, fontes)
│   └── helpers.dart               # Funções auxiliares
│
└── assets/
    ├── images/                    # Imagens (mascote, logo, ícones)
    └── sounds/                    # Sons (fundo, acerto, erro, vitória)
```

---

## 3. BANCO DE DADOS (SQLite)

### 3.1 Schema Completo

#### Tabela: `users`
```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  fullName TEXT NOT NULL,
  role TEXT DEFAULT 'student',          -- 'admin' ou 'student'
  grade INTEGER,                         -- Série (2, 3, 4, 5)
  schoolId INTEGER,
  pontuacao_total INTEGER DEFAULT 0,
  estrelas_total INTEGER DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

#### Tabela: `partidas`
```sql
CREATE TABLE partidas (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  usuario_id INTEGER NOT NULL,
  materia TEXT NOT NULL,                -- 'português' ou 'matemática'
  ano INTEGER NOT NULL,                 -- Série
  topico TEXT NOT NULL,
  pontuacao INTEGER NOT NULL,
  estrelas INTEGER NOT NULL,            -- 0-3
  acertos INTEGER NOT NULL,
  total_questoes INTEGER NOT NULL,
  tempo_segundos INTEGER NOT NULL,
  data_partida DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_id) REFERENCES users(id)
);
```

#### Tabela: `user_stats`
```sql
CREATE TABLE user_stats (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  usuario_id INTEGER NOT NULL UNIQUE,
  portugues_taxa_acerto REAL DEFAULT 0.0,
  matematica_taxa_acerto REAL DEFAULT 0.0,
  total_quizes INTEGER DEFAULT 0,
  total_pontos INTEGER DEFAULT 0,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_id) REFERENCES users(id)
);
```

#### Tabela: `user_progress`
```sql
CREATE TABLE user_progress (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  usuario_id INTEGER NOT NULL,
  materia TEXT NOT NULL,                -- 'português' ou 'matemática'
  ano INTEGER NOT NULL,
  topico TEXT NOT NULL,
  completed BOOLEAN DEFAULT 0,
  completed_at DATETIME,
  FOREIGN KEY (usuario_id) REFERENCES users(id),
  UNIQUE(usuario_id, materia, ano, topico)
);
```

### 3.2 Operações Principais

**Buscar usuário:**
```dart
User? user = await AppDatabase.instance.buscarUsuario('keinan', 'keinan');
```

**Salvar quiz completo:**
```dart
await AppDatabase.instance.salvarPartida(
  usuarioId: 1,
  materia: 'matemática',
  ano: 2,
  topico: 'Adição e Subtração',
  pontuacao: 40,
  estrelas: 3,
  acertos: 4,
  totalQuestoes: 5,
  tempoSegundos: 120
);
```

**Buscar ranking:**
```dart
List<User> ranking = await AppDatabase.instance.buscarRanking(limite: 3);
```

**Buscar estatísticas:**
```dart
Map<String, dynamic> stats = await AppDatabase.instance.buscarEstatisticasUsuario(1);
```

---

## 4. SERVIÇOS (Singletons)

### 4.1 UserService
**Função:** Gerenciar usuário logado em sessão

```dart
class UserService {
  static final UserService _instance = UserService._internal();
  
  User? usuarioAtual;
  
  static UserService get instance => _instance;
  
  // Fazer login
  bool login(String username, String password) { ... }
  
  // Fazer logout
  void logout() { ... }
  
  // Registrar novo aluno
  bool registrar(String nome, int serie, int escolaId) { ... }
}
```

### 4.2 ProgressoService
**Função:** Rastrear progresso, pontuação, conquistas do aluno

```dart
class ProgressoService {
  static final ProgressoService _instance = ProgressoService._internal();
  
  Map<int, Progresso> progresso = {}; // usuarioId -> Progresso
  
  // Registrar resultado de quiz
  void registrarResultadoQuiz(int usuarioId, int pontos, int estrelas) { ... }
  
  // Obter nível do aluno
  int getNivel(int usuarioId) { ... }
  
  // Verificar conquistas desbloqueadas
  List<Conquista> verificarConquistas(int usuarioId) { ... }
  
  // Obter ranking
  List<User> getRanking() { ... }
}
```

### 4.3 BackgroundAudioService
**Função:** Gerenciar música e efeitos sonoros

```dart
class BackgroundAudioService {
  static final BackgroundAudioService _instance = BackgroundAudioService._internal();
  
  AudioPlayer _backgroundPlayer = AudioPlayer();
  AudioPool _effectsPool = AudioPool();
  bool _muted = false;
  
  // Inicializar ao startup
  Future<void> init() async { ... }
  
  // Tocar música em loop
  Future<void> playLooped(String assetPath) async { ... }
  
  // Tocar efeito sonoro
  Future<void> playEffect(String effectType) async {
    // 'acerto', 'erro', 'vitoria'
  }
  
  // Ativar/desativar som
  void toggleMute() { ... }
}
```

### 4.4 SchoolService
**Função:** Gerenciar escolas municipais

```dart
class SchoolService {
  static final SchoolService _instance = SchoolService._internal();
  
  List<School> _escolas = [];
  
  static SchoolService get instance => _instance;
  
  // Obter todas escolas
  List<School> getEscolas() => _escolas;
  
  // Adicionar escola
  void adicionarEscola(School school) { ... }
}
```

### 4.5 PrivacySettingsService
**Função:** Gerenciar configurações de privacidade (LGPD)

```dart
class PrivacySettingsService {
  static final PrivacySettingsService _instance = PrivacySettingsService._internal();
  
  bool anonymizeStudentNames = false;
  bool showSchoolInStudentRanking = true;
  bool enableConfetti = true;
  bool enableSounds = true;
  
  // Carregar/salvar preferências
  Future<void> loadSettings() async { ... }
  Future<void> saveSettings() async { ... }
}
```

---

## 5. FLUXOS PRINCIPAIS

### 5.1 Fluxo de Login
```
1. Login Screen
   ↓
2. UserService.login(username, password)
   ├─ Busca em cache UserService._usuariosMemoria
   ├─ Se não encontrar, busca em AppDatabase.users
   ├─ Se encontrar, atualiza UserService.usuarioAtual
   ├─ Salva ID em SharedPreferences
   └─ Retorna true
   ↓
3. Se admin → Home (admin dashboard)
   Se student → MaterialasPage (seleção matéria)
```

### 5.2 Fluxo de Quiz Completo
```
1. MaterialasPage → Seleciona Português/Matemática
2. TopicosPage → Seleciona Tópico
3. JogoPage Inicia
   ├─ Carrega questões do tópico
   ├─ BackgroundAudioService toca música
   ├─ Timer inicia
   └─ Exibe 1ª questão
4. Aluno responde (seleciona opção)
   ├─ Valida resposta
   ├─ Se correto → +10 pontos + som acerto
   ├─ Se errado → 0 pontos + som erro
   └─ Próxima questão
5. Questão Final
   ├─ Calcula resultado: pontos, estrelas (0-3), acertos/total
   └─ Salva em AppDatabase.partidas
6. Resultado Screen
   ├─ Exibe pontuação, estrelas
   ├─ Atualiza ProgressoService
   ├─ Verifica Conquistas desbloqueadas
   ├─ Se nova conquista → Confete + Som vitória
   └─ Atualiza Ranking
```

### 5.3 Fluxo de Desbloqueio de Conquista
```
ProgressoService.registrarResultadoQuiz()
   ↓
Verifica critérios:
   ├─ Se 1º quiz completo → Desbloqueia "Primeira Vitória"
   ├─ Se pontos >= 50 → Desbloqueia "50 Pontos"
   ├─ Se 5 quizes com 100% → Desbloqueia "Perfeição"
   ├─ Se Português + Matemática completos → "Multidisciplinar"
   └─ Etc...
   ↓
Se nova conquista:
   ├─ CelebrationService.celebrate()
   ├─ Confetti controller ativa
   ├─ BackgroundAudioService.playEffect('vitoria')
   ├─ Mostra popup: "Parabéns! Desbloqueou: [Nome Badge]"
   └─ Persiste em banco
```

### 5.4 Fluxo de Ranking
```
PerfilAlunoPage clica Ranking
   ↓
ProgressoService.getRanking()
   ├─ Agrupa todos alunos por pontuação total
   ├─ Ordena DESC (maior pontuação primeiro)
   └─ Retorna top 3 + posição do aluno
   ↓
RankingPage exibe:
   ├─ 1º lugar (Ouro 🥇) - cor laranja
   ├─ 2º lugar (Prata 🥈) - cor cinzenta
   ├─ 3º lugar (Bronze 🥉) - cor marrom
   ├─ "Você está em 8º lugar" (do aluno)
   └─ Filtros: Turma, Escola, Série
```

---

## 6. FLUXO DE DADOS - DIAGRAMA

```
┌─────────────────────────────────────────────────────────┐
│                  QUIZ COMPLETO                          │
│  Aluno responde 5 questões, finaliza                   │
└──────────────────────┬──────────────────────────────────┘
                       │
            ┌──────────▼──────────┐
            │  Calcular Resultado │
            │ Pontos: 40          │
            │ Estrelas: 3         │
            │ Acertos: 4/5        │
            │ Tempo: 120s         │
            └──────────┬──────────┘
                       │
        ┌──────────────▼──────────────┐
        │  AppDatabase.salvarPartida()│
        │  Insere em 'partidas'       │
        └──────────────┬──────────────┘
                       │
         ┌─────────────▼─────────────┐
         │ Atualiza user.pontos      │
         │ pontuacao_total += 40     │
         │ estrelas_total += 3       │
         └─────────────┬─────────────┘
                       │
    ┌──────────────────▼──────────────────┐
    │ ProgressoService.registrarResultado │
    │ Atualiza memória (_progresso)       │
    └──────────────────┬──────────────────┘
                       │
            ┌──────────▼──────────┐
            │ Verifica Conquistas │
            │ Desbloqueadas?      │
            │ (15 badges)         │
            └──────────┬──────────┘
                       │
        ┌──────────────▼──────────────┐
        │ Se SIM → CelebrationService │
        │ - Confetti animation        │
        │ - Som vitória               │
        │ - Popup badge               │
        │ - Persiste no banco         │
        └──────────────┬──────────────┘
                       │
                ┌──────▼──────┐
                │ Atualiza    │
                │ Ranking em  │
                │ tempo real  │
                └─────────────┘
```

---

## 7. MODELOS DE DADOS

### User Model
```dart
class User {
  final int? id;
  final String username;
  final String password;
  final String fullName;
  final String role; // 'admin' ou 'student'
  final int? grade; // Série: 2, 3, 4, 5
  final int? schoolId;
  int pontuacaoTotal;
  int estrelasTotal;
}
```

### Partida Model (Quiz Result)
```dart
class Partida {
  final int? id;
  final int usuarioId;
  final String materia;  // 'português' ou 'matemática'
  final int ano;
  final String topico;
  final int pontuacao;
  final int estrelas; // 0-3
  final int acertos;
  final int totalQuestoes;
  final int tempoSegundos;
  final DateTime dataPart ida;
}
```

### Progresso Model
```dart
class Progresso {
  int usuarioId;
  int pontuacaoTotal;
  int estrelasTotal;
  int quizesCompletos;
  int nivel; // 1-5
  List<Conquista> conquistasDesbloqueadas;
  Map<String, double> taxaAcertoPorMateria;
}
```

### Conquista Model (Badge)
```dart
class Conquista {
  final int id;
  final String nome;
  final String descricao;
  final String icone; // Asset path
  final int criterio; // Pontos, quizes, etc
  final DateTime? desbloqueadaEm;
  bool desbloqueada;
}
```

---

## 8. TECNOLOGIAS E FRAMEWORKS

| Componente | Tecnologia | Versão |
|-----------|-----------|--------|
| **Framework** | Flutter | 3.43.0 beta |
| **Linguagem** | Dart | 3.12.0 |
| **DB Local** | SQLite | sqflite 2.3.3 |
| **Áudio** | audioplayers + flutter_tts | 6.5.1 + 4.2.3 |
| **Armazenamento Local** | shared_preferences | 2.3.2 |
| **UI Extra** | google_fonts, confetti | 8.0.2, 0.8.0 |
| **Análise Código** | flutter_lints | 6.0.0 |

---

## 9. CONFIGURAÇÕES IMPORTANTES

### AndroidManifest.xml
```xml
<activity
  android:name=".MainActivity"
  android:orientation="portrait">
  <!-- Apenas portrait -->
</activity>
<!-- Permissões TTS -->
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS Info.plist
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Permissão para ler questões em voz alta</string>
<key>UIInterfaceOrientations</key>
<array>
  <string>UIInterfaceOrientationPortrait</string>
</array>
```

### pubspec.yaml - Assets
```yaml
assets:
  - assets/images/
  - assets/sounds/fundo.mp3
  - assets/sounds/acerto.mp3
  - assets/sounds/erro.mp3
  - assets/sounds/vitoria.mp3
```

---

## 10. FLUXOS DE ERRO

### Erro: Banco não consegue inicializar
```
→ Fallback para in-memory storage
→ Dados não persistem (Web)
→ Aviso no console
```

### Erro: Quiz timeout
```
→ Salva parcialmente
→ Mostra "Quiz Interrompido"
→ Permite retomar
```

### Erro: Autenticação falha
```
→ Mensagem: "Username ou senha incorretos"
→ Apaga campo de senha
→ Foca em username
```

---

## 11. CHECKLIST DE DESENVOLVIMENTO

- [ ] Banco SQLite inicializando corretamente
- [ ] CRUD completo em AppDatabase
- [ ] UserService gerenciando login/logout
- [ ] ProgressoService calculando níveis corretamente
- [ ] Conquistas desbloqueando ao atingir critério
- [ ] Ranking atualizando em tempo real
- [ ] Áudio: música de fundo e efeitos funcionando
- [ ] TTS lendo questões
- [ ] Confetti animando ao desbloquear badge
- [ ] Quiz salvando e recuperando corretamente
- [ ] Estatísticas calculadas corretamente
- [ ] Perfil exibindo dados corretos
- [ ] Admin conseguindo gerenciar escolas
- [ ] Privacidade (LGPD) funcionando
- [ ] Build Android/iOS sem erros

---

**Versão:** 1.1
**Data:** 20/09/2026
