# Contribuindo com o SQEducaPlay

Guia rápido para colegas do grupo contribuírem com o projeto de forma organizada.

## 🌿 Branches

- `main` — código estável, sempre funcional.
- `feature/nome-da-feature` — novas funcionalidades.
- `fix/nome-do-bug` — correções de bugs.
- `docs/nome-do-documento` — mudanças apenas de documentação.

Nunca commit direto na `main`; sempre abra um Pull Request.

## 📝 Padrão de commits

Use mensagens curtas e descritivas, prefixadas pelo tipo de mudança:

```
feat: adiciona tela de ranking por turma
fix: corrige cálculo de pontos no quiz de matemática
docs: atualiza guia de desenvolvimento
refactor: extrai lógica de pontuação para ProgressoService
test: adiciona teste para daily_mission_service
```

## ✅ Antes de abrir um Pull Request

1. Rode `flutter analyze` e corrija os problemas apontados.
2. Rode `flutter test` e garanta que os testes existentes continuam passando.
3. Atualize a documentação relevante em [docs/README.md](https://github.com/SQEducaPlay/SQEducaPlay/blob/main/README.md) se a mudança afetar arquitetura, banco de dados ou requisitos.
4. Descreva no PR o que foi alterado e por quê.

## 🔍 Revisão de código

- Pelo menos 1 colega deve revisar antes do merge.
- Prefira `Squash and merge` para manter o histórico da `main` limpo.

## 🐛 Reportando bugs ou sugerindo melhorias

Use os templates de Issue disponíveis no repositório (`Bug report` ou `Feature request`).

## 📖 Documentação do projeto

Antes de codar, consulte [INDICE_DOCUMENTACAO.md](https://github.com/SQEducaPlay/SQEducaPlay/blob/main/DOCUMENTACAO_TECNICA.md) para entender requisitos, arquitetura e convenções já definidas.
