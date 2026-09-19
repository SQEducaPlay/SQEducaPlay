# SQEducaPlay

Aplicativo Flutter educativo para alunos do 2º ao 5º ano, com atividades de
Português e Matemática, ranking, progresso e acompanhamento do professor.

## Acesso ao projeto

O código principal fica em `Projeto SQEducaPlay/`.

```powershell
cd "Projeto SQEducaPlay"
flutter pub get
flutter run
```

Para validar a versão Web localmente:

```powershell
cd "Projeto SQEducaPlay"
flutter build web --release
```

O artefato gerado fica em `Projeto SQEducaPlay/build/web/`. O workflow
`.github/workflows/deploy-web.yml` valida e armazena esse artefato no GitHub.
Para publicar uma URL com GitHub Pages, o repositório precisa ter Pages
habilitado e um plano que ofereça Pages para repositórios privados; caso
contrário, o build continua disponível como artefato da execução.

## Funcionalidades

- escolha entre acesso de aluno e educador;
- cadastro de aluno com escola, turma, série e consentimento;
- aprovação do aluno pelo professor;
- quiz de Português e Matemática com progresso e ranking;
- convites de educador vinculados à escola, expirando e de uso único;
- senhas novas protegidas com bcrypt;
- exportação de dados sem senha e exclusão com confirmação;
- política de privacidade e preferências de anonimização;
- SQLite no mobile e fallback em memória para a Web.

## Segurança e privacidade

O app registra a versão do consentimento, não salva a senha nas preferências e
remove a senha da exportação JSON. A política de privacidade está disponível
dentro do app em **Privacidade (LGPD)**. Esta é uma versão acadêmica/piloto:
não use dados reais de crianças sem aprovação institucional, política de
retenção e backend adequado.

## Testes

```powershell
cd "Projeto SQEducaPlay"
flutter analyze
flutter test
```

## Histórico e comparação

`Projeto SQEducaPlay/COMPARACAO-PROJETOS.md` registra o diff entre a versão
antiga `c585150` e a versão atual do meu projeto. O repositório
`SQEducaPlay/SQEducaPlay` é separado e não é alterado por este projeto.

## Documentação da ação extensionista

Os documentos da ação estão no [índice da documentação](INDICE_DOCUMENTACAO.md).
O plano, o roteiro da oficina e o modelo de termo do responsável registram o
status real de preparação: E.M. Manoel Muniz como escola parceira, Direção da
escola como contato institucional e data e local ainda a confirmar. Não há
presenças ou resultados registrados.
