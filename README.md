# Guardian Auth

A robust authentication API built with Ruby on Rails 8, GraphQL, and JWT. This project provides a complete authentication and authorization system for modern applications.

---

## Features

- **JWT Authentication**: Secure token-based authentication using JSON Web Tokens
- **GraphQL API**: Modern and flexible API layer with full GraphQL support
- **Robust Validations**: Comprehensive user validations including email format and strong password enforcement
- **Policy-based Authorization**: Fine-grained authorization system powered by Pundit
- **PostgreSQL**: Reliable and scalable relational database backend
- **Kamal Deployment**: Streamlined deployment workflow with Docker and Kamal
- **Optimized Performance**: Background jobs and caching via Solid Queue and Solid Cache

---

## Tech Stack

| Layer          | Technology            |
| -------------- | --------------------- |
| Backend        | Ruby on Rails 8.0.2   |
| Database       | PostgreSQL            |
| API            | GraphQL               |
| Authentication | JWT (JSON Web Tokens) |
| Authorization  | Pundit                |
| Web Server     | Puma                  |
| Deployment     | Kamal + Docker        |
| Cache          | Solid Cache           |
| Job Queue      | Solid Queue           |
| WebSockets     | Solid Cable           |

---

## Prerequisites

- Ruby 3.0+
- PostgreSQL 14+
- Docker (for deployment)
- Kamal (for deployment)

---

## Installation

**1. Clone the repository**

```bash
git clone https://github.com/Whiskyrie/guardian_auth.git
cd guardian_auth
```

**2. Install dependencies**

```bash
bundle install
```

**3. Set up the database**

```bash
rails db:create
rails db:migrate
rails db:seed
```

**4. Configure environment variables**

```bash
cp .env.example .env
```

Edit the `.env` file with your configuration values.

**5. Start the server**

```bash
rails server
```

---

## Seeds and Test Data

The project includes a robust seed system that creates environment-specific data.

### Default Users (Development)

**Admins:**

- `admin@guardian.com` / `Admin123456`
- `admin2@test.com` / `User123456`
- `admin3@test.com` / `User123456`

**Regular Users:**

- `demo@guardian.com` / `Demo123456`
- `user1@test.com` through `user5@test.com` / `User123456`

### Seed Commands

```bash
# Run seeds (idempotent)
rails db:seed

# Recreate database with seeds
rails db:setup

# Full database reset
rails db:reset
```

For more information, see [db/seeds/README.md](db/seeds/README.md).

---

## Configuration

### Environment Variables

```env
# Database
DATABASE_URL=postgresql://username:password@localhost:5432/guardian_auth_development

# JWT Secret
SECRET_KEY_BASE=your_secret_key_here

# CORS (production)
ALLOWED_ORIGINS=https://yourapp.com,https://app.yourapp.com

# Rails Environment
RAILS_ENV=development
```

### Database Configuration

The project is configured to use PostgreSQL. See `config/database.yml` to adjust connection settings.

---

## API Documentation

### Endpoints

**GraphQL Playground (Development)**

- URL: `http://localhost:3000/graphiql`
- Interactive interface for testing queries and mutations

**GraphQL API**

- URL: `http://localhost:3000/graphql`
- Method: `POST`
- Content-Type: `application/json`

### Available Mutations

**Register User**

```graphql
mutation {
  registerUser(
    input: {
      firstName: "Joao"
      lastName: "Silva"
      email: "joao.silva@example.com"
      password: "SecureP@ss1"
      passwordConfirmation: "SecureP@ss1"
    }
  ) {
    success
    message
    user {
      id
      email
      firstName
      lastName
    }
    token
    errors {
      message
      code
      field
    }
  }
}
```

**Login**

```graphql
mutation {
  loginUser(email: "joao.silva@example.com", password: "SecureP@ss1") {
    success
    message
    user {
      id
      email
      firstName
      lastName
    }
    token
    errors {
      message
      code
      field
    }
  }
}
```

### Available Queries

**Current User**

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

---

## Authentication

### JWT Token

After login, include the returned token in the `Authorization` header of subsequent requests:

```http
Authorization: Bearer <your_jwt_token>
```

### Validation Rules

- **Email**: Must be a valid format and unique
- **Password**: Minimum 8 characters; must contain at least one uppercase letter, one lowercase letter, one digit, and one special character (`@$!%*?&`)
- **Name**: Required, between 2 and 50 characters

---

## Testing

```bash
# Run all tests
bundle exec rspec

# Run a specific test file
bundle exec rspec spec/models/user_spec.rb

# Run tests with coverage report
COVERAGE=true bundle exec rspec
```

---

## Deployment

### Using Kamal

```bash
# Initial setup
bundle exec kamal setup

# Deploy to production
bundle exec kamal deploy

# Check deployment status
bundle exec kamal details
```

### Production Environment Variables

```bash
bundle exec kamal env set --production
```

---

## Project Structure

```
app/
├── controllers/         # Rails controllers
├── graphql/             # GraphQL schema and types
│   ├── mutations/       # GraphQL mutations
│   ├── resolvers/       # GraphQL resolvers
│   └── types/           # GraphQL types
├── models/              # ActiveRecord models
├── policies/            # Authorization policies (Pundit)
└── services/            # Business logic services
```

---

## Development

### Linting

```bash
# Check style violations
bundle exec rubocop

# Auto-fix violations
bundle exec rubocop -a
```

### Security

```bash
# Static analysis with Brakeman
bundle exec brakeman

# Dependency vulnerability check
bundle exec bundler-audit check

# Update vulnerability database
bundle exec bundler-audit update
```

Additional security documentation:

- [Branch Protection Guide](.github/BRANCH_PROTECTION.md)
- [Security Guide](.github/SECURITY_GUIDE.md)

### CI/CD Pipeline

All pull requests run the following automated checks:

- **RuboCop** — Code style and linting
- **Brakeman** — Static security analysis
- **Bundler Audit** — Dependency vulnerability scanning
- **RSpec** — Full test suite
- **CodeQL** — GitHub security analysis

All checks must pass before merging into `main` or `develop`.

---

## Contributing

Contributions are welcome. Please follow the guidelines below.

### Workflow

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Follow the code conventions described in [AGENTS.md](AGENTS.md)
4. Write tests for new functionality
5. Run all validations before committing:
   ```bash
   bundle exec rubocop
   bundle exec brakeman
   bundle exec bundler-audit check
   bundle exec rspec
   ```
6. Commit using [Conventional Commits](https://www.conventionalcommits.org/):
   ```bash
   git commit -m "feat(auth): add two-factor authentication"
   ```
7. Push and open a Pull Request following the provided template

### Commit Convention

| Prefix             | Purpose                                  |
| ------------------ | ---------------------------------------- |
| `feat(scope):`     | New feature                              |
| `fix(scope):`      | Bug fix                                  |
| `docs(scope):`     | Documentation changes only               |
| `refactor(scope):` | Code refactoring without behavior change |
| `test(scope):`     | Adding or updating tests                 |
| `chore(scope):`    | Maintenance tasks                        |

### Code Review Requirements

All pull requests must:

- Receive approval from at least 1 reviewer (`develop`) or 2 reviewers (`main`)
- Pass all CI/CD checks
- Resolve all open review conversations
- Be up to date with the target branch

### Branch Protection Summary

| Branch    | Required Approvals | Signed Commits |
| --------- | ------------------ | -------------- |
| `main`    | 2                  | Yes            |
| `develop` | 1                  | No             |

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## Support

If you encounter any issues or have questions:

1. Check the existing documentation
2. Open an issue on GitHub
3. Contact the development team
