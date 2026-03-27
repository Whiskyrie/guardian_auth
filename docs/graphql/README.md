# Guardian Auth GraphQL API

Guardian Auth API - Sistema de autenticação e autorização com JWT e GraphQL

## Queries

### node

Busca um objeto pelo seu ID global único (Global ID)

**Type:** `Types::NodeType`

**Arguments:**

- `id`: `#<GraphQL::Schema::NonNull:0x00007f1514529ba0>` (required)
  - ID global único do objeto a ser buscado

### nodes

Busca objetos pelos seus IDs globais únicos

**Type:** `#<GraphQL::Schema::List:0x00007f15144dfc58>`

**Arguments:**

- `ids`: `#<GraphQL::Schema::NonNull:0x00007f15144dfbb8>` (required)
  - Lista de IDs globais únicos dos objetos a serem buscados

### currentUser

Obtém informações do usuário logado através do token JWT no header Authorization

**Type:** `Types::UserType`

### users

Lista todos os usuários com filtros e paginação (apenas administradores)

**Type:** `#<GraphQL::Schema::NonNull:0x00007f15144f9040>`

**Arguments:**

- `role`: `Types::UserRoleEnum` (optional)
  - Filter by user role
- `search`: `GraphQL::Types::String` (optional)
  - Search by name or email
- `createdAfter`: `GraphQL::Types::ISO8601Date` (optional)
  - Show users created after this date
- `createdBefore`: `GraphQL::Types::ISO8601Date` (optional)
  - Show users created before this date
- `after`: `GraphQL::Types::String` (optional)
  - Returns the elements in the list that come after the specified cursor.
- `before`: `GraphQL::Types::String` (optional)
  - Returns the elements in the list that come before the specified cursor.
- `first`: `GraphQL::Types::Int` (optional)
  - Returns the first _n_ elements from the list.
- `last`: `GraphQL::Types::Int` (optional)
  - Returns the last _n_ elements from the list.

### user

Busca um usuário específico pelo ID (apenas administradores)

**Type:** `Types::UserType`

**Arguments:**

- `id`: `#<GraphQL::Schema::NonNull:0x00007f1514529ba0>` (required)
  - O ID do usuário a ser buscado

### auditLogs

Consulta logs de auditoria para monitoramento de segurança (apenas administradores)

**Type:** `#<GraphQL::Schema::NonNull:0x00007f15144f1520>`

**Arguments:**

- `userId`: `GraphQL::Types::ID` (optional)
  - Filter by specific user ID
- `action`: `GraphQL::Types::String` (optional)
  - Filter by specific action
- `resource`: `GraphQL::Types::String` (optional)
  - Filter by resource type
- `result`: `GraphQL::Types::String` (optional)
  - Filter by result (success, failure, blocked)
- `startDate`: `GraphQL::Types::ISO8601Date` (optional)
  - Start date for filtering
- `endDate`: `GraphQL::Types::ISO8601Date` (optional)
  - End date for filtering
- `recentHours`: `GraphQL::Types::Int` (optional)
  - Filter logs from last N hours
- `ipAddress`: `GraphQL::Types::String` (optional)
  - Filter by IP address
- `failureReason`: `GraphQL::Types::String` (optional)
  - Filter by failure reason
- `after`: `GraphQL::Types::String` (optional)
  - Returns the elements in the list that come after the specified cursor.
- `before`: `GraphQL::Types::String` (optional)
  - Returns the elements in the list that come before the specified cursor.
- `first`: `GraphQL::Types::Int` (optional)
  - Returns the first _n_ elements from the list.
- `last`: `GraphQL::Types::Int` (optional)
  - Returns the last _n_ elements from the list.

### testField

Campo de teste para verificar conectividade da API

**Type:** `#<GraphQL::Schema::NonNull:0x00007f15145cbae0>`

## Mutations

### registerUser

Registra um novo usuário no sistema

**Type:** `#<Class:0x00007f151459bea8>`

**Arguments:**

- `input`: `#<GraphQL::Schema::NonNull:0x00007f1514528480>` (required)
  - Parameters for RegisterUser

### loginUser

Autentica um usuário e retorna token JWT

**Type:** `#<Class:0x00007f1514557140>`

**Arguments:**

- `input`: `#<GraphQL::Schema::NonNull:0x00007f1514527828>` (required)
  - Parameters for LoginUser

### refreshToken

Renova um token JWT válido antes de expirar

**Type:** `#<Class:0x00007f15145552a0>`

**Arguments:**

- `input`: `#<GraphQL::Schema::NonNull:0x00007f1514526ea0>` (required)
  - Parameters for RefreshToken

### logoutUser

Desconecta o usuário atual e invalida o token

**Type:** `#<Class:0x00007f1514553b80>`

**Arguments:**

- `input`: `#<GraphQL::Schema::NonNull:0x00007f15145260b8>` (required)
  - Parameters for LogoutUser

### logoutAllDevices

Desconecta o usuário de todos os dispositivos

**Type:** `#<Class:0x00007f1514552140>`

**Arguments:**

- `input`: `#<GraphQL::Schema::NonNull:0x00007f1514525708>` (required)
  - Parameters for LogoutAllDevices

### changePassword

Altera a senha do usuário autenticado

**Type:** `#<Class:0x00007f15145503e0>`

**Arguments:**

- `input`: `#<GraphQL::Schema::NonNull:0x00007f1514524da8>` (required)
  - Parameters for ChangePassword

### updateMyProfile

Atualiza o perfil do usuário autenticado

**Type:** `#<Class:0x00007f151453d538>`

**Arguments:**

- `input`: `#<GraphQL::Schema::NonNull:0x00007f1514524448>` (required)
  - Parameters for UpdateMyProfile

### updateUser

Atualiza dados de um usuário específico (apenas administradores)

**Type:** `#<Class:0x00007f151453b738>`

**Arguments:**

- `input`: `#<GraphQL::Schema::NonNull:0x00007f15145236d8>` (required)
  - Parameters for UpdateUser

### updateUserByEmail

Atualiza dados de um usuário pelo email (apenas administradores)

**Type:** `#<Class:0x00007f1514539898>`

**Arguments:**

- `input`: `#<GraphQL::Schema::NonNull:0x00007f1514522d00>` (required)
  - Parameters for UpdateUserByEmail

### deleteUser

Remove um usuário do sistema (apenas administradores)

**Type:** `#<Class:0x00007f1514537e58>`

**Arguments:**

- `input`: `#<GraphQL::Schema::NonNull:0x00007f15145223c8>` (required)
  - Parameters for DeleteUser

### updateUserRole

Atualiza o papel/função de um usuário (apenas administradores)

**Type:** `#<Class:0x00007f1514535d38>`

**Arguments:**

- `input`: `#<GraphQL::Schema::NonNull:0x00007f1514521a68>` (required)
  - Parameters for UpdateUserRole

## Types

### Mutation

Ponto de entrada para todas as mutações (alterações de dados) no sistema Guardian Auth

**Fields:**

- `registerUser`: `#<Class:0x00007f151459bea8>`
  - Registra um novo usuário no sistema
- `loginUser`: `#<Class:0x00007f1514557140>`
  - Autentica um usuário e retorna token JWT
- `refreshToken`: `#<Class:0x00007f15145552a0>`
  - Renova um token JWT válido antes de expirar
- `logoutUser`: `#<Class:0x00007f1514553b80>`
  - Desconecta o usuário atual e invalida o token
- `logoutAllDevices`: `#<Class:0x00007f1514552140>`
  - Desconecta o usuário de todos os dispositivos
- `changePassword`: `#<Class:0x00007f15145503e0>`
  - Altera a senha do usuário autenticado
- `updateMyProfile`: `#<Class:0x00007f151453d538>`
  - Atualiza o perfil do usuário autenticado
- `updateUser`: `#<Class:0x00007f151453b738>`
  - Atualiza dados de um usuário específico (apenas administradores)
- `updateUserByEmail`: `#<Class:0x00007f1514539898>`
  - Atualiza dados de um usuário pelo email (apenas administradores)
- `deleteUser`: `#<Class:0x00007f1514537e58>`
  - Remove um usuário do sistema (apenas administradores)
- `updateUserRole`: `#<Class:0x00007f1514535d38>`
  - Atualiza o papel/função de um usuário (apenas administradores)

### RegisterUserPayload

Autogenerated return type of RegisterUser.

**Fields:**

- `clientMutationId`: `GraphQL::Types::String`
  - A unique identifier for the client performing the mutation.
- `token`: `GraphQL::Types::String`
  - JWT authentication token
- `user`: `Types::UserType`
  - Created user object
- `errors`: `#<GraphQL::Schema::NonNull:0x00007f1514528f70>`
  - List of validation errors

### User

Representa um usuário do sistema Guardian Auth

**Fields:**

- `id`: `#<GraphQL::Schema::NonNull:0x00007f1514529ba0>`
  - Identificador único do usuário
- `email`: `#<GraphQL::Schema::NonNull:0x00007f15145cbae0>`
  - Endereço de email do usuário (único no sistema)
- `firstName`: `GraphQL::Types::String`
  - Primeiro nome do usuário
- `lastName`: `GraphQL::Types::String`
  - Sobrenome do usuário
- `role`: `Types::UserRoleEnum`
  - Papel/função primário do usuário
- `roles`: `#<GraphQL::Schema::List:0x00007f1514529628>`
  - Lista de papéis/funções do usuário
- `lastLoginAt`: `GraphQL::Types::ISO8601DateTime`
  - Data e hora do último login do usuário
- `createdAt`: `#<GraphQL::Schema::NonNull:0x00007f1514529330>`
  - Data e hora de criação da conta
- `updatedAt`: `#<GraphQL::Schema::NonNull:0x00007f1514529330>`
  - Data e hora da última atualização dos dados
- `fullName`: `GraphQL::Types::String`
  - Nome completo do usuário (primeiro nome + sobrenome)
- `displayName`: `#<GraphQL::Schema::NonNull:0x00007f15145cbae0>`
  - Nome de exibição do usuário (nome completo se disponível, senão email)

### UserError

Erro estruturado com código e campo para identificação programática

**Fields:**

- `message`: `#<GraphQL::Schema::NonNull:0x00007f15145cbae0>`
  - Mensagem legível para o usuário
- `code`: `GraphQL::Types::String`
  - Código de erro estruturado (ex: VALIDATION_FAILED, AUTHENTICATION_REQUIRED)
- `field`: `GraphQL::Types::String`
  - Nome do campo que causou o erro em erros de validação (ex: "email")

### LoginUserPayload

Autogenerated return type of LoginUser.

**Fields:**

- `clientMutationId`: `GraphQL::Types::String`
  - A unique identifier for the client performing the mutation.
- `token`: `GraphQL::Types::String`
  - JWT authentication token
- `user`: `Types::UserType`
  - Authenticated user object
- `errors`: `#<GraphQL::Schema::NonNull:0x00007f1514528f70>`
  - List of authentication errors

### RefreshTokenPayload

Autogenerated return type of RefreshToken.

**Fields:**

- `clientMutationId`: `GraphQL::Types::String`
  - A unique identifier for the client performing the mutation.
- `token`: `GraphQL::Types::String`
  - New JWT authentication token
- `user`: `Types::UserType`
  - Current user object
- `errors`: `#<GraphQL::Schema::NonNull:0x00007f1514528f70>`
  - List of refresh errors

### LogoutUserPayload

Autogenerated return type of LogoutUser.

**Fields:**

- `clientMutationId`: `GraphQL::Types::String`
  - A unique identifier for the client performing the mutation.
- `success`: `#<GraphQL::Schema::NonNull:0x00007f15145da040>`
- `message`: `GraphQL::Types::String`

### LogoutAllDevicesPayload

Autogenerated return type of LogoutAllDevices.

**Fields:**

- `clientMutationId`: `GraphQL::Types::String`
  - A unique identifier for the client performing the mutation.
- `success`: `#<GraphQL::Schema::NonNull:0x00007f15145da040>`
- `message`: `GraphQL::Types::String`

### ChangePasswordPayload

Autogenerated return type of ChangePassword.

**Fields:**

- `clientMutationId`: `GraphQL::Types::String`
  - A unique identifier for the client performing the mutation.
- `user`: `Types::UserType`
  - Updated user object
- `errors`: `#<GraphQL::Schema::NonNull:0x00007f1514528f70>`
  - List of validation errors

### UpdateMyProfilePayload

Autogenerated return type of UpdateMyProfile.

**Fields:**

- `clientMutationId`: `GraphQL::Types::String`
  - A unique identifier for the client performing the mutation.
- `user`: `Types::UserType`
- `errors`: `#<GraphQL::Schema::NonNull:0x00007f1514528f70>`

### UpdateUserPayload

Autogenerated return type of UpdateUser.

**Fields:**

- `clientMutationId`: `GraphQL::Types::String`
  - A unique identifier for the client performing the mutation.
- `user`: `Types::UserType`
- `errors`: `#<GraphQL::Schema::NonNull:0x00007f1514528f70>`

### UpdateUserByEmailPayload

Autogenerated return type of UpdateUserByEmail.

**Fields:**

- `clientMutationId`: `GraphQL::Types::String`
  - A unique identifier for the client performing the mutation.
- `user`: `Types::UserType`
- `errors`: `#<GraphQL::Schema::NonNull:0x00007f1514528f70>`

### DeleteUserPayload

Autogenerated return type of DeleteUser.

**Fields:**

- `clientMutationId`: `GraphQL::Types::String`
  - A unique identifier for the client performing the mutation.
- `success`: `#<GraphQL::Schema::NonNull:0x00007f15145da040>`
  - Whether the deletion was successful
- `message`: `#<GraphQL::Schema::NonNull:0x00007f15145cbae0>`
  - Confirmation message
- `errors`: `#<GraphQL::Schema::NonNull:0x00007f1514528f70>`
  - Any error messages

### UpdateUserRolePayload

Autogenerated return type of UpdateUserRole.

**Fields:**

- `clientMutationId`: `GraphQL::Types::String`
  - A unique identifier for the client performing the mutation.
- `user`: `Types::UserType`
  - Updated user
- `success`: `#<GraphQL::Schema::NonNull:0x00007f15145da040>`
  - Whether the operation was successful
- `message`: `#<GraphQL::Schema::NonNull:0x00007f15145cbae0>`
  - Result message
- `errors`: `#<GraphQL::Schema::NonNull:0x00007f1514528f70>`
  - Any error messages

### Query

Ponto de entrada para todas as consultas no sistema Guardian Auth

**Fields:**

- `node`: `Types::NodeType`
  - Busca um objeto pelo seu ID global único (Global ID)
- `nodes`: `#<GraphQL::Schema::List:0x00007f15144dfc58>`
  - Busca objetos pelos seus IDs globais únicos
- `currentUser`: `Types::UserType`
  - Obtém informações do usuário logado através do token JWT no header Authorization
- `users`: `#<GraphQL::Schema::NonNull:0x00007f15144f9040>`
  - Lista todos os usuários com filtros e paginação (apenas administradores)
- `user`: `Types::UserType`
  - Busca um usuário específico pelo ID (apenas administradores)
- `auditLogs`: `#<GraphQL::Schema::NonNull:0x00007f15144f1520>`
  - Consulta logs de auditoria para monitoramento de segurança (apenas administradores)
- `testField`: `#<GraphQL::Schema::NonNull:0x00007f15145cbae0>`
  - Campo de teste para verificar conectividade da API

### UserConnection

The connection type for User.

**Fields:**

- `edges`: `#<GraphQL::Schema::List:0x00007f15144df438>`
  - A list of edges.
- `nodes`: `#<GraphQL::Schema::List:0x00007f15144def38>`
  - A list of nodes.
- `pageInfo`: `#<GraphQL::Schema::NonNull:0x00007f15144df820>`
  - Information to aid in pagination.

### PageInfo

Information about pagination in a connection.

**Fields:**

- `hasNextPage`: `#<GraphQL::Schema::NonNull:0x00007f15145da040>`
  - When paginating forwards, are there more items?
- `hasPreviousPage`: `#<GraphQL::Schema::NonNull:0x00007f15145da040>`
  - When paginating backwards, are there more items?
- `startCursor`: `GraphQL::Types::String`
  - When paginating backwards, the cursor to continue.
- `endCursor`: `GraphQL::Types::String`
  - When paginating forwards, the cursor to continue.

### UserEdge

An edge in a connection.

**Fields:**

- `node`: `Types::UserType`
  - The item at the end of the edge.
- `cursor`: `#<GraphQL::Schema::NonNull:0x00007f15145cbae0>`
  - A cursor for use in pagination.

### AuditLogConnection

The connection type for AuditLog.

**Fields:**

- `edges`: `#<GraphQL::Schema::List:0x00007f15144dd5e8>`
  - A list of edges.
- `nodes`: `#<GraphQL::Schema::List:0x00007f15144dcd28>`
  - A list of nodes.
- `pageInfo`: `#<GraphQL::Schema::NonNull:0x00007f15144df820>`
  - Information to aid in pagination.

### AuditLogEdge

An edge in a connection.

**Fields:**

- `node`: `Types::AuditLogType`
  - The item at the end of the edge.
- `cursor`: `#<GraphQL::Schema::NonNull:0x00007f15145cbae0>`
  - A cursor for use in pagination.

### AuditLog

Audit log entry for security and compliance tracking

**Fields:**

- `id`: `#<GraphQL::Schema::NonNull:0x00007f1514529ba0>`
  - Unique identifier for the audit log entry
- `action`: `#<GraphQL::Schema::NonNull:0x00007f15145cbae0>`
  - Action performed (login, logout, register, etc)
- `resource`: `#<GraphQL::Schema::NonNull:0x00007f15145cbae0>`
  - Resource type (User, Token, etc)
- `resourceId`: `GraphQL::Types::String`
  - ID of the affected resource
- `metadata`: `Types::JsonType`
  - Additional metadata including IP, user agent, etc
- `result`: `#<GraphQL::Schema::NonNull:0x00007f15145cbae0>`
  - Result of the action (success, failure, blocked)
- `createdAt`: `#<GraphQL::Schema::NonNull:0x00007f15144dd020>`
  - When the action occurred
- `user`: `Types::UserType`
  - User who performed the action
- `ipAddress`: `GraphQL::Types::String`
  - IP address from which the action originated
- `userAgent`: `GraphQL::Types::String`
  - User agent string from the request
- `requestId`: `GraphQL::Types::String`
  - Unique request identifier
- `failureReason`: `GraphQL::Types::String`
  - Reason for failure if applicable
- `previousValues`: `Types::JsonType`
  - Previous values before update
