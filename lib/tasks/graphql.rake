namespace :graphql do
  desc "Export GraphQL schema"
  task export_schema: :environment do
    puts "Exporting GraphQL schema..."

    # Schema em formato GraphQL SDL (Schema Definition Language)
    schema_definition = GuardianAuthSchema.to_definition

    # Schema em formato JSON (para introspection)
    schema_json = GuardianAuthSchema.to_json

    # Criar diretório de output se não existir
    output_dir = Rails.root.join('docs', 'graphql')
    FileUtils.mkdir_p(output_dir)

    # Salvar schema em SDL
    sdl_file = output_dir.join('schema.graphql')
    File.write(sdl_file, schema_definition)
    puts "Schema SDL saved to: #{sdl_file}"

    # Salvar schema em JSON
    json_file = output_dir.join('schema.json')
    File.write(json_file, JSON.pretty_generate(JSON.parse(schema_json)))
    puts "Schema JSON saved to: #{json_file}"

    # Gerar documentação markdown
    generate_markdown_docs(output_dir)

    puts "Schema export completed!"
  end

  desc "Validate GraphQL schema"
  task validate_schema: :environment do
    puts "Validating GraphQL schema..."

    begin
      # Força a carga do schema
      GuardianAuthSchema.to_definition
      puts "✅ Schema is valid!"
    rescue StandardError => e
      puts "❌ Schema validation failed: #{e.message}"
      exit 1
    end
  end

  desc "Generate GraphQL documentation"
  task generate_docs: :environment do
    puts "Generating GraphQL documentation..."

    output_dir = Rails.root.join('docs', 'graphql')
    FileUtils.mkdir_p(output_dir)

    generate_markdown_docs(output_dir)

    puts "Documentation generated in: #{output_dir}"
  end

  private

  def generate_markdown_docs(output_dir)
    schema = GuardianAuthSchema

    # Gerar documentação principal
    docs = []
    docs << "# Guardian Auth GraphQL API"
    docs << ""
    docs << schema.description if schema.description
    docs << ""
    docs << "## Queries"
    docs << ""

    # Documentar queries
    schema.query.fields.each do |name, field|
      docs << "### #{name}"
      docs << ""
      docs << field.description if field.description
      docs << ""
      docs << "**Type:** `#{field.type}`"
      docs << ""

      next unless field.arguments.any?

      docs << "**Arguments:**"
      docs << ""
      field.arguments.each do |arg_name, arg|
        required = arg.type.non_null? ? " (required)" : " (optional)"
        docs << "- `#{arg_name}`: `#{arg.type}`#{required}"
        docs << "  - #{arg.description}" if arg.description
      end
      docs << ""
    end

    docs << "## Mutations"
    docs << ""

    # Documentar mutations
    schema.mutation.fields.each do |name, field|
      docs << "### #{name}"
      docs << ""
      docs << field.description if field.description
      docs << ""
      docs << "**Type:** `#{field.type}`"
      docs << ""

      next unless field.arguments.any?

      docs << "**Arguments:**"
      docs << ""
      field.arguments.each do |arg_name, arg|
        required = arg.type.non_null? ? " (required)" : " (optional)"
        docs << "- `#{arg_name}`: `#{arg.type}`#{required}"
        docs << "  - #{arg.description}" if arg.description
      end
      docs << ""
    end

    # Documentar tipos
    docs << "## Types"
    docs << ""

    schema.types.each do |name, type|
      next if name.start_with?('__') # Skip introspection types
      next if type.introspection?
      next unless type.kind.object?

      docs << "### #{name}"
      docs << ""
      docs << type.description if type.description
      docs << ""

      next unless type.fields.any?

      docs << "**Fields:**"
      docs << ""
      type.fields.each do |field_name, field|
        docs << "- `#{field_name}`: `#{field.type}`"
        docs << "  - #{field.description}" if field.description
      end
      docs << ""
    end

    # Salvar documentação
    docs_file = output_dir.join('README.md')
    File.write(docs_file, docs.join("\n"))
    puts "Documentation saved to: #{docs_file}"

    # Gerar arquivo de exemplo de queries
    generate_example_queries(output_dir)
  end

  def generate_example_queries(output_dir)
    examples = []
    examples << "# Exemplos de Queries e Mutations"
    examples << ""
    examples << "## Autenticação"
    examples << ""
    examples << "### Login"
    examples << "```graphql"
    examples << "mutation {"
    examples << "  loginUser(input: {"
    examples << "    email: \"user@example.com\""
    examples << "    password: \"password123\""
    examples << "  }) {"
    examples << "    token"
    examples << "    user {"
    examples << "      id"
    examples << "      email"
    examples << "      fullName"
    examples << "    }"
    examples << "    errors"
    examples << "  }"
    examples << "}"
    examples << "```"
    examples << ""
    examples << "### Usuário Atual"
    examples << "```graphql"
    examples << "query {"
    examples << "  currentUser {"
    examples << "    id"
    examples << "    email"
    examples << "    firstName"
    examples << "    lastName"
    examples << "    role"
    examples << "    fullName"
    examples << "    displayName"
    examples << "    lastLoginAt"
    examples << "  }"
    examples << "}"
    examples << "```"
    examples << ""
    examples << "### Listar Usuários (Admin)"
    examples << "```graphql"
    examples << "query {"
    examples << "  users(first: 10) {"
    examples << "    edges {"
    examples << "      node {"
    examples << "        id"
    examples << "        email"
    examples << "        fullName"
    examples << "        role"
    examples << "        createdAt"
    examples << "      }"
    examples << "    }"
    examples << "    pageInfo {"
    examples << "      hasNextPage"
    examples << "      hasPreviousPage"
    examples << "      startCursor"
    examples << "      endCursor"
    examples << "    }"
    examples << "  }"
    examples << "}"
    examples << "```"

    examples_file = output_dir.join('examples.md')
    File.write(examples_file, examples.join("\n"))
    puts "Examples saved to: #{examples_file}"
  end
end
