# Plano de Experiência Infantil do Aluno

## 1. Objetivo

Tornar a área do aluno mais acolhedora, lúdica e fácil de entender para crianças do 2º ao 5º ano, sem transformar o app em uma tela excessivamente carregada.

A direção visual sugerida pelas referências é uma experiência de aventura: cada matéria representa uma atividade, cada quiz oferece feedback imediato e o progresso fica visível por meio de níveis, estrelas, missões e conquistas.

Este documento é um plano de implementação futura. Ele não altera o comportamento atual do aplicativo.

## 2. Princípios de design

- **Clareza infantil:** uma ação principal por tela e textos curtos.
- **Aprender antes de competir:** ranking como recurso opcional, nunca como foco único.
- **Feedback imediato:** toda resposta deve informar acerto, tentativa ou próximo passo.
- **Recompensa compreensível:** pontos, estrelas, níveis e conquistas devem ter papéis diferentes.
- **Identidade própria:** usar ilustrações e personagens do SQEducaPlay ou assets licenciados; não copiar telas, mascotes ou imagens de outros aplicativos.
- **Acessibilidade:** bom contraste, botões grandes, leitura por voz opcional e suporte a telas pequenas.
- **Privacidade infantil:** evitar exposição desnecessária de nome completo, foto e escola em áreas públicas.

## 3. O que já existe

O projeto já possui uma base que pode ser aproveitada:

- Tela de escolha de matéria.
- Matérias de Português e Matemática.
- Fluxo de tópicos e quizzes.
- Mascote e identidade visual própria.
- Pontos, estrelas, níveis e conquistas.
- Perfil do aluno.
- Ranking com filtros.
- Confete e sons de celebração.
- Cadastro de escola, série e turma.

A evolução deve aproveitar esses elementos antes de criar novos sistemas complexos.

## 4. Proposta para a tela principal do aluno

### 4.1 Cabeçalho

Manter uma saudação curta e neutra:

```text
Oi, Junior! 👋
Qual aventura vamos começar?
```

Exibir no máximo quatro ações no cabeçalho:

- Meu perfil
- Ranking
- Privacidade
- Sair

A tela principal não deve exibir uma seta de voltar. A seta deve ficar reservada para telas internas, como Ranking, Tópicos e Perfil.

### 4.2 Cartões de matéria

Transformar cada matéria em um cartão com identidade própria:

**Português**

- Cor sugerida: laranja ou coral.
- Ícones: livro, lápis, letras ou balão de fala.
- Texto curto: `Mundo das palavras`.

**Matemática**

- Cor sugerida: verde ou azul-turquesa.
- Ícones: números, formas geométricas ou calculadora lúdica.
- Texto curto: `Desafio dos números`.

O nome oficial da matéria deve continuar visível para não causar dúvida. O texto lúdico funciona como complemento, não como substituto.

### 4.3 Área de missão do dia

Adicionar uma área opcional abaixo das matérias:

```text
Missão de hoje
Complete 1 quiz de Português
[Começar missão]
```

Primeira versão recomendada:

- Uma missão por dia.
- Recompensa pequena e previsível.
- Sem punição por não concluir.
- Missão gerada localmente, sem depender de notificações.

## 5. Tela de tópicos

A tela de tópicos pode usar um mapa vertical simples, inspirado em trilhas de aprendizagem, mas com identidade própria.

Cada tópico teria um estado:

- **Disponível:** pode iniciar.
- **Em andamento:** possui progresso parcial.
- **Concluído:** mostra estrela ou selo.
- **Bloqueado:** explica de forma curta o requisito, sem impedir toda a exploração.

Exemplo de organização:

```text
1. Vogais e palavras       Concluído
2. Sílabas                  Disponível
3. Frases curtas            Em breve
```

Para Matemática:

```text
1. Adição até 10            Concluído
2. Adição até 20            Disponível
3. Problemas ilustrados     Em breve
```

A progressão deve respeitar a série do aluno, do 2º ao 5º ano.

## 6. Tela do quiz

### 6.1 Estrutura recomendada

- Título curto, apenas a matéria.
- Indicador `Pergunta 1 de 6`.
- Barra de progresso clara.
- Uma pergunta por vez.
- Área visual grande para ilustrações quando ajudarem a compreensão.
- Botões de resposta grandes e fáceis de tocar.
- Botão de áudio opcional, sem ocupar espaço excessivo.
- Nenhum botão de sair misturado aos controles do quiz.

### 6.2 Feedback de resposta

Após cada resposta:

- Mostrar acerto com cor e som suaves.
- Mostrar erro sem linguagem punitiva.
- Exibir uma explicação curta quando possível.
- Permitir continuar rapidamente.

Exemplos:

```text
Muito bem! Você descobriu a resposta.
```

```text
Quase! Vamos observar esta pista e tentar novamente.
```

### 6.3 Resultado do quiz

O resultado deve destacar três informações:

- Pontos conquistados.
- Estrelas recebidas.
- Próxima conquista ou progresso do nível.

Evitar mostrar muitos números simultaneamente para crianças menores.

## 7. Gamificação com papéis bem definidos

### Pontuação

Representa o total acumulado para definir o nível e o ranking.

### Estrelas

Representam reconhecimento rápido por atividade, desempenho ou sequência.

### Nível

É uma faixa baseada na pontuação total:

- Novato
- Iniciante
- Aprendiz
- Intermediário
- Estudioso
- Expert
- Mestre

### Conquistas

São objetivos específicos, como concluir o primeiro quiz, estudar duas matérias ou manter uma sequência.

### Missões

São objetivos temporários e opcionais, como completar um quiz no dia.

Esses elementos não devem ser apresentados como se fossem a mesma coisa.

## 8. Perfil do aluno

O perfil deve exibir:

- Saudação curta.
- Avatar ou inicial.
- Nível atual.
- Barra de progresso até o próximo nível.
- Pontuação total.
- Estrelas.
- Quizzes concluídos.
- Conquistas recentes.
- Progresso por matéria.

A seção de progresso deve usar a faixa do nível atual. Exemplo:

```text
Nível Novato
120 / 150 pontos
80% até Iniciante
```

Não exibir nome completo, escola ou foto em áreas públicas sem necessidade.

## 9. Ranking infantil e seguro

O ranking deve ser opcional e contextualizado por escola, turma ou série quando possível.

Recomendações:

- Mostrar apenas alunos com atividade ou pontuação.
- Usar apelido ou nome anonimizado por padrão.
- Evitar exibir foto de crianças no ranking público.
- Destacar o progresso pessoal, não somente o primeiro colocado.
- Criar mensagens como `Você subiu 2 posições` ou `Você está melhorando`.
- Não usar linguagem de fracasso para posições baixas.

## 10. Sistema visual

### Cores

Usar uma paleta alegre, mas limitada:

- Azul claro para navegação e confiança.
- Laranja/coral para Português e recompensas.
- Verde/turquesa para Matemática e ações positivas.
- Amarelo para estrelas e destaque.
- Fundo claro com padrões sutis ou formas grandes, sem poluir a leitura.

### Componentes

- Cartões com raio aproximado de 16 a 20 px.
- Botões com área de toque grande.
- Ícones acompanhados de texto quando a ação não for óbvia.
- Ilustrações do mascote em momentos de orientação e celebração.
- Sombras suaves e hierarquia visual clara.

### Tipografia

- Títulos infantis, arredondados e legíveis.
- Textos de instrução maiores que os textos administrativos.
- Evitar fontes decorativas em perguntas e respostas.
- Não usar fonte pequena para informações essenciais.

## 11. Animação e áudio

Implementar com moderação:

- Entrada suave dos cartões de matéria.
- Pequeno movimento ao selecionar uma matéria.
- Confete ao desbloquear conquista.
- Reação do mascote após concluir um quiz.
- Sons curtos e opcionais.
- Controle de volume e opção de silêncio acessíveis aos responsáveis.

Evitar animações contínuas que distraiam ou dificultem a leitura.

## 12. Assets e direitos de uso

As imagens de referência servem apenas como inspiração de composição e linguagem visual.

Para o app:

- Criar ilustrações próprias para Português e Matemática.
- Reutilizar o mascote do SQEducaPlay com variações autorizadas.
- Registrar a origem e a licença de cada asset externo.
- Não copiar personagens, logos, telas ou ilustrações de aplicativos existentes.
- Preferir SVG ou PNG próprios, otimizados para Android.

## 13. Roadmap recomendado

### Fase 1 — Alto impacto e baixo risco

1. Melhorar os cartões de matéria.
2. Reduzir e reorganizar os ícones do cabeçalho.
3. Adicionar subtítulo infantil na tela principal.
4. Padronizar textos de feedback do quiz.
5. Corrigir a exibição de nível e progresso.

### Fase 2 — Engajamento

1. Criar missão diária simples.
2. Adicionar badges de progresso nos tópicos.
3. Criar resultado de quiz mais celebratório.
4. Adicionar reações do mascote.
5. Criar sequência de dias estudados.

### Fase 3 — Conteúdo e personalização

1. Criar trilhas por série, do 2º ao 5º ano.
2. Adicionar atividades ilustradas de sílabas e leitura.
3. Adicionar problemas matemáticos com imagens.
4. Permitir escolher avatar entre opções próprias.
5. Criar temas sazonais sem alterar a navegação principal.

### Fase 4 — Segurança e operação

1. Finalizar política de privacidade pública.
2. Revisar consentimento do responsável.
3. Adicionar exclusão e correção de dados.
4. Testar acessibilidade e contraste.
5. Testar o fluxo completo em dispositivos reais antes da Play Store.

## 14. Critérios de aceite para futuras implementações

Uma melhoria da área do aluno só deve ser considerada pronta quando:

- Funcionar em telas pequenas e grandes.
- Não esconder a ação principal.
- Não criar overflow de texto.
- Não expor dados pessoais desnecessários.
- Funcionar sem conexão, quando a funcionalidade for local.
- Passar em `flutter analyze`.
- Ser testada em pelo menos um dispositivo Android real.
- Ter textos compreensíveis para crianças do 2º ao 5º ano.
- Manter a navegação por voltar e sair consistente.
- Não depender de assets sem licença definida.

## 15. Primeira implementação recomendada

A primeira implementação futura recomendada é a renovação dos cartões de matéria na tela principal:

1. Manter `Português` e `Matemática` como nomes oficiais.
2. Adicionar subtítulos curtos e lúdicos.
3. Usar ilustrações próprias ou o mascote em poses diferentes.
4. Adicionar animação curta ao toque.
5. Testar com crianças ou responsáveis antes de expandir para missões e trilhas.

Essa ordem reduz o risco, melhora imediatamente a percepção infantil e cria uma base visual para as próximas telas.
