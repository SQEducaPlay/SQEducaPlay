# 🎮 Sistema Gamificado - SQEducaPlay

## 🌟 Visão Geral

Sistema completo de gamificação com níveis, conquistas, ranking e progresso do aluno.

## 📊 Funcionalidades Implementadas

### 1. **Sistema de Níveis**
Os alunos progridem através de 5 níveis baseados na pontuação:

| Nível | Pontos Necessários | Cor |
|-------|-------------------|-----|
| 🥉 Iniciante | 0 - 49 | Cinza |
| 🥈 Aprendiz | 50 - 149 | Verde |
| 🥇 Estudioso | 150 - 299 | Azul |
| 👑 Expert | 300 - 499 | Roxo |
| 🏆 Mestre | 500+ | Laranja |

### 2. **Sistema de Conquistas (15 Badges)**

#### Conquistas Gerais:
- 🎉 **Primeira Vitória** (10pts) - Complete seu primeiro quiz
- ⭐ **50 Pontos** (20pts) - Alcance 50 pontos totais
- 🏆 **100 Pontos** (50pts) - Alcance 100 pontos totais
- 💯 **Perfeição** (100pts) - Complete 5 quizes com 100% de acertos
- 📚 **Multidisciplinar** (50pts) - Complete quiz em todas as matérias
- 🌟 **Colecionador de Estrelas** (75pts) - Consiga 50 estrelas
- 🎯 **Dedicado** (30pts) - Complete 10 quizes

#### Conquistas por Matéria (40pts cada):
- 🔢 **Mestre da Matemática** - Complete 10 quizes de Matemática
- 📖 **Mestre do Português** - Complete 10 quizes de Português
- 🏛️ **Mestre da História** - Complete 10 quizes de História
- 🔬 **Mestre das Ciências** - Complete 10 quizes de Ciências
- 🌎 **Mestre da Geografia** - Complete 10 quizes de Geografia

#### Conquistas Especiais:
- 🎖️ **Infalível** (50pts) - Complete um quiz sem errar nenhuma
- ⚡ **Velocista** (30pts) - Complete um quiz em menos de 2 minutos
- 💪 **Persistente** (60pts) - Complete 5 quizes no mesmo dia

**Total de Pontos em Conquistas:** 685 pontos

### 3. **Sistema de Pontuação**

#### Pontos por Acerto:
- Cada resposta correta = 10 pontos base
- Bônus de estrelas adicionais

#### Pontos por Conquistas:
- Cada conquista desbloqueada dá pontos extras
- Pontos de conquistas são adicionados à pontuação total

### 4. **Ranking Global**
- Classificação por pontuação total
- Top 3 destacados com cores especiais:
  - 🥇 1º Lugar: Dourado
  - 🥈 2º Lugar: Prata
  - 🥉 3º Lugar: Bronze
- Visualização de posição individual

### 5. **Estatísticas Detalhadas**

#### Estatísticas Gerais:
- Total de pontos
- Total de estrelas
- Quizes completados
- Quizes perfeitos (100%)
- Taxa de acerto geral
- Posição no ranking

#### Por Matéria:
- Quantidade de quizes por matéria
- Taxa de acerto por matéria
- Acertos e erros contabilizados

### 6. **Perfil do Aluno**
Página completa com:
- Avatar personalizado
- Nível e progresso
- Barra de progresso para próximo nível
- Todas as estatísticas
- Conquistas desbloqueadas (com data)
- Conquistas a desbloquear
- Desempenho por matéria

## 📁 Arquivos Criados

### Modelos:
- `lib/models/conquista_model.dart` - Define conquistas e badges
- `lib/models/progresso_model.dart` - Gerencia progresso do aluno

### Serviços:
- `lib/services/progresso_service.dart` - Lógica de gamificação

### Páginas:
- `lib/pages/perfil_aluno_page.dart` - Perfil completo do aluno
- `lib/pages/ranking_page.dart` - Ranking global

## 🔌 Como Integrar

### 1. Adicionar botões na MateriasPage:

```dart
// Adicionar na AppBar ou no body:
actions: [
  IconButton(
    icon: const Icon(Icons.person),
    tooltip: 'Meu Perfil',
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PerfilAlunoPage(username: 'nome_do_usuario'),
        ),
      );
    },
  ),
  IconButton(
    icon: const Icon(Icons.leaderboard),
    tooltip: 'Ranking',
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RankingPage()),
      );
    },
  ),
]
```

### 2. Registrar resultado do quiz no JogoPage:

No final do quiz, quando calcular a pontuação:

```dart
final progressoService = ProgressoService();
progressoService.registrarResultadoQuiz(
  username: 'nome_do_usuario', // Pegar do login
  materia: widget.materia,
  pontos: pontuacao,
  estrelas: estrelas,
  acertos: totalAcertos,
  erros: totalErros,
  perfeito: totalErros == 0,
  tempoSegundos: tempoGasto, // Implementar timer
);
```

### 3. Mostrar conquistas desbloqueadas:

Após registrar resultado, verificar e mostrar novas conquistas:

```dart
// Buscar conquistas recém desbloqueadas e mostrar dialog
```

## 🎨 Recursos Visuais

- **Cores por Nível**: Cinza → Verde → Azul → Roxo → Laranja
- **Ícones Personalizados**: Cada conquista tem ícone e cor únicos
- **Medalhas no Ranking**: 🥇🥈🥉 para top 3
- **Barras de Progresso**: Visuais e animadas
- **Cards Coloridos**: Por matéria e por conquista

## 📈 Métricas Rastreadas

1. **Progresso Individual**:
   - Pontos totais
   - Estrelas coletadas
   - Quizes completados
   - Taxa de acerto

2. **Por Matéria**:
   - Quantidade de quizes
   - Acertos e erros
   - Taxa de sucesso

3. **Conquistas**:
   - Desbloqueadas
   - Em progresso
   - Data de desbloqueio

4. **Ranking**:
   - Posição global
   - Comparação com outros alunos

## 🚀 Próximas Melhorias Sugeridas

1. **Persistência de Dados**: Salvar em SQLite ou Firebase
2. **Timer no Quiz**: Rastrear tempo de conclusão
3. **Gráficos**: Visualizar evolução ao longo do tempo
4. **Notificações**: Avisar sobre novas conquistas
5. **Comparar com Amigos**: Ranking por turma/escola
6. **Recompensas Visuais**: Animações ao desbloquear conquistas
7. **Desafios Diários**: Quests e missões especiais
8. **Avatares Customizáveis**: Desbloquear com conquistas

## ✅ Status

- ✅ Modelos criados
- ✅ Serviços implementados
- ✅ Página de perfil completa
- ✅ Página de ranking completa
- ⏳ Integração com JogoPage (pendente)
- ⏳ Persistência de dados (pendente)
- ⏳ Animações de conquistas (pendente)

## 🎯 Diferencial

Este sistema transforma o aprendizado em uma experiência envolvente e competitiva, mantendo os alunos motivados através de:
- **Feedback imediato** com pontos e estrelas
- **Metas claras** através dos níveis
- **Reconhecimento** com conquistas
- **Competição saudável** através do ranking
- **Progresso visível** com estatísticas detalhadas
