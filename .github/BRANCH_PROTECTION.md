# Configuração de Proteção de Branches - Guardian Auth

Este documento descreve como configurar as proteções de branch no GitHub para o projeto Guardian Auth.

## Branches Protegidas

### Branch `main` (Produção)

**Configurações recomendadas no GitHub:**

1. **Proteção básica:**
   - Require a pull request before merging
   - Require approvals: **2**
   - Dismiss stale pull request approvals when new commits are pushed
   - Require review from Code Owners

2. **Status checks (CI/CD):**
   - Require status checks to pass before merging
   - Require branches to be up to date before merging
   - **Checks obrigatórios:**
     - `RuboCop (Linting)`
     - `Brakeman (Security)`
     - `Bundler Audit (Dependencies)`
     - `Tests`
     - `Build Check`

3. **Proteção adicional:**
   - Require conversation resolution before merging
   - Require signed commits (recomendado)
   - Require linear history
   - Include administrators (aplicar regras para admins também)
   - Restrict who can push to matching branches
     - Apenas: Maintainers e Admins

4. **Regras adicionais:**
   - Do not allow bypassing the above settings
   - Allow force pushes: **Disabled**
   - Allow deletions: **Disabled**

---

### Branch `develop` (Desenvolvimento)

**Configurações recomendadas no GitHub:**

1. **Proteção básica:**
   - Require a pull request before merging
   - Require approvals: **1**
   - Dismiss stale pull request approvals: **Optional**

2. **Status checks:**
   - Require status checks to pass before merging
   - Require branches to be up to date: **Optional** (mais flexível)
   - **Checks obrigatórios:**
     - `RuboCop (Linting)`
     - `Tests`

3. **Proteção adicional:**
   - Require conversation resolution before merging
   - Require linear history: **Optional**
   - Include administrators: **Disabled** (mais flexível para desenvolvimento)

4. **Regras adicionais:**
   - Allow force pushes: **Disabled**
   - Allow deletions: **Disabled**

---

## 🔧 Como Configurar no GitHub

### Via Interface Web

1. Vá para: `Settings` → `Branches` → `Branch protection rules`
2. Clique em `Add branch protection rule`
3. Em **Branch name pattern**, digite: `main` (ou `develop`)
4. Configure as opções conforme descrito acima
5. Clique em `Create` ou `Save changes`

### Via GitHub CLI (gh)

```bash
# Instalar GitHub CLI se necessário
# https://cli.github.com/

# Proteção para main
gh api repos/Whiskyrie/guardian_auth/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["RuboCop (Linting)","Brakeman (Security)","Bundler Audit (Dependencies)","Tests","Build Check"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"dismissal_restrictions":{},"dismiss_stale_reviews":true,"require_code_owner_reviews":true,"required_approving_review_count":2}' \
  --field restrictions=null \
  --field required_linear_history=true \
  --field allow_force_pushes=false \
  --field allow_deletions=false

# Proteção para develop
gh api repos/Whiskyrie/guardian_auth/branches/develop/protection \
  --method PUT \
  --field required_status_checks='{"strict":false,"contexts":["RuboCop (Linting)","Tests"]}' \
  --field enforce_admins=false \
  --field required_pull_request_reviews='{"dismissal_restrictions":{},"dismiss_stale_reviews":false,"require_code_owner_reviews":false,"required_approving_review_count":1}' \
  --field restrictions=null \
  --field allow_force_pushes=false \
  --field allow_deletions=false
```

---

## CODEOWNERS

Crie o arquivo `.github/CODEOWNERS` para definir revisores automáticos:

```
# Arquivo: .github/CODEOWNERS

# Global owners (fallback)
* @Whiskyrie

# GraphQL e mutations (crítico para segurança)
/app/graphql/ @Whiskyrie
/app/graphql/mutations/ @Whiskyrie

# Serviços de autenticação e segurança
/app/services/jwt_service.rb @Whiskyrie
/app/services/audit_logger.rb @Whiskyrie
/app/services/security_logger.rb @Whiskyrie

# Middleware de segurança
/app/middleware/ @Whiskyrie

# Policies de autorização
/app/policies/ @Whiskyrie

# Configurações sensíveis
/config/initializers/rack_attack.rb @Whiskyrie
/config/initializers/rate_limiting.rb @Whiskyrie

# CI/CD e deploy
/.github/workflows/ @Whiskyrie
/config/deploy.yml @Whiskyrie

# Migrações de banco
/db/migrate/ @Whiskyrie
```

---

## Rulesets (Nova Feature do GitHub)

**Rulesets** são a nova forma de proteger branches no GitHub (mais flexível que Branch Protection Rules).

### Criar Ruleset para `main`:

1. Vá para: `Settings` → `Rules` → `Rulesets`
2. Clique em `New ruleset` → `New branch ruleset`
3. Configure:
   - **Name**: `Production Protection (main)`
   - **Enforcement status**: Active
   - **Target branches**: `Include by pattern` → `main`
   
4. **Rules**:
   - Restrict creations
   - Restrict updates
   - Restrict deletions
   - Require a pull request before merging
     - Required approvals: 2
     - Dismiss stale reviews: Yes
     - Require review from code owners: Yes
   - Require status checks to pass
     - Status checks: RuboCop, Brakeman, Tests
     - Require branches to be up to date: Yes
   - Require conversation resolution
   - Require signed commits
   - Block force pushes

---

## Métricas e Monitoramento

### Configurar GitHub Insights

1. `Insights` → `Community` → Verificar se tem:
   - Description
   - README
   - Code of conduct
   - Contributing guidelines
   - License

2. `Insights` → `Security` → Habilitar:
   - Dependabot alerts
   - Dependabot security updates
   - Code scanning (CodeQL)
   - Secret scanning

### Habilitar Dependabot

Já criado em `.github/dependabot.yml`

---

## Configurações de Segurança Adicionais

### 1. Secret Scanning

```bash
# Habilitar via Settings → Security → Code security and analysis
# → Enable Secret scanning
# → Enable Push protection
```

### 2. Code Scanning (CodeQL)

Criar workflow adicional `.github/workflows/codeql.yml`:

```yaml
name: "CodeQL"

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]
  schedule:
    - cron: '0 6 * * 1'  # Segunda-feira às 6h

jobs:
  analyze:
    name: Analyze
    runs-on: ubuntu-latest
    permissions:
      actions: read
      contents: read
      security-events: write

    strategy:
      fail-fast: false
      matrix:
        language: [ 'ruby' ]

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Initialize CodeQL
      uses: github/codeql-action/init@v3
      with:
        languages: ${{ matrix.language }}

    - name: Autobuild
      uses: github/codeql-action/autobuild@v3

    - name: Perform CodeQL Analysis
      uses: github/codeql-action/analyze@v3
```

---

## Checklist de Configuração

- [ ] Branch `main` protegida com 2 aprovações
- [ ] Branch `develop` protegida com 1 aprovação
- [ ] CI/CD (GitHub Actions) configurado
- [ ] Dependabot habilitado
- [ ] CODEOWNERS criado
- [ ] Secret scanning habilitado
- [ ] Code scanning (CodeQL) habilitado
- [ ] Require signed commits (opcional mas recomendado)
- [ ] Linear history habilitado
- [ ] Force push bloqueado
- [ ] Administrators incluídos nas regras (para `main`)

---

## Referências

- [GitHub Branch Protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [GitHub Rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)
- [CODEOWNERS](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
- [Dependabot](https://docs.github.com/en/code-security/dependabot)
- [CodeQL](https://codeql.github.com/)

---

**Última atualização**: 2 de novembro de 2025
