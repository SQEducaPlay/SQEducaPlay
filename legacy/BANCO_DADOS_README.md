# 📊 Banco de Dados - SQEducaPlay

## Implementação SQLite Local

Nosso projeto SQEducaPlay agora possui um **banco de dados SQLite local** que armazena todo o progresso dos alunos, permitindo:

- ✅ **Persistência de dados** (não perde ao fechar o app)
- ✅ **Histórico completo** de partidas jogadas
- ✅ **Ranking real** com pontuação acumulada
- ✅ **Estatísticas detalhadas** por matéria e ano
- ✅ **Funciona offline** (sem necessidade de internet)

---

## 🗄️ Estrutura do Banco de Dados

### Tabelas Criadas

#### 1. **usuarios**
Armazena informações dos alunos e administradores.

```sql
CREATE TABLE usuarios (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nome TEXT NOT NULL,
  email TEXT UNIQUE,
  foto_url TEXT,
  pontuacao_total INTEGER DEFAULT 0,
  estrelas_total INTEGER DEFAULT 0,
  data_cadastro TEXT NOT NULL
)
```

#### 2. **partidas**
Histórico completo de cada quiz jogado.

```sql
CREATE TABLE partidas (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  usuario_id INTEGER NOT NULL,
  materia TEXT NOT NULL,
  ano TEXT NOT NULL,
  topico TEXT,
  pontuacao INTEGER NOT NULL,
  estrelas INTEGER NOT NULL,
  acertos INTEGER NOT NULL,
  total_perguntas INTEGER NOT NULL,
  tempo_segundos INTEGER,
  data_partida TEXT NOT NULL,
  FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
)
```

#### 3. **progresso_materias**
Progresso acumulado por matéria e ano escolar.

```sql
CREATE TABLE progresso_materias (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  usuario_id INTEGER NOT NULL,
  materia TEXT NOT NULL,
  ano TEXT NOT NULL,
  total_acertos INTEGER DEFAULT 0,
  total_perguntas INTEGER DEFAULT 0,
  melhor_pontuacao INTEGER DEFAULT 0,
  ultima_atualizacao TEXT NOT NULL,
  FOREIGN KEY (usuario_id) REFERENCES usuarios (id),
  UNIQUE(usuario_id, materia, ano)
)
```

#### 4. **conquistas_usuario**
Conquistas desbloqueadas pelos alunos.

```sql
CREATE TABLE conquistas_usuario (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  usuario_id INTEGER NOT NULL,
  conquista_id TEXT NOT NULL,
  data_desbloqueio TEXT NOT NULL,
  FOREIGN KEY (usuario_id) REFERENCES usuarios (id),
  UNIQUE(usuario_id, conquista_id)
)
```

---

## 🔧 Como Funciona

### 1. **Login / Cadastro Automático**

Quando o aluno faz login (`login_page.dart`):
- Se é a primeira vez → cria registro em `usuarios`
- Se já existe → carrega dados existentes
- Salva o `usuario_id` no SharedPreferences

```dart
// Exemplo de criação automática
await DatabaseHelper.instance.criarUsuario({
  'nome': 'João Silva',
  'email': 'joao@sqeducaplay.com',
  'pontuacao_total': 0,
  'estrelas_total': 0,
  'data_cadastro': DateTime.now().toIso8601String(),
});
```

### 2. **Salvamento Automático ao Finalizar Quiz**

Ao completar um quiz (`jogo_page.dart`), os dados são salvos automaticamente:

```dart
await DatabaseHelper.instance.salvarPartida({
  'usuario_id': usuarioId,
  'materia': 'Português',
  'ano': '2º ano',
  'pontuacao': 80,
  'estrelas': 3,
  'acertos': 8,
  'total_perguntas': 10,
  'data_partida': DateTime.now().toIso8601String(),
});
```

Isso atualiza automaticamente:
- ✅ Pontuação total do usuário
- ✅ Estrelas acumuladas
- ✅ Progresso na matéria

### 3. **Consultas de Ranking**

O ranking agora mostra dados reais do banco:

```dart
// Ranking geral (todos os alunos)
final ranking = await DatabaseHelper.instance.buscarRankingGeral(limit: 20);

// Ranking por matéria específica
final rankingPort = await DatabaseHelper.instance.buscarRankingPorMateria('Português');
```

### 4. **Estatísticas Pessoais**

Cada aluno pode ver suas estatísticas completas:

```dart
final stats = await DatabaseHelper.instance.buscarEstatisticasUsuario(usuarioId);
// Retorna: total de partidas, acertos, média de pontuação, progresso por matéria
```

---

## 📱 Novas Telas Adicionadas

### 1. **Ranking do Banco de Dados** (`ranking_database_page.dart`)
- 3 abas: Geral, Português, Matemática
- Top 20 alunos em cada categoria
- Atualização em tempo real
- Pull-to-refresh

### 2. **Estatísticas Pessoais** (`estatisticas_page.dart`)
- Resumo geral (partidas, taxa de acerto, média)
- Progresso detalhado por matéria
- Histórico das últimas 15 partidas
- Gráficos visuais

### 3. **Acesso pelo Menu**
No menu de matérias (`materias_page.dart`):
- 📊 **Estatísticas** (ícone analytics)
- 🏆 **Ranking** (ícone leaderboard)
- 👤 **Perfil** (ícone person)

---

## 🧪 Como Testar

### Teste Completo (passo a passo):

1. **Fazer Login**
   - Use qualquer usuário existente (ex: aluno1, senha: 123)
   - O sistema cria/carrega o registro no banco

2. **Jogar um Quiz**
   - Escolha uma matéria (Português ou Matemática)
   - Complete o quiz até o final
   - Os dados serão salvos automaticamente

3. **Ver Estatísticas**
   - Clique no ícone 📊 (Estatísticas) no topo
   - Veja: pontos, estrelas, histórico de partidas

4. **Ver Ranking**
   - Clique no ícone 🏆 (Ranking) no topo
   - Navegue pelas abas: Geral, Português, Matemática
   - Seu nome deve aparecer na posição correta

5. **Jogar Mais e Subir no Ranking**
   - Jogue mais quizzes para acumular pontos
   - Atualize o ranking (ícone refresh)
   - Veja sua posição melhorar!

### Verificar Banco de Dados (Debug):

```dart
// No console, você verá logs como:
debugPrint('Novo usuário criado no banco: João (ID: 1)');
debugPrint('Partida salva: 80 pontos, 3 estrelas, 8/10 acertos');
```

---

## 🔍 Localização do Banco de Dados

### Android
```
/data/data/com.example.sqeducaplay/databases/sqeducaplay.db
```

### iOS
```
Library/Application Support/sqeducaplay.db
```

### Web (IndexedDB)
```
IndexedDB → sqflite_databases → sqeducaplay.db
```

---

## 🚀 Funcionalidades Principais

| Funcionalidade | Status | Descrição |
|----------------|--------|-----------|
| Criar usuário no login | ✅ | Automático ao fazer login |
| Salvar partidas | ✅ | Ao completar quiz |
| Ranking geral | ✅ | Top 20 alunos por pontos |
| Ranking por matéria | ✅ | Português e Matemática separados |
| Histórico de partidas | ✅ | Últimas 15 partidas |
| Estatísticas pessoais | ✅ | Taxa de acerto, médias, etc |
| Progresso por matéria | ✅ | Acumulado por ano e matéria |
| Conquistas | 🔄 | Estrutura criada, falta implementar lógica |

---

## 📝 Para a Feira FLIS

### Demonstração Sugerida:

1. **Mostrar Login** → "Aqui o aluno entra no sistema"
2. **Jogar um Quiz** → "Responder perguntas ganha pontos e estrelas"
3. **Abrir Estatísticas** → "Tudo é salvo: histórico, pontos, acertos"
4. **Mostrar Ranking** → "Os alunos competem entre si em tempo real"
5. **Destacar**: "Tudo funciona **offline**, sem internet!"

### Pontos Fortes:
- ✅ Gamificação completa
- ✅ Persistência local (SQLite)
- ✅ Interface atrativa para crianças
- ✅ TTS (leitura de perguntas)
- ✅ Ranking competitivo
- ✅ Estatísticas detalhadas

---

## 🛠️ Arquivos Principais

```
lib/
├── database_helper.dart              # Gerenciador SQLite principal
├── jogo_page.dart                    # Salvamento ao finalizar quiz
├── login_page.dart                   # Criação/login de usuário
├── materias_page.dart                # Menu com links para ranking/stats
└── pages/
    ├── ranking_database_page.dart    # Ranking com dados do banco
    └── estatisticas_page.dart        # Estatísticas pessoais
```

---

## 🎓 Conceitos de SQL Aplicados

- **CREATE TABLE** → Estrutura das tabelas
- **INSERT** → Adicionar novos registros
- **UPDATE** → Atualizar pontuações
- **SELECT** → Consultas de ranking e estatísticas
- **JOIN** → Relacionar usuários com partidas
- **GROUP BY** → Agrupar por matéria
- **ORDER BY** → Ordenar rankings
- **FOREIGN KEY** → Integridade referencial
- **UNIQUE** → Evitar duplicatas

---

## 📚 Próximos Passos (Opcional)

- [ ] Adicionar gráficos de progresso (charts)
- [ ] Implementar sistema de conquistas completo
- [ ] Exportar relatórios em PDF
- [ ] Sincronização com Firebase (backup online)
- [ ] Dashboard para professores/administradores

---

**Boa sorte na feira FLIS! 🎉**

Qualquer dúvida sobre o banco de dados, consulte `database_helper.dart` - todos os métodos estão documentados!
