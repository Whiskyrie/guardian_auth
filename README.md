# Guardian Auth

Uma API de autenticação robusta construída com Ruby on Rails 8, GraphQL e JWT. Este projeto fornece um sistema completo de autenticação e autorização para aplicações modernas.

## 🚀 Funcionalidades

- **Autenticação JWT**: Sistema seguro de autenticação baseado em JSON Web Tokens
- **GraphQL API**: API moderna e flexível com GraphQL
- **Validações Robustas**: Validações completas para usuários, incluindo formato de email e senha forte
- **Autorização com Pundit**: Sistema de autorização baseado em políticas
- **Banco de Dados PostgreSQL**: Banco de dados robusto e escalável
- **Deploy com Kamal**: Deploy simplificado com Docker e Kamal
- **Performance Otimizada**: Cache e filas com Solid Cache e Solid Queue

## 🛠️ Stack Tecnológica

- **Backend**: Ruby on Rails 8.0.2
- **Banco de Dados**: PostgreSQL
- **API**: GraphQL
- **Autenticação**: JWT (JSON Web Tokens)
- **Autorização**: Pundit
- **Web Server**: Puma
- **Deploy**: Kamal + Docker
- **Cache**: Solid Cache
- **Filas**: Solid Queue
- **WebSockets**: Solid Cable

## 📋 Pré-requisitos

- Ruby 3.0+
- PostgreSQL 14+
- Docker (para deploy)
- Kamal (para deploy)

## 🚀 Instalação

1. **Clone o repositório**
   ```bash
   git clone https://github.com/Whiskyrie/guardian_auth.git
   cd guardian_auth
   ```

2. **Instale as dependências**
   ```bash
   bundle install
   ```

3. **Configure o banco de dados**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

## 🌱 Seeds e Dados de Teste

O projeto inclui um sistema robusto de seeds que cria dados específicos por ambiente:

### Usuários Padrão (Desenvolvimento)

**Admins:**
- `admin@guardian.com` / senha: `Admin123456`
- `admin2@test.com` / senha: `User123456`
- `admin3@test.com` / senha: `User123456`

**Usuários:**
- `demo@guardian.com` / senha: `Demo123456`
- `user1@test.com` até `user5@test.com` / senha: `User123456`

### Comandos dos Seeds

```bash
# Executar seeds (idempotente)
rails db:seed

# Recriar banco com seeds
rails db:setup

# Reset completo do banco
rails db:reset
```

Para mais informações sobre seeds, consulte [db/seeds/README.md](db/seeds/README.md).

4. **Configure as variáveis de ambiente**
   ```bash
   cp .env.example .env
   ```
   Edite o arquivo `.env` com suas configurações.

5. **Inicie o servidor**
   ```bash
   rails server
   ```

## 🔧 Configuração

### Variáveis de Ambiente

As seguintes variáveis de ambiente precisam ser configuradas:

```env
# Database
DATABASE_URL=postgresql://username:password@localhost:5432/guardian_auth_development

# JWT Secret
SECRET_KEY_BASE=sua_chave_secreta_aqui

# Rails Environment
RAILS_ENV=development
```

### Configuração do Banco de Dados

O projeto está configurado para usar PostgreSQL. Verifique o arquivo `config/database.yml` para ajustar as configurações de conexão.

## 📚 API Documentation

### Endpoints

#### GraphQL Playground (Desenvolvimento)
- **URL**: `http://localhost:3000/graphiql`
- **Descrição**: Interface interativa para testar queries e mutations GraphQL

#### GraphQL API
- **URL**: `http://localhost:3000/graphql`
- **Método**: POST
- **Content-Type**: application/json

### Mutations Disponíveis

#### Registrar Usuário
```graphql
mutation {
  registerUser(
    input: {
      firstName: "João",
      lastName: "Silva",
      email: "joao.silva@example.com",
      password: "Senha123",
      passwordConfirmation: "Senha123"
    }
  ) {
    user {
      id
      email
      firstName
      lastName
    }
    token
    errors
  }
}
```

#### Login de Usuário
```graphql
mutation {
  loginUser(
    email: "joao.silva@example.com",
    password: "Senha123"
  ) {
    user {
      id
      email
      firstName
      lastName
    }
    token
    errors
  }
}
```

### Queries Disponíveis

#### Obter Usuário Atual
```graphql
query {
  currentUser {
    id
    email
    firstName
    lastName
    createdAt
    updatedAt
  }
}
```

## 🔐 Autenticação

### JWT Token

O sistema utiliza JWT para autenticação. Após o login, você receberá um token que deve ser incluído no header das requisições:

```http
Authorization: Bearer <seu_token_jwt>
```

### Validações

- **Email**: Deve ter formato válido e ser único
- **Senha**: Mínimo de 8 caracteres, deve conter letras e números
- **Nome**: Obrigatório, entre 2 e 50 caracteres

## 🧪 Testes

Para executar os testes:

```bash
# Executar todos os testes
rails test

# Executar testes específicos
rails test test/models/user_test.rb

# Executar testes com coverage
rails test:coverage
```

## 🚀 Deploy

### Usando Kamal

1. **Configure o Kamal**
   ```bash
   bundle exec kamal setup
   ```

2. **Deploy para produção**
   ```bash
   bundle exec kamal deploy
   ```

3. **Verificar status**
   ```bash
   bundle exec kamal details
   ```

### Variáveis de Ambiente de Produção

Configure as variáveis de ambiente de produção:

```bash
bundle exec kamal env set --production
```

## 📊 Estrutura do Projeto

```
app/
├── controllers/         # Controllers Rails
├── graphql/            # Schema e tipos GraphQL
│   ├── mutations/      # Mutations GraphQL
│   ├── resolvers/      # Resolvers GraphQL
│   └── types/          # Tipos GraphQL
├── models/             # Models ActiveRecord
├── policies/           # Políticas de autorização
└── services/           # Serviços de negócio
```

## 🔧 Desenvolvimento

### Linting e Formatação

O projeto utiliza RuboCop para manter o código limpo e consistente:

```bash
# Verificar problemas de estilo
bundle exec rubocop

# Corrigir problemas automaticamente
bundle exec rubocop -a
```

### Segurança

Para verificar vulnerabilidades de segurança:

```bash
bundle exec brakeman
```

## 🤝 Contribuindo

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Crie um Pull Request

## 📄 Licença

Este projeto está licenciado sob a MIT License - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🙋‍♂️ Suporte

Se você tiver alguma dúvida ou problema, por favor:

1. Verifique a documentação
2. Abra uma issue no GitHub
3. Entre em contato com a equipe de desenvolvimento

---

**Desenvolvido com ❤️ usando Ruby on Rails**
