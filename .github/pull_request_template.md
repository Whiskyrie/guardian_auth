## Descrição

<!-- Descreva as mudanças deste PR de forma clara e concisa -->

## Issue Relacionada

<!-- Referencie a issue relacionada: Closes ou Fixes  -->

## Tipo de Mudança

<!-- Marque com 'x' o tipo de mudança -->

- [ ] Bug fix (correção de bug)
- [ ] Nova funcionalidade (feature)
- [ ] Breaking change (mudança que quebra compatibilidade)
- [ ] Documentação
- [ ] Refatoração
- [ ] Melhoria de performance
- [ ] Adição/atualização de testes
- [ ] Configuração/DevOps

## Screenshots (se aplicável)

<!-- Adicione screenshots se houver mudanças visuais -->

## Checklist

### Código
- [ ] Código segue as convenções Rails (snake_case, etc)
- [ ] Mutations GraphQL retornam estrutura consistente: `{ token, user, errors }`
- [ ] Lógica de negócio complexa extraída para services
- [ ] Não há queries N+1
- [ ] Erros tratados adequadamente com logging
- [ ] Tokens JWT validados e blacklist verificada
- [ ] Rate limiting considerado para endpoints sensíveis

### Testes
- [ ] Testes passam: `rails test`
- [ ] Novos testes adicionados para novas funcionalidades
- [ ] Cobertura de testes mantida ou melhorada

### Qualidade
- [ ] RuboCop passa: `bundle exec rubocop`
- [ ] Brakeman passa: `bundle exec brakeman`
- [ ] Sem vulnerabilidades: `bundle exec bundler-audit`

### Database
- [ ] Migrações funcionam corretamente (up e down)
- [ ] Seeds funcionam: `rails db:reset`
- [ ] Migrações são reversíveis

### GraphQL
- [ ] GraphQL Playground testado manualmente
- [ ] Schema GraphQL atualizado se necessário
- [ ] Documentação GraphQL atualizada

### Documentação
- [ ] README atualizado (se necessário)
- [ ] AGENTS.md atualizado (se necessário)
- [ ] Comentários úteis adicionados (não óbvios)
- [ ] CHANGELOG atualizado (se aplicável)

### Git
- [ ] Commit segue padrão convencional
- [ ] Sem commits de merge desnecessários
- [ ] Branch atualizada com base (`main` ou `develop`)

## Notas Adicionais

<!-- Adicione quaisquer notas ou contexto adicional sobre o PR -->

## Considerações de Segurança

<!-- Descreva quaisquer implicações de segurança dessas mudanças -->

- [ ] Sem dados sensíveis expostos
- [ ] Inputs validados e sanitizados
- [ ] Autorização verificada com Pundit
- [ ] Logs de segurança adicionados (se necessário)

---

**Revisor**: Por favor, verifique especialmente:
<!-- Indique áreas específicas que precisam de atenção especial na revisão -->
