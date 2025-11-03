module Analyzers
  class QueryComplexityAnalyzer < GraphQL::Analysis::AST::Analyzer
    def initialize(query)
      super
      @complexity = 0
      @max_complexity = query.schema.max_complexity || 200
      @query = query
    end

    def on_enter_field(node, parent, visitor)
      field_definition = visitor.field_definition
      return if field_definition.nil?

      # Calcular complexidade baseada no tipo de campo
      field_complexity = calculate_field_complexity(node, field_definition)
      @complexity += field_complexity

      # Log campos complexos
      return unless field_complexity > 10

      Rails.logger.info({
        event: 'complex_graphql_field',
        field: field_definition.graphql_name,
        complexity: field_complexity,
        total_complexity: @complexity,
        query: @query.query_string&.gsub(/\s+/, ' ')&.strip
      }.to_json)
    end

    def result
      if @complexity > @max_complexity
        GraphQL::AnalysisError.new(
          "Query complexity #{@complexity} exceeds maximum allowed complexity #{@max_complexity}"
        )
      else
        # Log complexity metrics
        Rails.logger.info({
          event: 'graphql_query_complexity',
          complexity: @complexity,
          max_complexity: @max_complexity,
          query: @query.query_string&.gsub(/\s+/, ' ')&.strip
        }.to_json)

        nil
      end
    end

    private

    def calculate_field_complexity(node, field_definition)
      # Complexidade base
      complexity = 1

      # Conexões são mais complexas
      if field_definition.type.list?
        complexity += 2

        # Se tem argumentos de paginação, adicionar complexidade baseada no limite
        if node.arguments.any?
          first_arg = node.arguments.find { |arg| arg.name == 'first' }
          last_arg = node.arguments.find { |arg| arg.name == 'last' }

          complexity += if first_arg&.value
                          (first_arg.value / 10.0).ceil
                        elsif last_arg&.value
                          (last_arg.value / 10.0).ceil
                        else
                          5 # Complexidade padrão para listas sem limite
                        end
        end
      end

      # Campos aninhados aumentam complexidade
      if node.selections.any?
        complexity += node.selections.length * 0.1
      end

      # Campos específicos com alta complexidade
      case field_definition.graphql_name
      when 'auditLogs'
        complexity += 5
      when 'users'
        complexity += 3
      end

      complexity.to_i
    end
  end
end
