# 📋 ESPECIFICAÇÃO DE REQUISITOS - SQEducaPlay

## 1. VISÃO GERAL DO PROJETO

### 1.1 Descrição
**SQEducaPlay** é um aplicativo educacional gamificado desenvolvido em **Flutter/Dart** para crianças do Ensino Fundamental I (2º ao 5º ano) de escolas municipais de Saquarema-RJ. O objetivo é tornar o aprendizado divertido e interativo através de quizes alinhados à BNCC (Base Nacional Comum Curricular), com um sistema completo de gamificação.

### 1.2 Público-alvo
- 👧👦 **Alunos**: Crianças de 7-11 anos (Ensino Fundamental I)
- 👨‍🏫 **Administradores**: Professores e gestores
- 📍 **Escolas**: 16 escolas municipais de Saquarema-RJ

### 1.3 Plataformas Suportadas
- ✅ Android (Play Store - quando pronto)
- ✅ iOS (App Store - quando houver Mac + Apple Developer Account)
- ✅ Web (Navegadores - versão experimental)

---

## 2. REQUISITOS FUNCIONAIS (RF)

### 2.1 Autenticação e Autorização

| ID | Requisito | Descrição | Prioridade |
|----|-----------|-----------|-----------|
| **RF-001** | Login de Usuário | Sistema deve permitir login com username e password | 🔴 ALTA |
| **RF-002** | Registro de Aluno | Alunos podem registrar-se fornecendo: nome completo, série, escola | 🔴 ALTA |
| **RF-003** | Conta Admin Especial | Usuário "Keinan" (admin) tem acesso restrito de gerenciamento | 🔴 ALTA |
| **RF-004** | Autenticação Persistente | Aplicativo mantém sessão do usuário após sair/voltar | 🟡 MÉDIA |
| **RF-005** | Validação de Dados | Sistema valida campos obrigatórios em login/registro | 🔴 ALTA |
| **RF-006** | Roles e Permissões | Admin e Student têm diferentes níveis de acesso | 🔴 ALTA |

### 2.2 Gerenciamento de Conteúdo Educacional

| ID | Requisito | Descrição | Prioridade |
|----|-----------|-----------|-----------|
| **RF-101** | Seleção de Matéria | Aluno pode escolher entre Português e Matemática | 🔴 ALTA |
| **RF-102** | Seleção de Ano/Série | Aluno pode escolher 2º, 3º, 4º ou 5º ano | 🔴 ALTA |
| **RF-103** | Seleção de Tópico | Sistema exibe tópicos BNCC por matéria e série selecionada | 🔴 ALTA |
| **RF-104** | Visualização de Tópicos | Cada tópico mostra: nome, quantidade de questões, ícone | 🟡 MÉDIA |
| **RF-105** | Conteúdo Alinhado à BNCC | Todas as questões estão alinhadas aos objetivos da BNCC | 🔴 ALTA |
| **RF-106** | Progressão de Tópicos | Aluno não consegue pular tópicos (ordem linear) | 🟡 MÉDIA |

### 2.3 Sistema de Quiz/Jogo

| ID | Requisito | Descrição | Prioridade |
|----|-----------|-----------|-----------|
| **RF-201** | Iniciar Quiz | Aluno pode iniciar quiz de um tópico selecionado | 🔴 ALTA |
| **RF-202** | Questões Múltipla Escolha | Questões apresentadas com 4 opções de resposta | 🔴 ALTA |
| **RF-203** | Visualização Geométrica (Math) | Matemática mostra representações visuais (figuras, números) | 🟡 MÉDIA |
| **RF-204** | Leitura em Voz Alta (TTS) | Sistema lê questão e opções automaticamente | 🟡 MÉDIA |
| **RF-205** | Cronômetro | Quiz possui timer mostrando tempo decorrido | 🟡 MÉDIA |
| **RF-206** | Validação de Resposta | Sistema verifica resposta e exibe feedback imediato | 🔴 ALTA |
| **RF-207** | Progresso no Quiz | Exibe questão atual / total de questões (ex: 3/10) | 🔴 ALTA |
| **RF-208** | Finalizar Quiz | Aluno pode terminar quiz antecipadamente | 🟡 MÉDIA |
| **RF-209** | Resultado Final | Sistema calcula e exibe: pontuação, estrelas, acertos | 🔴 ALTA |

### 2.4 Sistema de Gamificação

#### 2.4.1 Pontuação e Estrelas

| ID | Requisito | Descrição | Prioridade |
|----|-----------|-----------|-----------|
| **RF-301** | Cálculo de Pontos | +10 pontos por resposta correta (base) | 🔴 ALTA |
| **RF-302** | Bônus de Estrelas | Estrelas adicionais conforme desempenho (0-3 estrelas) | 🔴 ALTA |
| **RF-303** | Pontuação Total | Sistema acumula pontos de todos os quizes | 🔴 ALTA |
| **RF-304** | Histórico de Pontos | Salva cada quiz: data, matéria, pontos, tempo | 🔴 ALTA |

#### 2.4.2 Sistema de Níveis

| ID | Requisito | Descrição | Prioridade |
|----|-----------|-----------|-----------|
| **RF-305** | 5 Níveis de Progressão | Iniciante (0-49) → Aprendiz (50-149) → Estudioso (150-299) → Expert (300-499) → Mestre (500+) | 🔴 ALTA |
| **RF-306** | Mudança de Nível | Sistema atualiza nível automático ao atingir pontuação | 🔴 ALTA |
| **RF-307** | Cores por Nível | Cada nível tem cor visual distincta (Cinza, Verde, Azul, Roxo, Laranja) | 🟡 MÉDIA |

#### 2.4.3 Sistema de Conquistas (Badges)

| ID | Requisito | Descrição | Prioridade |
|----|-----------|-----------|-----------|
| **RF-308** | 15 Conquistas Totais | Sistema oferece 15 badges diferentes para desbloquear | 🔴 ALTA |
| **RF-309** | Badges Gerais | Primeira Vitória, 50 Pontos, 100 Pontos, Perfeição (5 quizes 100%) | 🔴 ALTA |
| **RF-310** | Badges por Matéria | Mestre da Matemática, Mestre do Português (10 quizes cada) | 🟡 MÉDIA |
| **RF-311** | Badges Especiais | Infalível, Velocista (<2min), Persistente (5 quizes/dia), Multidisciplinar, Colecionador | 🟡 MÉDIA |
| **RF-312** | Desbloqueio Automático | Badges desbloqueadas automaticamente ao cumprir condição | 🔴 ALTA |
| **RF-313** | Exibição de Conquistas | Perfil do aluno mostra todas as conquistas desbloqueadas | 🔴 ALTA |
| **RF-314** | Celebração | Animação (confete), som e mensagem ao desbloquear badge | 🟡 MÉDIA |

#### 2.4.4 Sistema de Ranking

| ID | Requisito | Descrição | Prioridade |
|----|-----------|-----------|-----------|
| **RF-315** | Ranking Global | Lista top 3 alunos com maior pontuação total | 🔴 ALTA |
| **RF-316** | Ranking por Matéria | Ranking separado para Português e Matemática | 🔴 ALTA |
| **RF-317** | Filtro de Ranking | Ranking pode ser filtrado por: Turma, Escola, Série | 🟡 MÉDIA |
| **RF-318** | Medalhas de Ranking | Top 3: Ouro (1º), Prata (2º), Bronze (3º) com cores/ícones | 🟡 MÉDIA |
| **RF-319** | Atualização em Tempo Real | Ranking atualiza após cada quiz finalizado | 🔴 ALTA |
| **RF-320** | Posição do Aluno | Aluno pode ver sua posição no ranking | 🔴 ALTA |

### 2.5 Perfil e Estatísticas do Aluno

| ID | Requisito | Descrição | Prioridade |
|----|-----------|-----------|-----------|
| **RF-401** | Página de Perfil | Exibe: avatar, nome, série, escola, nível, pontos, estrelas | 🔴 ALTA |
| **RF-402** | Histórico de Quizes | Lista de últimos quizes com: matéria, data, pontos, acertos | 🔴 ALTA |
| **RF-403** | Estatísticas por Matéria | Taxa de acerto (%) por Português e Matemática | 🟡 MÉDIA |
| **RF-404** | Gráficos de Desempenho | Visualização visual do progresso (barras, linhas) | 🟡 MÉDIA |
| **RF-405** | Progresso de Tópicos | Mostra quais tópicos foram completados | 🟡 MÉDIA |
| **RF-406** | Avatar do Aluno | Aluno pode ter avatar/personagem customizado | 🟢 BAIXA |

### 2.6 Gerenciamento Admin

| ID | Requisito | Descrição | Prioridade |
|----|-----------|-----------|-----------|
| **RF-501** | Dashboard Admin | Home especial para admin com opções de gerenciamento | 🔴 ALTA |
| **RF-502** | Gerenciar Escolas | Admin pode adicionar/remover/editar escolas | 🟡 MÉDIA |
| **RF-503** | Gerenciar Turmas | Admin pode criar turmas e vincular alunos | 🟡 MÉDIA |
| **RF-504** | Ranking Admin | Admin vê ranking de alunos e escolas | 🟡 MÉDIA |
| **RF-505** | Relatórios | Admin pode gerar relatórios de desempenho | 🟢 BAIXA |

### 2.7 Configurações e Privacidade (LGPD)

| ID | Requisito | Descrição | Prioridade |
|----|-----------|-----------|-----------|
| **RF-601** | Anonimização de Nomes | Admin pode ativar/desativar anonimização em rankings | 🟡 MÉDIA |
| **RF-602** | Ocultar Escola | Admin pode ocultar dados de escola em rankings | 🟡 MÉDIA |
| **RF-603** | Efeitos Visuais | Admin pode desabilitar confete/celebrações | 🟡 MÉDIA |
| **RF-604** | Música de Fundo | Admin/Aluno pode ativar/desativar sons | 🟡 MÉDIA |
| **RF-605** | Filtro de Escopo | Alunos podem ver ranking apenas da própria escola (configurável) | 🟡 MÉDIA |

### 2.8 Áudio e Acessibilidade

| ID | Requisito | Descrição | Prioridade |
|----|-----------|-----------|-----------|
| **RF-701** | Música de Fundo | Música em loop durante o jogo | 🟡 MÉDIA |
| **RF-702** | Efeitos Sonoros | Sons para: acerto, erro, vitória, desbloquear badge | 🟡 MÉDIA |
| **RF-703** | Text-to-Speech | Questões podem ser lidas em voz alta | 🟡 MÉDIA |
| **RF-704** | Mute/Unmute | Aluno pode desativar sons a qualquer momento | 🟡 MÉDIA |
| **RF-705** | Persistir Preferências | Preferências de áudio salvam para próxima sessão | 🟡 MÉDIA |

---

## 3. REQUISITOS NÃO-FUNCIONAIS (RNF)

### 3.1 Performance

| ID | Requisito | Descrição | Prioridade |
|----|-----------|-----------|-----------|
| **RNF-001** | Tempo de Resposta | Aplicativo responde em <2 segundos a ações do usuário | 🔴 ALTA |
| **RNF-002** | Carregamento de Quiz | Quiz carrega em <3 segundos | 🟡 MÉDIA |
| **RNF-003** | Eficiência de Banco | Queries no SQLite retornam em <500ms | 🔴 ALTA |
| **RNF-004** | Uso de Memória | Aplicativo ocupa <150MB de RAM em idle | 🟡 MÉDIA |
| **RNF-005** | Capacidade de Usuários | Sistema suporta >1.000 alunos simultâneos | 🟢 BAIXA |

### 3.2 Confiabilidade e Disponibilidade

| ID | Requisito | Descrição | Prioridade |
|----|-----------|-----------|-----------|
| **RNF-101** | Offline First | Aplicativo funciona completamente offline | 🔴 ALTA |
| **RNF-102** | Sincronização | Dados sincronizam quando internet retorna | 🟡 MÉDIA |
| **RNF-103** | Integridade de Dados | Quizes completados não são perdidos (persistência garantida) | 🔴 ALTA |
| **RNF-104** | Recuperação de Erro | Sistema mostra mensagens claras em caso de falha | 🟡 MÉDIA |
| **RNF-105** | Uptime | Aplicativo deve ter uptime >99% | 🟢 BAIXA |

### 3.3 Usabilidade

| ID | Requisito | Descrição | Prioridade |
|----|-----------|-----------|-----------|
| **RNF-201** | Interface Intuitiva | UI/UX projetada para crianças (>7 anos) | 🔴 ALTA |
| **RNF-202** | Cores Vibrantes | Cores alegres e vibrantes adequadas para público infantil | 🟡 MÉDIA |
| **RNF-203** | Fonte Legível | Fontes claras e tamanho adequado (>14px) | 🟡 MÉDIA |
| **RNF-204** | Ícones Reconhecíveis | Ícones são claros e reconhecíveis por crianças | 🟡 MÉDIA |
| **RNF-205** | Navegação Simples | Menu com max 3 níveis de profundidade | 🟡 MÉDIA |
| **RNF-206** | Feedback Visual | Ações sempre geram feedback visual (botão pressionado, animação) | 🟡 MÉDIA |

### 3.4 Segurança

| ID | Requisito | Descrição | Prioridade |
|----|-----------|-----------|-----------|
| **RNF-301** | Proteção de Senhas | Senhas hasheadas no banco (não em plain text) | 🔴 ALTA |
| **RNF-302** | Dados LGPD | Conformidade com Lei Geral de Proteção de Dados (LGPD) | 🔴 ALTA |
| **RNF-303** | Consentimento Parental | Sistema deve coletar consentimento de responsáveis | 🟡 MÉDIA |
| **RNF-304** | Privacidade de Dados | Dados de crianças não devem ser compartilhados com terceiros | 🔴 ALTA |
| **RNF-305** | Validação de Entrada | Todas as entradas validadas contra injeção SQL | 🔴 ALTA |

### 3.5 Escalabilidade

| ID | Requisito | Descrição | Prioridade |
|----|-----------|-----------|-----------|
| **RNF-401** | Adicionar Conteúdo | Sistema permite adicionar novas questões facilmente | 🟡 MÉDIA |
| **RNF-402** | Novos Tópicos | Fácil adicionar tópicos BNCC sem modificar código | 🟡 MÉDIA |
| **RNF-403** | Multi-idioma | Arquitetura preparada para expansão multilíngue | 🟢 BAIXA |
| **RNF-404** | Novos Badges | Simples adicionar novas conquistas sem refactor | 🟡 MÉDIA |

### 3.6 Compatibilidade

| ID | Requisito | Descrição | Prioridade |
|----|-----------|-----------|-----------|
| **RNF-501** | Android | Suporta Android 8.0+ (API 26+) | 🔴 ALTA |
| **RNF-502** | iOS | Suporta iOS 12.0+ (após Mac/Apple Dev Account) | 🔴 ALTA |
| **RNF-503** | Web | Funciona em Chrome, Firefox, Safari (browsers modernos) | 🟡 MÉDIA |
| **RNF-504** | Responsividade | UI adapta a diferentes tamanhos de tela | 🟡 MÉDIA |
| **RNF-505** | Orientação | Apenas portrait (vertical) em mobile | 🟡 MÉDIA |

### 3.7 Manutenibilidade

| ID | Requisito | Descrição | Prioridade |
|----|-----------|-----------|-----------|
| **RNF-601** | Código Limpo | Código segue padrões Dart/Flutter | 🟡 MÉDIA |
| **RNF-602** | Documentação | Código comentado, README completo | 🟡 MÉDIA |
| **RNF-603** | Versionamento | Controle de versão com Git | 🟡 MÉDIA |
| **RNF-604** | CI/CD | Pipeline automático para builds Android/iOS | 🟡 MÉDIA |

---

## 4. CASOS DE USO (USE CASES)

### UC-001: Fazer Login
**Ator:** Aluno / Admin
**Pré-condição:** Usuário cadastrado no sistema
**Fluxo Principal:**
1. Usuário abre app e clica "Login"
2. Insere username e password
3. Sistema valida credenciais
4. Se correto → Redireciona para home
5. Se errado → Exibe mensagem de erro

**Exceção:** Campos vazios → Exibe aviso

---

### UC-002: Registrar Novo Aluno
**Ator:** Aluno (novo)
**Pré-condição:** App aberto, usuário sem conta
**Fluxo Principal:**
1. Usuário clica "Registrar"
2. Insere: Nome completo, Série, Escola
3. Sistema valida dados
4. Salva novo usuário no banco
5. Redireciona para login

**Exceção:** Dados inválidos → Exibe mensagem de erro

---

### UC-003: Selecionar Matéria e Iniciar Quiz
**Ator:** Aluno
**Pré-condição:** Aluno logado
**Fluxo Principal:**
1. Aluno vai para MateriasPage
2. Seleciona Português ou Matemática
3. Escolhe série (2º-5º ano)
4. Seleciona tópico da lista
5. Clica "Iniciar Quiz"
6. JogoPage abre com primeira questão

**Fluxo Alternativo:**
- Se tópico já completado → Mostra opção de "Refazer" ou "Ver Resultado"

---

### UC-004: Responder Questão do Quiz
**Ator:** Aluno
**Pré-condição:** Quiz iniciado
**Fluxo Principal:**
1. Aluno lê questão (ou escuta com TTS)
2. Aluno seleciona uma das 4 opções
3. Sistema valida resposta
4. Se correto → Som de acerto + +10 pontos
5. Se errado → Som de erro + 0 pontos
6. Próxima questão carrega
7. Ao final → Exibe resultado

---

### UC-005: Visualizar Perfil e Conquistas
**Ator:** Aluno
**Pré-condição:** Aluno logado, completou quizes
**Fluxo Principal:**
1. Aluno clica em "Perfil"
2. Exibe: Nome, Nível, Pontos, Estrelas, Conquistas desbloqueadas
3. Aluno pode scrollear para ver mais detalhes
4. Clica em conquista para ver descrição

---

### UC-006: Visualizar Ranking
**Ator:** Aluno
**Pré-condição:** Aluno logado
**Fluxo Principal:**
1. Aluno clica em "Ranking"
2. Sistema exibe top 3 (Ouro, Prata, Bronze)
3. Mostra posição do aluno
4. Pode filtrar por: Turma, Escola, Série
5. Tabs para Português e Matemática separados

---

### UC-007: Admin Gerenciar Escolas
**Ator:** Admin
**Pré-condição:** Admin logado (username: Keinan)
**Fluxo Principal:**
1. Admin vai para "Gerenciar Escolas"
2. Vê lista de 16 escolas municipais
3. Pode: Adicionar nova escola, Editar, Remover
4. Salva mudanças no banco

---

### UC-008: Admin Configurar Privacidade (LGPD)
**Ator:** Admin
**Pré-condição:** Admin logado
**Fluxo Principal:**
1. Admin acessa "Configurações de Privacidade"
2. Ativa/desativa: Anonimização, Ocultar Escola, Efeitos Visuais, Sons
3. Salva preferências
4. Configurações aplicadas para todos os usuários

---

## 5. CRITÉRIOS DE ACEITAÇÃO (AC)

### AC-001: Login
- [ ] AC1.1: Usuário com credenciais corretas consegue logar
- [ ] AC1.2: Usuário com credenciais incorretas vê mensagem de erro
- [ ] AC1.3: Campos obrigatórios não podem estar vazios
- [ ] AC1.4: Sessão persiste após sair do app

### AC-002: Quiz
- [ ] AC2.1: Quiz carrega todas as questões corretamente
- [ ] AC2.2: Resposta correta adiciona +10 pontos
- [ ] AC2.3: Resposta incorreta não adiciona pontos
- [ ] AC2.4: Quiz salva no banco após finalizar
- [ ] AC2.5: Cronômetro funciona corretamente

### AC-003: Gamificação
- [ ] AC3.1: Pontos acumulam de todos os quizes
- [ ] AC3.2: Nível muda automaticamente ao atingir threshold
- [ ] AC3.3: Conquista desbloqueia ao cumprir condição
- [ ] AC3.4: Celebração (confete + som) ao desbloquear badge
- [ ] AC3.5: Ranking atualiza em tempo real

### AC-004: Perfil
- [ ] AC4.1: Perfil exibe nível, pontos, estrelas corretos
- [ ] AC4.2: Conquistas desbloqueadas aparecem
- [ ] AC4.3: Histórico de quizes carrega
- [ ] AC4.4: Estatísticas por matéria calculadas corretamente

### AC-005: LGPD/Privacidade
- [ ] AC5.1: Configurações de privacidade salvam
- [ ] AC5.2: Anonimização funciona quando ativada
- [ ] AC5.3: Dados não são compartilhados
- [ ] AC5.4: Senhas são hasheadas no banco

---

## 6. GLOSSÁRIO

| Termo | Definição |
|-------|-----------|
| **BNCC** | Base Nacional Comum Curricular - padrão educacional brasileiro |
| **Badge** | Conquista visual desbloqueável ao cumprir critério |
| **LGPD** | Lei Geral de Proteção de Dados - legislação de privacidade Brasil |
| **Quiz** | Jogo com perguntas múltipla escolha |
| **Tópico** | Agrupamento de questões por assunto BNCC |
| **Turma** | Agrupamento de alunos por série/escola |
| **TTS** | Text-to-Speech - leitura de texto em voz alta |
| **SQLite** | Banco de dados local embarcado no app |
| **Gamificação** | Uso de elementos de jogos para engajar usuários |
| **Ranking** | Classificação de alunos por pontuação |
| **Nível** | Progressão do aluno (5 níveis totais) |
| **Estrelas** | Pontos adicionais ganhos em cada quiz |

---

## 7. PRIORIDADES

### 🔴 ALTA (MVP - Must Have)
- Autenticação e Login
- Quiz funcionando
- Cálculo de Pontos e Nível
- Ranking básico
- Salvamento no banco
- Conformidade LGPD

### 🟡 MÉDIA (Should Have)
- TTS (leitura em voz alta)
- Visualizações geométricas
- Gerenciamento de escolas/turmas
- Relatórios admin
- Som/Música
- Badges e Conquistas

### 🟢 BAIXA (Nice to Have)
- Avatar customizado
- Relatórios avançados
- Multi-idioma
- Gráficos complexos

---

**Data de Criação:** 15/05/2026
**Versão:** 1.0
**Status:** Em revisão
