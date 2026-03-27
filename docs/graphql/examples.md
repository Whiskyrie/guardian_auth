# Exemplos de Queries e Mutations

## Autenticação

### Login
```graphql
mutation {
  loginUser(input: {
    email: "user@example.com"
    password: "password123"
  }) {
    token
    user {
      id
      email
      fullName
    }
    errors
  }
}
```

### Usuário Atual
```graphql
query {
  currentUser {
    id
    email
    firstName
    lastName
    role
    fullName
    displayName
    lastLoginAt
  }
}
```

### Listar Usuários (Admin)
```graphql
query {
  users(first: 10) {
    edges {
      node {
        id
        email
        fullName
        role
        createdAt
      }
    }
    pageInfo {
      hasNextPage
      hasPreviousPage
      startCursor
      endCursor
    }
  }
}
```