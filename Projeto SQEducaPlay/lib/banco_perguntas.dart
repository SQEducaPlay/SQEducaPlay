// Banco de perguntas organizadas por matéria, ano, tópico

class BancoPerguntas {
  static String _canonicalGrade(String ano) {
    final value = ano.trim();
    if (value.endsWith('Fundamental')) return value;
    return '$value Fundamental';
  }

  static Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>> perguntas = {
    'Matemática': {
      '2º Ano Fundamental': {
        'Números até 1000': [
          {
            'pergunta': 'Qual número vem depois de 29?',
            'opcoes': ['28', '30', '31', '32'],
            'resposta': '30',
          },
          {
            'pergunta': 'Quantos meses tem um ano?',
            'opcoes': ['10', '11', '12', '13'],
            'resposta': '12',
          },
          {
            'pergunta': 'Qual número está entre 15 e 17?',
            'opcoes': ['14', '15', '16', '17'],
            'resposta': '16',
          },
          {
            'pergunta': 'Quantos dias tem uma semana?',
            'opcoes': ['5', '6', '7', '8'],
            'resposta': '7',
          },
          {
            'pergunta': 'Qual é o próximo número par depois de 20?',
            'opcoes': ['21', '22', '23', '24'],
            'resposta': '22',
          },
          {
            'pergunta': 'Qual número é maior: 45 ou 54?',
            'opcoes': ['45', '54', 'São iguais', 'Nenhum'],
            'resposta': '54',
          },
        ],
        'Adição e Subtração': [
          {
            'pergunta': 'Quanto é 15 + 10?',
            'opcoes': ['20', '25', '30', '35'],
            'resposta': '25',
          },
          {
            'pergunta': 'Se você tem 10 balas e ganha mais 5, com quantas balas você fica?',
            'opcoes': ['12', '15', '18', '20'],
            'resposta': '15',
          },
          {
            'pergunta': 'Quanto é 25 + 25?',
            'opcoes': ['40', '45', '50', '55'],
            'resposta': '50',
          },
          {
            'pergunta': 'Quanto é 12 + 18?',
            'opcoes': ['25', '28', '30', '32'],
            'resposta': '30',
          },
          {
            'pergunta': 'Quanto é 30 + 20?',
            'opcoes': ['40', '45', '50', '55'],
            'resposta': '50',
          },
          {
            'pergunta': 'Quanto é 20 - 8?',
            'opcoes': ['10', '12', '14', '16'],
            'resposta': '12',
          },
          {
            'pergunta': 'Quanto é 50 - 20?',
            'opcoes': ['20', '30', '40', '50'],
            'resposta': '30',
          },
          {
            'pergunta': 'Quanto é 30 - 15?',
            'opcoes': ['10', '15', '20', '25'],
            'resposta': '15',
          },
          {
            'pergunta': 'Quanto é 40 - 12?',
            'opcoes': ['26', '28', '30', '32'],
            'resposta': '28',
          },
          {
            'pergunta': 'Tenho 35 reais e gasto 10, quanto sobra?',
            'opcoes': ['20', '22', '25', '28'],
            'resposta': '25',
          },
        ],
        'Multiplicação (Dobro e Triplo)': [
          {
            'pergunta': 'Qual é o dobro de 6?',
            'opcoes': ['10', '12', '14', '16'],
            'resposta': '12',
          },
          {
            'pergunta': 'Quanto é 2 + 2 + 2?',
            'opcoes': ['4', '5', '6', '8'],
            'resposta': '6',
          },
          {
            'pergunta': 'Quanto é 5 x 2?',
            'opcoes': ['8', '10', '12', '15'],
            'resposta': '10',
          },
          {
            'pergunta': 'Qual é o dobro de 10?',
            'opcoes': ['15', '18', '20', '22'],
            'resposta': '20',
          },
          {
            'pergunta': 'Quanto é 3 + 3 + 3?',
            'opcoes': ['6', '7', '8', '9'],
            'resposta': '9',
          },
        ],
        'Medidas e Tempo': [
          {
            'pergunta': 'Quantas horas tem um dia?',
            'opcoes': ['12', '20', '24', '30'],
            'resposta': '24',
          },
          {
            'pergunta': 'Qual é maior: 1 metro ou 50 centímetros?',
            'opcoes': ['1 metro', '50 centímetros', 'São iguais', 'Nenhum'],
            'resposta': '1 metro',
          },
          {
            'pergunta': 'Quantos minutos tem uma hora?',
            'opcoes': ['50', '55', '60', '100'],
            'resposta': '60',
          },
          {
            'pergunta': 'Qual é o mês com menos dias?',
            'opcoes': ['Janeiro', 'Fevereiro', 'Março', 'Abril'],
            'resposta': 'Fevereiro',
          },
        ],
      },
      '3º Ano Fundamental': {
        'Números até 1000': [
          {
            'pergunta': 'Qual número tem 3 centenas, 5 dezenas e 2 unidades?',
            'opcoes': ['325', '352', '523', '532'],
            'resposta': '352',
          },
          {
            'pergunta': 'Qual é o antecessor de 500?',
            'opcoes': ['498', '499', '501', '502'],
            'resposta': '499',
          },
          {
            'pergunta': 'Quantas dezenas tem o número 780?',
            'opcoes': ['7', '70', '78', '80'],
            'resposta': '78',
          },
          {
            'pergunta': 'Qual número é maior: 789 ou 798?',
            'opcoes': ['789', '798', 'São iguais', 'Nenhum'],
            'resposta': '798',
          },
        ],
        'Adição e Subtração': [
          {
            'pergunta': 'Quanto é 150 + 250?',
            'opcoes': ['300', '350', '400', '450'],
            'resposta': '400',
          },
          {
            'pergunta': 'Quanto é 500 - 175?',
            'opcoes': ['315', '325', '335', '345'],
            'resposta': '325',
          },
          {
            'pergunta': 'Quanto é 234 + 166?',
            'opcoes': ['390', '400', '410', '420'],
            'resposta': '400',
          },
          {
            'pergunta': 'Quanto é 1000 - 450?',
            'opcoes': ['540', '550', '560', '570'],
            'resposta': '550',
          },
        ],
        'Multiplicação (Tabuada)': [
          {
            'pergunta': 'Quanto é 7 x 8?',
            'opcoes': ['49', '54', '56', '63'],
            'resposta': '56',
          },
          {
            'pergunta': 'Quanto é 9 x 6?',
            'opcoes': ['48', '52', '54', '56'],
            'resposta': '54',
          },
          {
            'pergunta': 'Quanto é 6 x 7?',
            'opcoes': ['40', '42', '44', '46'],
            'resposta': '42',
          },
          {
            'pergunta': 'Quanto é 8 x 5?',
            'opcoes': ['35', '38', '40', '45'],
            'resposta': '40',
          },
          {
            'pergunta': 'Quanto é 9 x 9?',
            'opcoes': ['72', '77', '81', '90'],
            'resposta': '81',
          },
        ],
        'Divisão': [
          {
            'pergunta': 'Quanto é 45 ÷ 5?',
            'opcoes': ['7', '8', '9', '10'],
            'resposta': '9',
          },
          {
            'pergunta': 'Quanto é 72 ÷ 8?',
            'opcoes': ['7', '8', '9', '10'],
            'resposta': '9',
          },
          {
            'pergunta': 'Quanto é 100 ÷ 10?',
            'opcoes': ['8', '9', '10', '11'],
            'resposta': '10',
          },
          {
            'pergunta': 'Quanto é 56 ÷ 7?',
            'opcoes': ['6', '7', '8', '9'],
            'resposta': '8',
          },
        ],
        'Frações (Introdução)': [
          {
            'pergunta': 'Qual é a fração que representa a metade?',
            'opcoes': ['1/2', '1/3', '1/4', '2/3'],
            'resposta': '1/2',
          },
          {
            'pergunta': 'Qual é a fração que representa um quarto?',
            'opcoes': ['1/2', '1/3', '1/4', '1/5'],
            'resposta': '1/4',
          },
          {
            'pergunta': 'Se uma pizza tem 8 pedaços e você come 2, que fração você comeu?',
            'opcoes': ['1/8', '2/8', '3/8', '4/8'],
            'resposta': '2/8',
          },
          {
            'pergunta': 'Qual fração é maior: 1/2 ou 1/4?',
            'opcoes': ['1/2', '1/4', 'São iguais', 'Nenhuma'],
            'resposta': '1/2',
          },
        ],
      },
      '4º Ano Fundamental': {
        'Números até 10.000': [
          {
            'pergunta': 'Qual é o valor de 5 no número 5.432?',
            'opcoes': ['5', '50', '500', '5000'],
            'resposta': '5000',
          },
          {
            'pergunta': 'Como se lê 7.809?',
            'opcoes': ['Sete mil e oitenta e nove', 'Setecentos e oitenta e nove', 'Sete mil, oitocentos e nove', 'Setenta e oito mil e nove'],
            'resposta': 'Sete mil, oitocentos e nove',
          },
          {
            'pergunta': 'Qual número é maior: 4.567 ou 4.765?',
            'opcoes': ['4.567', '4.765', 'São iguais', 'Nenhum'],
            'resposta': '4.765',
          },
        ],
        'Adição e Subtração': [
          {
            'pergunta': 'Quanto é 567 + 238?',
            'opcoes': ['695', '805', '815', '825'],
            'resposta': '805',
          },
          {
            'pergunta': 'Quanto é 750 - 385?',
            'opcoes': ['355', '360', '365', '370'],
            'resposta': '365',
          },
          {
            'pergunta': 'Quanto é 420 + 180?',
            'opcoes': ['560', '590', '600', '610'],
            'resposta': '600',
          },
          {
            'pergunta': 'Qual é o resultado de 1000 - 425?',
            'opcoes': ['565', '570', '575', '580'],
            'resposta': '575',
          },
        ],
        'Multiplicação': [
          {
            'pergunta': 'Quanto é 12 x 12?',
            'opcoes': ['124', '144', '154', '164'],
            'resposta': '144',
          },
          {
            'pergunta': 'Quanto é 15 x 8?',
            'opcoes': ['110', '120', '130', '140'],
            'resposta': '120',
          },
          {
            'pergunta': 'Quanto é 13 x 7?',
            'opcoes': ['81', '87', '91', '97'],
            'resposta': '91',
          },
          {
            'pergunta': 'Quanto é 25 x 4?',
            'opcoes': ['90', '95', '100', '105'],
            'resposta': '100',
          },
        ],
        'Divisão': [
          {
            'pergunta': 'Quanto é 144 ÷ 12?',
            'opcoes': ['10', '11', '12', '13'],
            'resposta': '12',
          },
          {
            'pergunta': 'Quanto é 150 ÷ 5?',
            'opcoes': ['25', '30', '35', '40'],
            'resposta': '30',
          },
          {
            'pergunta': 'Quanto é 96 ÷ 8?',
            'opcoes': ['10', '11', '12', '13'],
            'resposta': '12',
          },
        ],
        'Frações e Operações': [
          {
            'pergunta': 'Quanto é 1/2 + 1/2?',
            'opcoes': ['1/4', '2/4', '1', '2'],
            'resposta': '1',
          },
          {
            'pergunta': 'Quanto é 3/4 - 1/4?',
            'opcoes': ['1/4', '2/4', '3/4', '4/4'],
            'resposta': '2/4',
          },
          {
            'pergunta': 'Quanto é 2/5 + 2/5?',
            'opcoes': ['2/5', '3/5', '4/5', '5/5'],
            'resposta': '4/5',
          },
        ],
        'Geometria (Perímetro)': [
          {
            'pergunta': 'Qual é o perímetro de um retângulo de lados 6 e 4?',
            'opcoes': ['18', '20', '22', '24'],
            'resposta': '20',
          },
          {
            'pergunta': 'Um quadrado tem quantos ângulos retos?',
            'opcoes': ['2', '3', '4', '5'],
            'resposta': '4',
          },
          {
            'pergunta': 'Todos os lados de um quadrado são iguais?',
            'opcoes': ['Sim', 'Não', 'Apenas dois', 'Depende'],
            'resposta': 'Sim',
          },
          {
            'pergunta': 'Qual é o perímetro de um retângulo de lados 5 e 3?',
            'opcoes': ['14', '15', '16', '18'],
            'resposta': '16',
          },
        ],
      },
      '5º Ano Fundamental': {
        'Números e Sistema Decimal': [
          {
            'pergunta': 'Qual é o valor de 7 no número 47.329?',
            'opcoes': ['7', '70', '700', '7000'],
            'resposta': '7000',
          },
          {
            'pergunta': 'Como se escreve por extenso 52.408?',
            'opcoes': ['Cinquenta e dois mil e quarenta e oito', 'Cinquenta e dois mil, quatrocentos e oito', 'Cinco mil, duzentos e quarenta e oito', 'Quinhentos e vinte e quatro mil e oito'],
            'resposta': 'Cinquenta e dois mil, quatrocentos e oito',
          },
          {
            'pergunta': 'Qual é o sucessor de 99.999?',
            'opcoes': ['99.998', '100.000', '100.001', '110.000'],
            'resposta': '100.000',
          },
        ],
        'Operações com Decimais': [
          {
            'pergunta': 'Quanto é 3.5 + 2.8?',
            'opcoes': ['5.9', '6.1', '6.3', '6.5'],
            'resposta': '6.3',
          },
          {
            'pergunta': 'Quanto é 12.0 - 4.75?',
            'opcoes': ['6.95', '7.15', '7.25', '7.35'],
            'resposta': '7.25',
          },
          {
            'pergunta': 'Qual é o valor de 4,2 + 3,75?',
            'opcoes': ['7,85', '7,90', '7,95', '8,00'],
            'resposta': '7,95',
          },
          {
            'pergunta': 'Quanto é 9,5 - 2,3?',
            'opcoes': ['6,9', '7,0', '7,1', '7,2'],
            'resposta': '7,2',
          },
          {
            'pergunta': 'Qual é o resultado de 2,5 × 4?',
            'opcoes': ['8,5', '9,5', '10,0', '10,5'],
            'resposta': '10,0',
          },
        ],
        'Adição e Subtração': [
          {
            'pergunta': 'Quanto é 2350 + 1675?',
            'opcoes': ['3925', '4025', '4125', '4225'],
            'resposta': '4025',
          },
          {
            'pergunta': 'Calcule: 5000 - 2879',
            'opcoes': ['2111', '2121', '2131', '2141'],
            'resposta': '2121',
          },
          {
            'pergunta': 'Quanto é 8.457 + 3.896?',
            'opcoes': ['12.343', '12.353', '12.363', '12.373'],
            'resposta': '12.353',
          },
        ],
        'Multiplicação e Divisão': [
          {
            'pergunta': 'Quanto é 25 x 4?',
            'opcoes': ['90', '95', '100', '105'],
            'resposta': '100',
          },
          {
            'pergunta': 'Quanto é 250 ÷ 5?',
            'opcoes': ['45', '50', '55', '60'],
            'resposta': '50',
          },
          {
            'pergunta': 'Quanto é 18 x 5?',
            'opcoes': ['80', '85', '90', '95'],
            'resposta': '90',
          },
          {
            'pergunta': 'Quanto é 360 ÷ 12?',
            'opcoes': ['28', '29', '30', '31'],
            'resposta': '30',
          },
        ],
        'Frações': [
          {
            'pergunta': 'Quanto é 1/2 + 1/4?',
            'opcoes': ['1/6', '2/6', '3/4', '1/3'],
            'resposta': '3/4',
          },
          {
            'pergunta': 'Quanto é 2/3 + 1/3?',
            'opcoes': ['1/3', '2/3', '3/3', '4/3'],
            'resposta': '3/3',
          },
          {
            'pergunta': 'Quanto é 3/5 - 1/5?',
            'opcoes': ['1/5', '2/5', '3/5', '4/5'],
            'resposta': '2/5',
          },
          {
            'pergunta': 'Qual fração é equivalente a 2/4?',
            'opcoes': ['1/2', '1/3', '3/4', '2/3'],
            'resposta': '1/2',
          },
        ],
        'Geometria (Área e Perímetro)': [
          {
            'pergunta': 'Qual é a área de um retângulo de lados 8 e 5?',
            'opcoes': ['13', '30', '35', '40'],
            'resposta': '40',
          },
          {
            'pergunta': 'Qual é o perímetro de um triângulo com lados 5, 6 e 7?',
            'opcoes': ['16', '17', '18', '19'],
            'resposta': '18',
          },
          {
            'pergunta': 'Um retângulo com lados 10 e 3 tem área igual a:',
            'opcoes': ['13', '20', '30', '40'],
            'resposta': '30',
          },
          {
            'pergunta': 'Qual é a área de um quadrado de lado 6?',
            'opcoes': ['24', '30', '36', '42'],
            'resposta': '36',
          },
        ],
      },
    },
    'Português': {
      '2º Ano Fundamental': {
  'Leitura/escuta e interpretação': [
          {
            'pergunta': 'Em um poema, palavras que têm sons parecidos no final chamam-se:',
            'opcoes': ['Rimas', 'Versos', 'Estrofes', 'Títulos'],
            'resposta': 'Rimas',
          },
          {
            'pergunta': 'Qual palavra rima com "GATO"?',
            'opcoes': ['RATO', 'BOLA', 'CASA', 'PATO'],
            'resposta': 'RATO',
          },
          {
            'pergunta': 'Se Maria comeu uma maçã no lanche, o que ela fez?',
            'opcoes': ['Jogou fora', 'Comeu', 'Comprou', 'Guardou'],
            'resposta': 'Comeu',
          },
          {
            'pergunta': 'Na frase "O sol brilha no céu", o que brilha?',
            'opcoes': ['A lua', 'O sol', 'A estrela', 'O céu'],
            'resposta': 'O sol',
          },
          {
            'pergunta': 'Um bilhete serve para:',
            'opcoes': ['Deixar recado', 'Cozinhar', 'Brincar', 'Dormir'],
            'resposta': 'Deixar recado',
          },
          {
            'pergunta': 'Em qual tipo de texto encontramos uma lição moral no final?',
            'opcoes': ['Bilhete', 'Fábula', 'Carta', 'Lista'],
            'resposta': 'Fábula',
          },
        ],
  'Análise linguística/semiótica (ortografia e pontuação)': [
          {
            'pergunta': 'Qual palavra usa o dígrafo CH?',
            'opcoes': ['Carro', 'Chocolate', 'Sapato', 'Mesa'],
            'resposta': 'Chocolate',
          },
          {
            'pergunta': 'Qual palavra usa o dígrafo NH?',
            'opcoes': ['Ninho', 'Nome', 'Nota', 'Nada'],
            'resposta': 'Ninho',
          },
          {
            'pergunta': 'Qual palavra usa o dígrafo LH?',
            'opcoes': ['Palha', 'Pala', 'Pato', 'Pala'],
            'resposta': 'Palha',
          },
          {
            'pergunta': 'Usamos M antes de qual letra?',
            'opcoes': ['A', 'P', 'S', 'T'],
            'resposta': 'P',
          },
          {
            'pergunta': 'Qual sinal usamos no final de uma pergunta?',
            'opcoes': ['.', ',', '?', '!'],
            'resposta': '?',
          },
          {
            'pergunta': 'Qual palavra está escrita corretamente?',
            'opcoes': ['Bonpa', 'Bomba', 'Bonba', 'Bopa'],
            'resposta': 'Bomba',
          },
          {
            'pergunta': 'Qual é o plural de "mão"?',
            'opcoes': ['Mãos', 'Maos', 'Mães', 'Mães'],
            'resposta': 'Mãos',
          },
        ],
  'Análise linguística/semiótica (vocabulário)': [
          {
            'pergunta': 'O que é o contrário de "alto"?',
            'opcoes': ['Baixo', 'Grande', 'Pequeno', 'Gordo'],
            'resposta': 'Baixo',
          },
          {
            'pergunta': 'O que é o contrário de "aberto"?',
            'opcoes': ['Fechado', 'Largo', 'Estreito', 'Grande'],
            'resposta': 'Fechado',
          },
          {
            'pergunta': 'Qual palavra é sinônimo de "feliz"?',
            'opcoes': ['Triste', 'Alegre', 'Bravo', 'Cansado'],
            'resposta': 'Alegre',
          },
          {
            'pergunta': 'Qual palavra é antônimo de "limpo"?',
            'opcoes': ['Sujo', 'Claro', 'Bonito', 'Novo'],
            'resposta': 'Sujo',
          },
          {
            'pergunta': 'O que usamos para escrever no papel?',
            'opcoes': ['Lápis', 'Prato', 'Sapato', 'Livro'],
            'resposta': 'Lápis',
          },
        ],
      },
      '3º Ano Fundamental': {
        'Leitura/escuta e interpretação': [
          {
            'pergunta': 'Na frase "O gato dorme no tapete", quem realiza a ação?',
            'opcoes': ['O gato', 'O tapete', 'Dormir', 'A ação'],
            'resposta': 'O gato',
          },
          {
            'pergunta': 'Se "Ana levou um guarda-chuva", o tempo provavelmente estava:',
            'opcoes': ['Ensolarado', 'Chuvoso', 'Nevando', 'Seco'],
            'resposta': 'Chuvoso',
          },
          {
            'pergunta': 'Qual é a ideia principal de "Pedro comeu uma maçã no lanche"?',
            'opcoes': ['Pedro comprou uma maçã', 'Pedro comeu uma maçã', 'Pedro guardou a maçã', 'Pedro jogou a maçã'],
            'resposta': 'Pedro comeu uma maçã',
          },
          {
            'pergunta': 'Em uma notícia, o título serve para:',
            'opcoes': ['Resumir o assunto', 'Decorar', 'Confundir', 'Numerar'],
            'resposta': 'Resumir o assunto',
          },
          {
            'pergunta': 'Qual a função de um texto instrucional?',
            'opcoes': ['Ensinar fazer algo', 'Contar história', 'Vender produto', 'Fazer piada'],
            'resposta': 'Ensinar fazer algo',
          },
        ],
  'Análise linguística/semiótica (ortografia)': [
          {
            'pergunta': 'Qual palavra está escrita corretamente?',
            'opcoes': ['Exenplo', 'Exemplo', 'Ezemplo', 'Exsemplo'],
            'resposta': 'Exemplo',
          },
          {
            'pergunta': 'Qual palavra usa "SS"?',
            'opcoes': ['Pasaro', 'Pássaro', 'Passsaro', 'Pazaro'],
            'resposta': 'Pássaro',
          },
          {
            'pergunta': 'Qual palavra usa "RR"?',
            'opcoes': ['Caro', 'Carro', 'Carocha', 'Carão'],
            'resposta': 'Carro',
          },
          {
            'pergunta': 'Qual palavra está escrita corretamente?',
            'opcoes': ['Asul', 'Azul', 'Azzul', 'Aszul'],
            'resposta': 'Azul',
          },
          {
            'pergunta': 'Complete: "O gato subiu na _____ alta."',
            'opcoes': ['árvore', 'arvore', 'arvre', 'árvori'],
            'resposta': 'árvore',
          },
          {
            'pergunta': 'Qual palavra tem Ç (cedilha)?',
            'opcoes': ['Cabeça', 'Cabesa', 'Cabessa', 'Kabeca'],
            'resposta': 'Cabeça',
          },
        ],
  'Produção de textos': [
          {
            'pergunta': 'Para começar um texto narrativo, usamos:',
            'opcoes': ['Era uma vez', 'Em conclusão', 'Por isso', 'Finalmente'],
            'resposta': 'Era uma vez',
          },
          {
            'pergunta': 'Um parágrafo começa com:',
            'opcoes': ['Vírgula', 'Ponto final', 'Espaço maior', 'Letra minúscula'],
            'resposta': 'Espaço maior',
          },
          {
            'pergunta': 'Qual sinal usamos para separar itens de uma lista?',
            'opcoes': ['!', '?', ',', '.'],
            'resposta': ',',
          },
          {
            'pergunta': 'Em um convite, devemos incluir:',
            'opcoes': ['Data e local', 'Receita', 'Piada', 'Desenho'],
            'resposta': 'Data e local',
          },
        ],
      },
      '4º Ano Fundamental': {
        'Leitura/escuta e interpretação': [
          {
            'pergunta': 'Em "O time venceu porque treinou muito", qual é a causa da vitória?',
            'opcoes': ['O time venceu', 'Treinou muito', 'O time perdeu', 'Não treinou'],
            'resposta': 'Treinou muito',
          },
          {
            'pergunta': 'Na frase "Embora estivesse cansado, João estudou", a conjunção indica:',
            'opcoes': ['Causa', 'Concessão', 'Conclusão', 'Comparação'],
            'resposta': 'Concessão',
          },
          {
            'pergunta': 'O que conclui a frase: "Carla levou casaco e guarda-chuva, então..."',
            'opcoes': ['Está calor', 'Vai chover', 'Vai nevar', 'Está seco'],
            'resposta': 'Vai chover',
          },
          {
            'pergunta': 'O que significa a palavra "veloz"?',
            'opcoes': ['Rápido', 'Lento', 'Parado', 'Quieto'],
            'resposta': 'Rápido',
          },
          {
            'pergunta': 'Qual é o sinônimo de "alegre"?',
            'opcoes': ['Triste', 'Feliz', 'Bravo', 'Calmo'],
            'resposta': 'Feliz',
          },
          {
            'pergunta': 'O que é uma "moral da história"?',
            'opcoes': ['O início', 'A lição aprendida', 'O personagem', 'O local'],
            'resposta': 'A lição aprendida',
          },
        ],
  'Análise linguística/semiótica (ortografia)': [
          {
            'pergunta': 'Qual palavra usa "Ç"?',
            'opcoes': ['Camiseta', 'Coração', 'Cavalo', 'Carro'],
            'resposta': 'Coração',
          },
          {
            'pergunta': 'Qual palavra está escrita corretamente?',
            'opcoes': ['Excessão', 'Exceção', 'Excessáo', 'Exsessão'],
            'resposta': 'Exceção',
          },
          {
            'pergunta': 'Qual palavra usa "CH"?',
            'opcoes': ['Sapato', 'Chocolate', 'Sorvete', 'Suco'],
            'resposta': 'Chocolate',
          },
          {
            'pergunta': 'Qual palavra está correta com G?',
            'opcoes': ['Girafa', 'Jirafa', 'Guirafa', 'Gerafa'],
            'resposta': 'Girafa',
          },
          {
            'pergunta': 'Quando usar "MAL" (com L)?',
            'opcoes': ['Oposto de bem', 'Oposto de bom', 'Animal', 'Fruta'],
            'resposta': 'Oposto de bem',
          },
          {
            'pergunta': 'Complete: "Vou _____ praia" (à/a)',
            'opcoes': ['à', 'a', 'há', 'ah'],
            'resposta': 'à',
          },
        ],
  'Produção de textos': [
          {
            'pergunta': 'Em um texto argumentativo, devemos:',
            'opcoes': ['Defender uma ideia', 'Contar piada', 'Fazer lista', 'Desenhar'],
            'resposta': 'Defender uma ideia',
          },
          {
            'pergunta': 'Qual conectivo indica oposição?',
            'opcoes': ['E', 'Mas', 'Porque', 'Quando'],
            'resposta': 'Mas',
          },
          {
            'pergunta': 'Para dar sequência às ideias, usamos:',
            'opcoes': ['Palavras soltas', 'Conectivos', 'Números', 'Desenhos'],
            'resposta': 'Conectivos',
          },
          {
            'pergunta': 'O que é um texto instrucional?',
            'opcoes': ['Ensina fazer algo', 'Conta história', 'Dá notícia', 'Faz propaganda'],
            'resposta': 'Ensina fazer algo',
          },
        ],
      },
      '5º Ano Fundamental': {
        'Leitura/escuta e interpretação': [
          {
            'pergunta': 'No trecho "A leitura amplia o conhecimento", qual é o efeito apresentado?',
            'opcoes': ['Causa', 'Amplia conhecimento', 'Tempo', 'Lugar'],
            'resposta': 'Amplia conhecimento',
          },
          {
            'pergunta': 'O que melhor resume: "Após estudar, Lucas resolveu o problema com facilidade"?',
            'opcoes': ['Lucas não estudou', 'Estudar ajudou Lucas', 'O problema era impossível', 'Lucas adivinhou'],
            'resposta': 'Estudar ajudou Lucas',
          },
          {
            'pergunta': 'Em "Se houvesse silêncio, a concentração aumentaria", qual relação há entre as orações?',
            'opcoes': ['Causa e efeito', 'Comparação', 'Exemplificação', 'Conclusão'],
            'resposta': 'Causa e efeito',
          },
          {
            'pergunta': 'Em "A lua é um queijo", temos uma:',
            'opcoes': ['Verdade', 'Metáfora', 'Pergunta', 'Ordem'],
            'resposta': 'Metáfora',
          },
          {
            'pergunta': 'O que é discurso direto?',
            'opcoes': ['Narrador conta', 'Personagem fala', 'Descrição', 'Conclusão'],
            'resposta': 'Personagem fala',
          },
        ],
  'Produção de textos': [
          {
            'pergunta': 'Em uma carta formal, devemos usar:',
            'opcoes': ['Gírias', 'Linguagem culta', 'Desenhos', 'Abreviações'],
            'resposta': 'Linguagem culta',
          },
          {
            'pergunta': 'O que caracteriza um texto expositivo?',
            'opcoes': ['Apresenta informações', 'Conta história', 'Diverte', 'Vende produto'],
            'resposta': 'Apresenta informações',
          },
          {
            'pergunta': 'Em um debate, é importante:',
            'opcoes': ['Gritar', 'Argumentar com respeito', 'Interromper', 'Brigar'],
            'resposta': 'Argumentar com respeito',
          },
          {
            'pergunta': 'O que é coesão textual?',
            'opcoes': ['Ligar as ideias', 'Decorar texto', 'Copiar', 'Apagar'],
            'resposta': 'Ligar as ideias',
          },
        ],
      },
    },
  };

  // Método auxiliar para buscar perguntas
  static List<Map<String, dynamic>> buscarPerguntas(
    String materia,
    String ano,
    String? topico,
  ) {
    final anoNormalizado = _canonicalGrade(ano);

    // Se não tiver o tópico especificado, retorna todas as perguntas da matéria/ano
    if (topico == null || topico.isEmpty) {
      var todasPerguntas = <Map<String, dynamic>>[];
      var materiaData = perguntas[materia];
      if (materiaData != null) {
        var anoData = materiaData[anoNormalizado];
        if (anoData != null) {
          anoData.forEach((_, perguntasTopico) {
            todasPerguntas.addAll(perguntasTopico);
          });
        }
      }
      return todasPerguntas;
    }

    // Retorna perguntas do tópico específico
    try {
      return perguntas[materia]?[anoNormalizado]?[topico] ?? [];
    } catch (e) {
      return [];
    }
  }
}
