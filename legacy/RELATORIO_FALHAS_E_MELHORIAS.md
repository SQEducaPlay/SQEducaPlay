# Relatório de falhas e melhorias do SQEducaPlay

## Resumo executivo

O projeto já entrega uma base funcional, mas hoje apresenta problemas claros de manutenção, consistência de dados e experiência de uso. O principal risco não é apenas visual: há pontos em que a aplicação pode iniciar com falhas silenciosas, exibir informações do usuário errado e depender de valores estáticos que não acompanham o estado real do sistema.

Em termos práticos, isso significa que parte das telas parece pronta, mas ainda existe acoplamento alto, tratamento de erro insuficiente e baixa confiabilidade em cenários fora do caminho feliz.

## Falhas identificadas

### 1. Inicialização com falhas silenciosas

No ponto de entrada, o app inicializa o áudio de fundo e carrega o progresso persistido dentro de blocos `try/catch` que ignoram o erro. Isso evita travar a abertura, mas também esconde falhas reais e dificulta diagnóstico.

Referências:

- [lib/main.dart](lib/main.dart#L12)
- [lib/main.dart](lib/main.dart#L13)
- [lib/main.dart](lib/main.dart#L15)
- [lib/main.dart](lib/main.dart#L17)

Impacto:

- Se o banco falhar, o usuário pode abrir o app sem perceber que o estado foi parcialmente carregado.
- Se o áudio falhar, o problema fica invisível para quem mantém o projeto.
- A depuração em produção fica mais cara porque os sintomas são mascarados.

### 2. Perfil do usuário fixo na tela inicial

O atalho de perfil na home abre sempre o perfil do usuário `admin`, independentemente de quem esteja logado. Esse é um bug funcional direto, porque a navegação não respeita a sessão real.

Referência:

- [lib/home_page.dart](lib/home_page.dart#L81)

Impacto:

- O aluno ou professor pode ver dados errados.
- A navegação quebra a identidade da sessão.
- Essa falha reduz a confiança na área de perfil e nas estatísticas exibidas.

### 3. Banco com fallback parcial e inconsistência entre plataformas

A camada `AppDatabase` tenta resolver o caso sem `sqflite` com um fallback em memória, mas o comportamento é parcial: vários métodos apenas retornam vazio ou não persistem nada quando o banco não está disponível. Além disso, o construtor marca o banco como indisponível só em Web, enquanto falhas de inicialização também levam a um `throw`, o que pode interromper fluxos que poderiam ser degradados com mais controle.

Referências:

- [lib/database/app_database.dart](lib/database/app_database.dart#L18)
- [lib/database/app_database.dart](lib/database/app_database.dart#L84)
- [lib/database/app_database.dart](lib/database/app_database.dart#L258)
- [lib/database/app_database.dart](lib/database/app_database.dart#L270)
- [lib/database/app_database.dart](lib/database/app_database.dart#L611)

Impacto:

- Em cenários sem banco nativo, parte das funcionalidades simplesmente desaparece.
- O fallback não é completo o bastante para sustentar navegação, progresso e ranking de forma confiável.
- O código passa a ter dois comportamentos diferentes para a mesma funcionalidade, o que complica testes e manutenção.

### 4. Tela inicial baseada em dados estáticos

A home exibe nível, XP, progresso e conquistas recentes com valores fixos, sem conectar esses blocos ao estado real do usuário. Isso cria uma interface bonita, mas enganosa: a tela parece personalizada, porém não reage ao progresso real salvo no sistema.

Referências:

- [lib/home_page.dart](lib/home_page.dart#L96)
- [lib/home_page.dart](lib/home_page.dart#L120)

Impacto:

- O usuário vê números que não refletem a realidade.
- O app transmite sensação de progresso mesmo quando não houve atualização real.
- Estatísticas e gamificação perdem credibilidade.

### 5. Uso excessivo de nomes e regras hardcoded

Há regras de negócio embutidas diretamente no código, como a identificação especial do usuário `Keinan` e a normalização de professor por nome. Isso funciona para um cenário específico, mas reduz a escalabilidade do sistema e dificulta expansão para múltiplas escolas, perfis ou administradores.

Referências:

- [lib/login_page.dart](lib/login_page.dart#L95)
- [lib/login_page.dart](lib/login_page.dart#L99)
- [lib/database/app_database.dart](lib/database/app_database.dart#L44)

Impacto:

- O app fica dependente de exceções manuais para um usuário específico.
- A manutenção fica sensível a mudanças de nome, papel ou regra de acesso.
- Regras de autenticação e perfil ficam misturadas com detalhes de implementação.

### 6. Tratamento de erro e logging insuficientes

Parte dos erros é apenas registrada em log ou engolida sem ação compensatória. Isso aparece em inicialização, carregamento de dados e fluxos de login. O resultado é um sistema mais difícil de diagnosticar quando algo quebra fora do ambiente de desenvolvimento.

Referências:

- [lib/main.dart](lib/main.dart#L12)
- [lib/login_page.dart](lib/login_page.dart#L57)
- [lib/login_page.dart](lib/login_page.dart#L129)

Impacto:

- Falhas podem passar despercebidas por muito tempo.
- O suporte técnico fica mais lento.
- O comportamento do app pode divergir entre dispositivos sem explicação clara.

### 7. Dependência de estado global e acoplamento elevado

O projeto concentra várias responsabilidades em serviços globais e classes estáticas, como banco, progresso, áudio e sessão. Esse desenho facilita começar, mas cria acoplamento alto e reduz a testabilidade.

Impacto:

- Fica mais difícil simular cenários em testes automatizados.
- Mudanças em uma camada podem afetar várias telas sem fronteira clara.
- A evolução para arquitetura modular fica mais cara com o tempo.

## Melhorias recomendadas

### Prioridade alta

1. Corrigir o perfil fixo na home para usar o usuário autenticado da sessão atual.
2. Trocar os blocos de erro silencioso por tratamento explícito, com feedback ao usuário e telemetria local mínima.
3. Padronizar um fluxo de sessão único, evitando reconstruções manuais de `User` em várias telas.
4. Transformar a home em uma tela reativa, lendo progresso, XP, estrelas e conquistas do serviço correspondente.
5. Reforçar a camada de banco para que o fallback, se existir, seja previsível e bem delimitado.

### Prioridade média

1. Separar regra de negócio de UI em serviços menores e mais coesos.
2. Remover dependências de nome fixo como forma de identificar papel especial de usuário.
3. Adicionar validações de entrada nos formulários de login, cadastro e edição de perfil.
4. Criar um estado compartilhado para sessão do usuário, reduzindo consultas repetidas ao banco.
5. Melhorar a cobertura de testes para autenticação, ranking e progresso.

### Prioridade baixa

1. Revisar consistência visual para reduzir blocos estáticos que parecem dados reais.
2. Revisar textos e rótulos para torná-los mais consistentes entre perfis de aluno e professor.
3. Documentar melhor o fluxo de inicialização, persistência e regras de gamificação.
4. Avaliar se parte do fallback em memória ainda faz sentido no escopo atual do projeto.

## Riscos de continuidade se nada mudar

- O projeto pode continuar funcionando apenas no caminho feliz, mas quebrar em cenários reais de uso.
- A manutenção tende a ficar mais cara, porque cada nova feature aumenta o acoplamento existente.
- A confiança do usuário pode cair se a tela mostrar dados que não correspondem à conta ativa.
- A expansão para múltiplos perfis, escolas ou ambientes tende a exigir refatorações maiores do que o necessário.

## Recomendação prática de execução

1. Corrigir os bugs funcionais mais visíveis primeiro, especialmente sessão e perfil.
2. Em seguida, tornar as telas dependentes do estado real do usuário, não de valores estáticos.
3. Depois, reestruturar banco, sessão e progresso para uma arquitetura mais testável.
4. Por fim, adicionar testes e validação para impedir regressões nos fluxos principais.

## Observação de validação

Este relatório foi montado a partir da análise do código-fonte do projeto. Para validação completa em Android, o ambiente local também depende de configuração de Java e de um dispositivo ou emulador conectado; sem isso, parte da checagem prática da plataforma fica limitada.