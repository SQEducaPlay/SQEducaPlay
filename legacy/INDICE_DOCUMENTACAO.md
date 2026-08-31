# 📚 ÍNDICE DE DOCUMENTAÇÃO - SQEducaPlay

Bem-vindo à documentação completa do **SQEducaPlay**! Este arquivo serve como ponto de partida para navegar toda a documentação do projeto.

---

## 📋 DOCUMENTOS PRINCIPAIS

### 1. **[ESPECIFICACAO_REQUISITOS.md](ESPECIFICACAO_REQUISITOS.md)** 
   📌 **O QUE O APP FAZ?**
   - Visão geral do projeto
   - 30+ Requisitos Funcionais (RF) com prioridades
   - 16 Requisitos Não-Funcionais (RNF)
   - 8 Casos de Uso (UC)
   - Critérios de Aceitação
   - Glossário de termos
   
   **Leia se você quer:** Entender o que é SQEducaPlay, suas features, o que deve fazer

   **Públicos:** Product Owners, QA, Stakeholders

---

### 2. **[DOCUMENTACAO_TECNICA.md](DOCUMENTACAO_TECNICA.md)**
   🏗️ **COMO O APP FOI CONSTRUÍDO?**
   - Arquitetura em 3 camadas
   - Banco de dados completo (schema SQL)
   - 5 Serviços principais (Singletons)
   - Fluxos de dados com diagramas
   - Stack tecnológico (Flutter 3.43, Dart 3.12, SQLite)
   - Modelos de dados
   - Configurações (Android, iOS, Web)
   - Checklist de desenvolvimento
   
   **Leia se você quer:** Entender arquitetura, como dados fluem, banco de dados, tecnologias

   **Públicos:** Desenvolvedores, Arquitetos, DevOps

---

### 3. **[GUIA_DESENVOLVIMENTO.md](GUIA_DESENVOLVIMENTO.md)**
   🚀 **COMO DESENVOLVER NO PROJETO?**
   - Configuração do ambiente (Flutter, Android Studio, Xcode)
   - Como rodar localmente
   - Convenções de código (Dart/Flutter)
   - Padrões (Singletons, StatefulWidgets, Tratamento de erros)
   - Como adicionar novas features
   - Testando localmente
   - Build para Android/iOS/Web
   - Troubleshooting
   - Análise de código e linting
   
   **Leia se você quer:** Começar a desenvolver, adicionar features, fazer builds

   **Públicos:** Desenvolvedores, QA, Contribuidores

### 5. **[PLANO_EXPERIENCIA_INFANTIL_ALUNO.md](PLANO_EXPERIENCIA_INFANTIL_ALUNO.md)**
   🎨 **COMO EVOLUIR A EXPERIÊNCIA DO ALUNO?**
   - Direção visual infantil para o 2º ao 5º ano
   - Sugestões para matérias, tópicos, quizzes, perfil e ranking
   - Missões, níveis, estrelas e conquistas com papéis separados
   - Recomendações de acessibilidade, privacidade e assets
   - Roadmap dividido por impacto e esforço

   **Leia se você quer:** Planejar futuras melhorias visuais e de experiência sem alterar a implementação atual

   **Públicos:** Produto, design, desenvolvimento, QA e educadores

---

### 4. **[README.md](README.md)** (arquivo padrão)
   📖 **VISÃO GERAL RÁPIDA**
   - O que é SQEducaPlay (resumido)
   - Como instalar e rodar
   - Links para documentação completa

---

## 🎯 GUIA RÁPIDO POR PERSONA

### 👨‍💼 **Gerente de Projeto / Product Owner**
1. Leia: [ESPECIFICACAO_REQUISITOS.md](ESPECIFICACAO_REQUISITOS.md) — Visão Geral (seção 1)
2. Leia: [ESPECIFICACAO_REQUISITOS.md](ESPECIFICACAO_REQUISITOS.md) — Requisitos Funcionais (seção 2)
3. Entenda: Prioridades (Alta/Média/Baixa)

### 👨‍💻 **Desenvolvedor Novo no Projeto**
1. Leia: [README.md](README.md) — Overview
2. Leia: [GUIA_DESENVOLVIMENTO.md](GUIA_DESENVOLVIMENTO.md) — Seção 1 (Setup ambiente)
3. Leia: [DOCUMENTACAO_TECNICA.md](DOCUMENTACAO_TECNICA.md) — Seção 1-2 (Arquitetura)
4. Leia: [GUIA_DESENVOLVIMENTO.md](GUIA_DESENVOLVIMENTO.md) — Seção 4 (Padrões)
5. Comece a codar! 🎉

### 👨‍🔬 **QA / Testador**
1. Leia: [ESPECIFICACAO_REQUISITOS.md](ESPECIFICACAO_REQUISITOS.md) — Casos de Uso (seção 4)
2. Leia: [ESPECIFICACAO_REQUISITOS.md](ESPECIFICACAO_REQUISITOS.md) — Critérios de Aceitação (seção 5)
3. Leia: [GUIA_DESENVOLVIMENTO.md](GUIA_DESENVOLVIMENTO.md) — Seção 6 (Testando localmente)
4. Comece a testar cases

### 👨‍🏫 **Educador / Gestor de Conteúdo**
1. Leia: [ESPECIFICACAO_REQUISITOS.md](ESPECIFICACAO_REQUISITOS.md) — Visão Geral
2. Foco: Requisitos RF-101 a RF-106 (Conteúdo Educacional)
3. Foco: Requisitos RF-301 a RF-314 (Gamificação)

### 🏗️ **Arquiteto de Software**
1. Leia: [DOCUMENTACAO_TECNICA.md](DOCUMENTACAO_TECNICA.md) — Seções 1-4 (Arquitetura + DB)
2. Leia: [DOCUMENTACAO_TECNICA.md](DOCUMENTACAO_TECNICA.md) — Seção 5 (Fluxos principais)
3. Leia: [DOCUMENTACAO_TECNICA.md](DOCUMENTACAO_TECNICA.md) — Seção 6-7 (Modelos + Tecnologias)

---

## 🔄 FLUXOS PRINCIPAIS (Quick Reference)

### 1️⃣ Fluxo de Login
```
Login Screen → UserService.login() → Valida credenciais 
→ Se correto: sessão criada (SharedPreferences) 
→ Redireciona para home (admin ou aluno)
```
**Arquivo:** `lib/login_page.dart` + `lib/services/user_service.dart`

### 2️⃣ Fluxo de Quiz
```
MaterialasPage → TopicosPage → JogoPage (quiz)
→ Aluno responde → Calcula resultado 
→ Salva em AppDatabase → Atualiza ProgressoService 
→ Verifica conquistas → Resultado screen
```
**Arquivos:** `lib/jogo_page.dart` + `lib/services/progresso_service.dart` + `lib/database/app_database.dart`

### 3️⃣ Fluxo de Gamificação
```
Quiz completo → ProgressoService.registrarResultadoQuiz()
→ Calcula pontos/nível → Verifica conquistas desbloqueadas
→ Se nova conquista: CelebrationService → Confete + Som
→ Atualiza Ranking em tempo real
```
**Arquivos:** `lib/services/progresso_service.dart` + `lib/services/celebration_service.dart`

### 4️⃣ Fluxo de Ranking
```
PerfilAlunoPage → ProgressoService.getRanking()
→ Agrupa e ordena alunos por pontuação
→ Retorna top 3 + posição do aluno
→ RankingPage exibe com filtros (Turma, Escola, Série)
```
**Arquivos:** `lib/pages/ranking_tabs_page.dart` + `lib/services/progresso_service.dart`

---

## 📊 ESTRUTURA DE DADOS RESUMIDA

### Tabelas Principais (SQLite)
| Tabela | Função |
|--------|--------|
| `users` | Usuários (admin + alunos) |
| `partidas` | Histórico de quizes |
| `user_stats` | Estatísticas por matéria |
| `user_progress` | Tópicos completados |

**Detalhes completos:** Ver [DOCUMENTACAO_TECNICA.md](DOCUMENTACAO_TECNICA.md) — Seção 3

---

## 🎮 GAMIFICAÇÃO (Resumo)

### Níveis (5 total)
- 🥉 Iniciante (0-49 pts)
- 🥈 Aprendiz (50-149 pts)
- 🥇 Estudioso (150-299 pts)
- 👑 Expert (300-499 pts)
- 🏆 Mestre (500+ pts)

### Conquistas (15 total)
- Gerais: Primeira Vitória, Multidisciplinar, Colecionador
- Por Matéria: Mestre da Matemática, Mestre do Português
- Especiais: Infalível, Velocista, Persistente

### Ranking
- Top 3 global (Ouro/Prata/Bronze)
- Separado por matéria
- Filtros: Turma, Escola, Série

**Detalhes completos:** Ver [ESPECIFICACAO_REQUISITOS.md](ESPECIFICACAO_REQUISITOS.md) — Seção 2.4

---

## 🔐 SEGURANÇA & LGPD

### Conformidade
- ✅ Senhas hasheadas (não em plain text)
- ✅ Privacidade de dados (LGPD)
- ✅ Consentimento parental (recomendado)
- ✅ Anonimização opcional de nomes
- ✅ Validação contra SQL injection

### Configurações de Privacidade
- Anonimização de nomes em rankings
- Ocultar dados de escola
- Desabilitar efeitos visuais/sons

**Detalhes:** Ver [ESPECIFICACAO_REQUISITOS.md](ESPECIFICACAO_REQUISITOS.md) — Seção 2.7

---

## 📱 PLATAFORMAS & BUILDS

| Plataforma | Status | Build Command |
|-----------|--------|----------------|
| Android | ✅ Pronto | `flutter build apk --release` |
| iOS | ⏳ Aguardando Mac + Apple Dev Account | `flutter build ios --release` |
| Web | ✅ Experimental | `flutter build web --release` |

**Como buildar:** Ver [GUIA_DESENVOLVIMENTO.md](GUIA_DESENVOLVIMENTO.md) — Seção 7

---

## 🚨 ARQUIVOS CRÍTICOS (Cuidado ao editar!)

| Arquivo | Por quê? | Risco |
|---------|---------|-------|
| `lib/database/app_database.dart` | Schema SQLite | Quebra builds anteriores |
| `lib/services/progresso_service.dart` | Lógica de gamificação | Pontos/níveis incorretos |
| `lib/jogo_page.dart` | Cálculo de resultado | Quiz não funciona |
| `main.dart` | Inicialização de serviços | App não inicia |

**Boas práticas:** Ver [GUIA_DESENVOLVIMENTO.md](GUIA_DESENVOLVIMENTO.md) — Seção 2

---

## 🔗 LINKS ÚTEIS

### Documentação Externa
- [Flutter Official Docs](https://flutter.dev/docs)
- [Dart Language Guide](https://dart.dev/guides)
- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [BNCC - Base Curricular](https://www.gov.br/cidadania/pt-br/acesso-a-informacao/participacao-social/consultas-publicas/educacao/bncc)

### Repositórios
- **GitHub:** [KeinanSZ/SQEducaPlay](https://github.com/KeinanSZ/SQEducaPlay)
- **Branch padrão:** `main`

### Contato
- **Desenvolvedor Principal:** Keinan
- **Email:** (keinan.souza2@gmail.com)
- **Issues:** [GitHub Issues](https://github.com/KeinanSZ/SQEducaPlay/issues)

---

## 🎯 ROADMAP E TO-DO

### MVP (Pronto)
- ✅ Login/Registro de alunos
- ✅ Quiz com múltipla escolha
- ✅ Sistema de pontos e níveis (5 níveis)
- ✅ Badges e conquistas (15 total)
- ✅ Ranking em tempo real
- ✅ Perfil do aluno com estatísticas
- ✅ Banco de dados SQLite
- ✅ Áudio (música + efeitos)
- ✅ TTS (Text-to-Speech)

### Próximas Versões
- 📋 Relatórios avançados para admin
- 📋 Multi-idioma (EN, ES)
- 📋 Sistema de desafios (weekly quests)
- 📋 Social (compartilhar badges)
- 📋 Analytics e heatmaps

---

## 📝 VERSIONAMENTO

**Versão Atual:** 1.0  
**Flutter:** 3.43.0 beta  
**Dart:** 3.12.0  
**Data de Criação da Documentação:** 15/05/2026  
**Status:** Documentação Completa ✅

---

## 🎓 PRÓXIMOS PASSOS

1. **Primeiro Acesso?**
   - Clone o repo
   - Instale dependências: `flutter pub get`
   - Configure emulador Android/iOS
   - Rode: `flutter run`

2. **Quer Adicionar Feature?**
   - Leia [GUIA_DESENVOLVIMENTO.md](GUIA_DESENVOLVIMENTO.md) — Seção 5
   - Entenda padrões em [GUIA_DESENVOLVIMENTO.md](GUIA_DESENVOLVIMENTO.md) — Seção 4
   - Faça commit com convenção [GUIA_DESENVOLVIMENTO.md](GUIA_DESENVOLVIMENTO.md) — Seção 10

3. **Quer Testar?**
   - Leia [GUIA_DESENVOLVIMENTO.md](GUIA_DESENVOLVIMENTO.md) — Seção 6
   - Use credenciais de teste
   - Reporte bugs em GitHub Issues

4. **Precisa de Suporte?**
   - Verifique Troubleshooting em [GUIA_DESENVOLVIMENTO.md](GUIA_DESENVOLVIMENTO.md) — Seção 8
   - Procure por seu erro em Issues
   - Crie issue se não encontrar

---

## 📞 SUPORTE & CONTRIBUIÇÃO

**Para reportar bugs:**  
→ [GitHub Issues](https://github.com/KeinanSZ/SQEducaPlay/issues/new)

**Para contribuir:**  
→ Fork o repo → Crie branch → Faça PR  
→ Siga convenções em [GUIA_DESENVOLVIMENTO.md](GUIA_DESENVOLVIMENTO.md) — Seção 10

**Para sugerir melhorias:**  
→ Discussões no GitHub ou issues com label `enhancement`

---

**Mantido por:** Keinan  
**Última atualização:** 03/08/2026  
**Status:** ✅ Completo e Atualizado
