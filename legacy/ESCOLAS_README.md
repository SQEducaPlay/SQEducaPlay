# Sistema de Cadastro de Escolas - SQEducaPlay

## 📚 Visão Geral

O sistema agora possui funcionalidade completa de cadastro e vinculação de escolas aos alunos.

## 🏫 Funcionalidades Implementadas

### 1. **Modelo de Escola** (`school_model.dart`)
Representa uma escola com os seguintes atributos:
- `id`: Identificador único da escola
- `name`: Nome da escola
- `address`: Endereço (opcional)
- `city`: Cidade (opcional)

### 2. **Serviço de Escolas** (`school_service.dart`)
Gerencia as escolas cadastradas no sistema:
- **Escolas Pré-cadastradas**: 5 escolas exemplo já vêm configuradas:
  1. Escola Estadual Dom Pedro II (São Paulo)
  2. Colégio Municipal Santos Dumont (Rio de Janeiro)
  3. Escola Municipal Machado de Assis (Belo Horizonte)
  4. Colégio Estadual Tiradentes (Brasília)
  5. Escola Monteiro Lobato (Salvador)

### 3. **Cadastro de Alunos Atualizado** (`register_page.dart`)
A página de registro agora inclui:
- ✅ Nome de usuário
- ✅ Senha
- ✅ Série Fundamental (2º ao 5º ano)
- ✅ **Escola** (obrigatório) - Dropdown com todas as escolas disponíveis

### 4. **Modelo de Usuário Atualizado** (`user_model.dart`)
O modelo de usuário agora inclui:
- `schoolId`: ID da escola onde o aluno estuda

### 5. **Página de Gerenciamento de Escolas** (`manage_schools_page.dart`)
Interface completa para administradores:
- ➕ Adicionar novas escolas
- 📋 Visualizar todas as escolas cadastradas
- 🗑️ Remover escolas existentes

## 🚀 Como Usar

### Para Alunos (Registro)
1. Na tela inicial, clique em "Cadastrar"
2. Preencha os dados:
   - Nome de usuário
   - Senha
   - Selecione sua série
   - **Selecione a escola onde você estuda**
3. Clique em "Cadastrar"
4. Sua conta será criada e vinculada à escola selecionada

### Para Administradores (Gerenciar Escolas)
Para acessar a página de gerenciamento de escolas, você pode:

**Opção 1: Adicionar um botão na HomePage**
```dart
// No arquivo home_page.dart, adicione:
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageSchoolsPage()),
    );
  },
  child: const Text('Gerenciar Escolas'),
)
```

**Opção 2: Adicionar no menu/drawer**
Se você tiver um Drawer, adicione a navegação lá.

## 📋 Estrutura dos Arquivos Criados/Modificados

### Arquivos Novos:
- `lib/school_model.dart` - Modelo de dados da escola
- `lib/school_service.dart` - Lógica de negócio para escolas
- `lib/manage_schools_page.dart` - Interface de gerenciamento

### Arquivos Modificados:
- `lib/user_model.dart` - Adicionado campo `schoolId`
- `lib/register_page.dart` - Adicionado dropdown de seleção de escola

## 🔄 Próximos Passos Sugeridos

1. **Adicionar link para gerenciar escolas**: Adicione um botão na HomePage ou no menu para acessar `ManageSchoolsPage`

2. **Persistência de dados**: Implementar salvamento em banco de dados (SQLite, Firebase, etc.)

3. **Filtros por escola**: Permitir visualizar alunos de uma escola específica

4. **Estatísticas**: Mostrar quantos alunos estão cadastrados em cada escola

5. **Busca de escolas**: Adicionar campo de busca no dropdown para facilitar a seleção

## 💡 Exemplo de Uso na HomePage

Para integrar o gerenciamento de escolas na sua HomePage, adicione este código:

```dart
import 'manage_schools_page.dart';

// Dentro do build method:
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageSchoolsPage()),
    );
  },
  icon: const Icon(Icons.school),
  label: const Text('Gerenciar Escolas'),
)
```

## 🎨 Interface Visual

A interface foi melhorada com:
- Ícones informativos para cada campo
- Mensagem de ajuda no campo de escola
- Layout responsivo com scroll
- Cards visuais na lista de escolas
- Confirmação antes de excluir escolas

## ✅ Validações Implementadas

- ✅ Nome de usuário obrigatório
- ✅ Senha obrigatória
- ✅ Série obrigatória
- ✅ **Escola obrigatória** (novo)
- ✅ Nome da escola obrigatório ao adicionar nova escola

Login → Séries → Matérias → **TÓPICOS** → Quiz
