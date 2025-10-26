# AGENTS.md - Guardian Auth

Sistema de autenticação robusto construído com Ruby on Rails 8, GraphQL e JWT.

---

## Build & Test

### Instalação e Configuração Inicial

```bash
# Clonar repositório
git clone https://github.com/Whiskyrie/guardian_auth.git
cd guardian_auth

# Instalar dependências Ruby
bundle install

# Configurar banco de dados
rails db:create
rails db:migrate

# Carregar seeds (idempotente)
rails db:seed

# Iniciar servidor de desenvolvimento
rails server
# API disponível em: http://localhost:3000
# GraphQL Playground: http://localhost:3000/graphiql
```

### Comandos de Banco de Dados

```bash
# Recriar banco com seeds
rails db:setup

# Reset completo do banco
rails db:reset

# Rollback de uma migração
rails db:rollback

# Status das migrações
rails db:migrate:status
```

### Linting e Qualidade de Código

```bash
# Verificar problemas de estilo (RuboCop)
bundle exec rubocop

# Corrigir problemas automaticamente
bundle exec rubocop -a

# Verificar vulnerabilidades de segurança (Brakeman)
bundle exec brakeman
```

### Testes

```bash
# Executar todos os testes
rails test

# Executar teste específico
rails test test/models/user_test.rb

# Executar testes com cobertura
rails test:coverage
```

### Deploy com Kamal

```bash
# Setup inicial do Kamal
bundle exec kamal setup

# Deploy para produção
bundle exec kamal deploy

# Verificar status
bundle exec kamal details

# Configurar variáveis de ambiente de produção
bundle exec kamal env set --production
```

---

## Arquitetura do Projeto

### Stack Tecnológica

- **Backend**: Ruby on Rails 8.0.2
- **Banco de Dados**: PostgreSQL 14+
- **API**: GraphQL (gem `graphql`)
- **Autenticação**: JWT (JSON Web Tokens)
- **Autorização**: Pundit (políticas baseadas em roles)
- **Web Server**: Puma
- **Deploy**: Kamal + Docker
- **Cache**: Solid Cache
- **Filas**: Solid Queue
- **WebSockets**: Solid Cable
- **Rate Limiting**: Rack Attack

### Estrutura de Diretórios

```
app/
├── controllers/         # Controllers Rails
│   └── concerns/        # Concerns reutilizáveis (Authentication, etc)
├── graphql/            # Schema e tipos GraphQL
│   ├── mutations/      # Mutations GraphQL (LoginUser, RegisterUser, etc)
│   ├── resolvers/      # Resolvers GraphQL
│   ├── types/          # Tipos GraphQL (UserType, ErrorType, etc)
│   └── errors/         # Classes de erro customizadas
├── models/             # Models ActiveRecord (User, etc)
├── policies/           # Políticas Pundit para autorização
└── services/           # Serviços de negócio (JwtService, etc)

config/
├── initializers/       # Inicializadores (rack_attack.rb, etc)
└── locales/           # Arquivos i18n (pt-BR, en)

db/
├── migrate/           # Migrações do banco
└── seeds/             # Seeds específicos por ambiente
```

### Fluxo de Autenticação

1. **Registro** (`registerUser`): Cria usuário → Gera JWT token
2. **Login** (`loginUser`): Valida credenciais → Retorna JWT token
3. **Refresh** (`refreshToken`): Valida token expirado → Gera novo token
4. **Autorização**: Valida JWT + verifica policies Pundit

### Componentes Críticos

**JwtService** (`app/services/jwt_service.rb`):
- `encode(payload, exp)`: Gera token JWT com expiração
- `decode(token)`: Decodifica e valida token
- `valid_token?(token)`: Verifica validade incluindo blacklist
- `blacklist_token!(token, user_id, reason)`: Adiciona token à blacklist

**Authentication Concern** (`app/controllers/concerns/authentication.rb`):
- `current_user_from_token`: Extrai usuário do JWT header
- `authenticate_user!`: Garante que requisição está autenticada

**Políticas Pundit** (`app/policies/`):
- `ApplicationPolicy`: Base para todas as políticas
- `UserPolicy`: Controla acesso a operações de usuário
- Helper methods: `admin?`, `owner?`

---

## Convenções & Padrões

### Princípios Fundamentais

**Clean Code é obrigatório**. Todo código Rails deve ser:
- Idiomático e seguindo convenções Rails
- Autoexplicativo através de nomes descritivos
- Modular com responsabilidades bem definidas
- Testável e com cobertura adequada

### Nomenclatura Ruby on Rails

**Classes e Módulos**:
```ruby
# Bom - PascalCase
class UserAuthentication
  # implementação
end

module GraphqlHelpers
  # implementação
end

# Evitar
class user_authentication
end
```

**Métodos e Variáveis**:
```ruby
# Bom - snake_case, nomes descritivos
def calculate_token_expiration
  24.hours.from_now
end

def user_already_exists?(email)
  User.exists?(email: email)
end

# Evitar - nomes curtos ou confusos
def calc_exp
  # ...
end

def exists?(e)
  # ...
end
```

**Constantes**:
```ruby
# Bom - SCREAMING_SNAKE_CASE
MAX_LOGIN_ATTEMPTS = 5
TOKEN_EXPIRATION_TIME = 24.hours

# Evitar
maxLoginAttempts = 5
```

**Arquivos**:
- Use `snake_case` para nomes de arquivos
- Exemplo: `jwt_service.rb`, `user_policy.rb`, `login_user.rb`

### GraphQL Conventions

**Types**:
```ruby
# Bom - PascalCase com sufixo Type
module Types
  class UserType < Types::BaseObject
    field :id, ID, null: false
    field :email, String, null: false
    field :first_name, String, null: false
  end
end
```

**Mutations**:
```ruby
# Bom - PascalCase, verbo + substantivo
module Mutations
  class RegisterUser < BaseMutation
    argument :email, String, required: true
    argument :password, String, required: true
    
    field :token, String, null: true
    field :user, Types::UserType, null: true
    field :errors, [String], null: false
    
    def resolve(email:, password:)
      # implementação clara e concisa
    end
  end
end

# Evitar - lógica complexa no resolve
def resolve(email:, password:)
  # 100+ linhas de código aqui
  # Extrair para service objects!
end
```

**Error Codes**:
```ruby
# Bom - usar constantes do módulo ErrorCodes
module Errors
  module ErrorCodes
    AUTHENTICATION_REQUIRED = 'AUTHENTICATION_REQUIRED'
    INVALID_TOKEN = 'INVALID_TOKEN'
    # ...
  end
end

# Uso:
raise Errors::AuthenticationError.new(
  'Token inválido',
  code: Errors::ErrorCodes::INVALID_TOKEN
)
```

### Comentários em Ruby

```ruby
# Comentário útil - explica o "porquê"
# Bloqueamos tokens expirados há mais de 7 dias para segurança
max_refresh_window = 7.days.ago.to_i

# Comentário desnecessário - repete o código
# Incrementa o contador
counter += 1
```

### DRY (Don't Repeat Yourself)

```ruby
# Bom - extrair lógica repetida
class User < ApplicationRecord
  def full_name
    "#{first_name} #{last_name}".strip
  end
  
  def track_login!
    update_column(:last_login_at, Time.current)
  end
end

# Uso
user.track_login!

# Evitar - duplicação
user.update_column(:last_login_at, Time.current) # repetido em 5 lugares
```

### Service Objects

Use service objects para lógica de negócio complexa:

```ruby
# Bom - responsabilidade única
class JwtService
  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    payload[:iat] = Time.current.to_i
    JWT.encode(payload, SECRET_KEY)
  end
  
  def self.decode(token)
    # lógica de decodificação
  end
end

# Evitar - lógica complexa no controller ou mutation
def resolve(email:, password:)
  # 50 linhas de lógica JWT aqui
end
```

### Tratamento de Erros

```ruby
# Bom - erros específicos e logs apropriados
def resolve(email:, password:)
  user = User.find_by(email: email)
  
  unless user&.authenticate(password)
    AuditLogger.log_login(
      email: email,
      success: false,
      failure_reason: 'invalid_credentials'
    )
    
    return {
      token: nil,
      user: nil,
      errors: ['Email ou senha inválidos']
    }
  end
  
  # continua...
rescue StandardError => e
  Rails.logger.error "LoginUser error: #{e.message}"
  { errors: ['Falha na autenticação'] }
end

# Evitar - engolir erros silenciosamente
def resolve(email:, password:)
  user = User.find_by(email: email)
  user.authenticate(password)
rescue
  nil
end
```

### ActiveRecord Conventions

```ruby
# Bom - queries eficientes e claras
class User < ApplicationRecord
  scope :active, -> { where(active: true) }
  scope :admins, -> { where(role: 'admin') }
  
  validates :email, presence: true, uniqueness: true
  validates :password, length: { minimum: 8 }
  
  has_secure_password
end

# Uso
User.active.admins.where('created_at > ?', 1.week.ago)

# Evitar - queries N+1
users.each do |user|
  user.posts.each do |post|  # N+1 query!
    puts post.title
  end
end

# Corrigir com includes
users.includes(:posts).each do |user|
  user.posts.each do |post|
    puts post.title
  end
end
```

---

## Segurança e Rate Limiting

### Rack Attack Configuration

O projeto usa **Rack Attack** para rate limiting. Configuração em `config/initializers/rack_attack.rb`:

```ruby
# GraphQL requests: 60 por minuto
throttle('graphql requests', limit: 60, period: 1.minute)

# Login attempts: escalonamento exponencial
# Level 1: 5 tentativas em 2 minutos
# Level 2: 10 tentativas em 4 minutos
# Level 3: 15 tentativas em 8 minutos
```

### JWT Token Blacklist

Tokens podem ser invalidados através do `TokenBlacklist`:

```ruby
# Invalidar token específico
JwtService.blacklist_token!(token, user_id, reason: 'logout')

# Invalidar todos os tokens de um usuário
JwtService.blacklist_user_tokens!(user_id, reason: 'password_change')
```

### Logging de Segurança

```ruby
# Log de tentativas de login
AuditLogger.log_login(
  email: email,
  success: true/false,
  ip: request.remote_ip,
  user_agent: request.user_agent
)

# Log de atividade suspeita
SecurityLogger.log_suspicious_activity(
  ip: request.remote_ip,
  activity: 'brute_force_attempt',
  details: { attempts: 10 }
)
```

---

## Internacionalização (i18n)

O projeto suporta múltiplos idiomas com arquivos em `config/locales/`:

- `graphql.pt-BR.yml`: Mensagens de erro em português
- `graphql.en.yml`: Mensagens de erro em inglês

```yaml
# config/locales/graphql.pt-BR.yml
pt-BR:
  graphql:
    errors:
      authentication:
        required: "Autenticação obrigatória"
        invalid_credentials: "Email ou senha inválidos"
```

Uso nos mutations:
```ruby
errors: [I18n.t('graphql.errors.authentication.invalid_credentials')]
```

---

## Dados de Teste (Seeds)

### Usuários Padrão (Desenvolvimento)

**Admins**:
- `admin@guardian.com` / senha: `Admin123456` (role: admin)
- `admin2@test.com` / senha: `User123456` (role: admin)

**Usuários**:
- `demo@guardian.com` / senha: `Demo123456` (role: user)
- `user1@test.com` até `user5@test.com` / senha: `User123456` (role: user)

### Seeds por Ambiente

Seeds estão organizados em `db/seeds/`:
- `development.rb`: Dados para desenvolvimento
- `production.rb`: Dados mínimos para produção
- `README.md`: Documentação completa dos seeds

```bash
# Carregar seeds
rails db:seed

# Seeds são idempotentes - podem ser executados múltiplas vezes
```

---

## Variáveis de Ambiente

```bash
# Database
DATABASE_URL=postgresql://username:password@localhost:5432/guardian_auth_development

# JWT Secret (gerado com: rails secret)
SECRET_KEY_BASE=sua_chave_secreta_de_64_caracteres_aqui

# Rails Environment
RAILS_ENV=development

# Redis (para rate limiting)
REDIS_URL=redis://localhost:6379/0
```

Crie arquivo `.env` baseado em `.env.example` para desenvolvimento local.

---

## GraphQL API

### Endpoint

- **URL**: `http://localhost:3000/graphql`
- **GraphQL Playground**: `http://localhost:3000/graphiql` (apenas desenvolvimento)
- **Método**: POST
- **Content-Type**: `application/json`

### Mutations Disponíveis

#### Registrar Usuário
```graphql
mutation {
  registerUser(
    email: "joao@example.com",
    password: "SenhaSegura123",
    firstName: "João",
    lastName: "Silva"
  ) {
    token
    user { id email firstName lastName }
    errors
  }
}
```

#### Login
```graphql
mutation {
  loginUser(
    email: "joao@example.com",
    password: "SenhaSegura123"
  ) {
    token
    user { id email firstName lastName role }
    errors
  }
}
```

#### Refresh Token
```graphql
mutation {
  refreshToken(token: "eyJhbGciOiJIUzI1...") {
    token
    user { id email }
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
    role
    createdAt
    updatedAt
  }
}
```

### Autenticação em Requisições

Inclua o token JWT no header:
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

---

## Git Workflow

### Branch Strategy

- `main`: código de produção
- `develop`: branch de desenvolvimento
- `feature/nome-da-feature`: novas funcionalidades
- `fix/nome-do-bug`: correções de bugs
- `hotfix/nome-urgente`: correções urgentes em produção

### Commits Convencionais

```bash
# Formato
tipo(escopo): descrição curta em português

# Tipos permitidos
feat(auth): adiciona refresh token automático
fix(graphql): corrige validação de email no registro
refactor(jwt): extrai lógica de blacklist para service
docs(readme): atualiza documentação da API
test(user): adiciona testes para validação de senha
chore(deps): atualiza dependências do Rails

# Commit com corpo
feat(rate-limit): implementa rate limiting por IP

Adiciona Rack Attack para limitar requisições:
- 60 requisições por minuto no GraphQL
- Escalonamento exponencial para tentativas de login
- Blacklist automática após atividade suspeita
```

### Pull Requests

1. Crie branch a partir de `develop`
2. Implemente a funcionalidade com testes
3. Execute `bundle exec rubocop` e corrija issues
4. Execute `bundle exec brakeman` para segurança
5. Execute testes: `rails test`
6. Crie PR para `develop` com descrição clara
7. Solicite code review
8. Merge após aprovação

---

## Refatoração

### Sinais de Código que Precisa Refatoração

1. **Mutations com >50 linhas**: Extrair para service objects
2. **Duplicação de lógica**: Criar concerns ou helpers
3. **Queries N+1**: Usar `includes`, `joins` ou `preload`
4. **Lógica complexa em callbacks**: Mover para service objects
5. **Validações customizadas complexas**: Criar custom validators

### Exemplo de Refatoração

**Antes** (mutation com muita lógica):
```ruby
module Mutations
  class RegisterUser < BaseMutation
    def resolve(email:, password:, first_name:, last_name:)
      email = email.downcase.strip
      
      if User.exists?(email: email)
        return { errors: ['Email já existe'] }
      end
      
      if password.length < 8
        return { errors: ['Senha muito curta'] }
      end
      
      user = User.create(
        email: email,
        password: password,
        first_name: first_name,
        last_name: last_name
      )
      
      if user.persisted?
        token = JWT.encode(
          { user_id: user.id, exp: 24.hours.from_now.to_i },
          Rails.application.credentials.secret_key_base
        )
        { token: token, user: user, errors: [] }
      else
        { errors: user.errors.full_messages }
      end
    end
  end
end
```

**Depois** (refatorado):
```ruby
module Mutations
  class RegisterUser < BaseMutation
    def resolve(email:, password:, first_name:, last_name:)
      result = UserRegistrationService.call(
        email: email,
        password: password,
        first_name: first_name,
        last_name: last_name
      )
      
      if result.success?
        {
          token: result.token,
          user: result.user,
          errors: []
        }
      else
        {
          token: nil,
          user: nil,
          errors: result.errors
        }
      end
    end
  end
end

# app/services/user_registration_service.rb
class UserRegistrationService
  def self.call(email:, password:, first_name:, last_name:)
    new(email, password, first_name, last_name).call
  end
  
  def initialize(email, password, first_name, last_name)
    @email = email.downcase.strip
    @password = password
    @first_name = first_name.strip
    @last_name = last_name.strip
  end
  
  def call
    return failure(['Email já existe']) if email_exists?
    
    user = create_user
    return failure(user.errors.full_messages) unless user.persisted?
    
    success(user, generate_token(user))
  end
  
  private
  
  def email_exists?
    User.exists?(email: @email)
  end
  
  def create_user
    User.create(
      email: @email,
      password: @password,
      first_name: @first_name,
      last_name: @last_name
    )
  end
  
  def generate_token(user)
    JwtService.encode(user_id: user.id)
  end
  
  def success(user, token)
    OpenStruct.new(success?: true, user: user, token: token)
  end
  
  def failure(errors)
    OpenStruct.new(success?: false, errors: errors)
  end
end
```

**Benefícios da refatoração**:
- Mutation focada apenas em GraphQL
- Lógica de negócio isolada e testável
- Reutilizável em outros contextos (API REST, console, jobs)
- Mais fácil de manter e estender

---

## Checklist Antes de Commitar

- [ ] Código segue convenções Rails (snake_case, etc)
- [ ] Mutations retornam estrutura consistente: `{ token, user, errors }`
- [ ] Lógica de negócio complexa extraída para services
- [ ] Não há queries N+1 (verificar com `bullet` gem em dev)
- [ ] Erros tratados adequadamente com logging
- [ ] Tokens JWT validados e blacklist verificada
- [ ] Rate limiting considerado para endpoints sensíveis
- [ ] Testes passam: `rails test`
- [ ] RuboCop passa: `bundle exec rubocop`
- [ ] Brakeman passa: `bundle exec brakeman`
- [ ] Seeds funcionam: `rails db:reset`
- [ ] GraphQL Playground testado manualmente
- [ ] Commit segue padrão convencional

---

## Recursos e Documentação

### GraphQL
- [GraphQL Ruby Gem](https://graphql-ruby.org/)
- [GraphQL Best Practices](https://graphql-ruby.org/guides)

### Segurança
- [Brakeman Security Scanner](https://brakemanscanner.org/)
- [Rack Attack](https://github.com/rack/rack-attack)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

### Rails
- [Rails Guides](https://guides.rubyonrails.org/)
- [Rails API Documentation](https://api.rubyonrails.org/)

### Pundit
- [Pundit Authorization](https://github.com/varvet/pundit)

---

## Notas para Agentes de IA

### Ao Criar Código Ruby/Rails:

1. **Siga convenções Rails idiomáticas**:
   - Use `snake_case` para métodos e variáveis
   - Use `PascalCase` para classes e módulos
   - Prefira ActiveRecord queries sobre SQL raw

2. **GraphQL Mutations devem**:
   - Sempre retornar `{ token, user, errors }` ou estrutura similar
   - Usar `BaseMutation` como parent
   - Ter descrições claras nos fields e arguments
   - Tratar erros gracefully com arrays de strings

3. **Service Objects quando**:
   - Lógica de negócio tem >30 linhas
   - Precisa ser testada isoladamente
   - Será reutilizada em múltiplos lugares
   - Envolve múltiplos models ou external APIs

4. **Segurança sempre**:
   - Validar e sanitizar inputs
   - Usar `authorize` do Pundit para autorização
   - Logar atividades sensíveis (login, logout, mudança de senha)
   - Rate limit em mutations públicas (login, register)

5. **Testes são obrigatórios**:
   - Unit tests para models e services
   - Integration tests para mutations
   - Usar fixtures ou factories consistentes

### Ao Refatorar:

1. **Identifique code smells**:
   - Long methods (>50 linhas)
   - God classes (>300 linhas)
   - Duplicação de código
   - Callbacks complexos em models

2. **Sugira melhorias com**:
   - Código antes e depois
   - Justificativa clara dos benefícios
   - Testes para validar refatoração

3. **Preserve comportamento**:
   - Execute testes antes e depois
   - Mantenha mesma API pública
   - Documente breaking changes se necessário

### Ao Responder Perguntas sobre Arquitetura:

1. **Explique o fluxo completo**:
   - Request → GraphQL → Mutation → Service → Model → Database
   - Onde ocorre autenticação (concern)
   - Onde ocorre autorização (Pundit)
   - Onde ocorre rate limiting (Rack Attack)

2. **Justifique decisões**:
   - Por que GraphQL? (flexibilidade, type safety)
   - Por que JWT? (stateless, escalável)
   - Por que Pundit? (políticas claras e testáveis)
   - Por que Service Objects? (SRP, testabilidade)

3. **Ofereça exemplos práticos** do próprio código do projeto

---

**Última atualização**: 2025-10-26  
**Projeto**: Guardian Auth  
**Stack**: Ruby on Rails 8 + GraphQL + JWT + PostgreSQL
