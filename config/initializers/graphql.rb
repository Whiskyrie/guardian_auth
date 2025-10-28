# frozen_string_literal: true

# Configurações específicas do GraphQL
Rails.application.configure do
  # Configurações de performance em produção
  if Rails.env.production?
    # Configurações específicas de produção podem ser adicionadas aqui
  end
end

# Configurar métricas personalizadas se disponível
if defined?(Prometheus)
  # Registrar métricas Prometheus para GraphQL
  GRAPHQL_QUERY_DURATION = Prometheus::Histogram.new(
    :graphql_query_duration_seconds,
    docstring: 'GraphQL query execution time',
    labels: [:operation_name, :operation_type]
  )

  GRAPHQL_QUERY_COMPLEXITY = Prometheus::Histogram.new(
    :graphql_query_complexity,
    docstring: 'GraphQL query complexity',
    labels: [:operation_name],
    buckets: [1, 5, 10, 25, 50, 100, 200, 300]
  )

  GRAPHQL_FIELD_DURATION = Prometheus::Histogram.new(
    :graphql_field_duration_seconds,
    docstring: 'GraphQL field execution time',
    labels: [:field_name, :type_name]
  )

  # Registrar métricas
  Prometheus::Client.registry.register(GRAPHQL_QUERY_DURATION)
  Prometheus::Client.registry.register(GRAPHQL_QUERY_COMPLEXITY)
  Prometheus::Client.registry.register(GRAPHQL_FIELD_DURATION)
end
