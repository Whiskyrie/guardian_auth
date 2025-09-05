# frozen_string_literal: true

require_relative 'errors/base_error'
require_relative 'errors/error_codes'
require_relative 'middleware/logging_middleware'

class GuardianAuthSchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)

  # For batch-loading (see https://graphql-ruby.org/dataloader/overview.html)
  use GraphQL::Dataloader

  # Configurar limites de paginação para economizar recursos
  default_max_page_size 100  # Máximo 100 por página
  default_page_size 25       # Padrão 25 por página

  # Configurar limites de segurança
  max_depth 15
  max_complexity 300

  # Add query analyzers for security
  query_analyzer(GraphQL::Analysis::AST::MaxQueryDepth)
  query_analyzer(GraphQL::Analysis::AST::MaxQueryComplexity)

  # Configure error handling with detailed logging and user-friendly messages
  use GraphQL::Backtrace

  # Add logging tracer for GraphQL operations (usando a nova sintaxe)
  trace_with GraphQL::LoggingTracer

  # Rescue from specific exceptions
  rescue_from(ActiveRecord::RecordNotFound) do |err, obj, args, ctx, field|
    GraphqlLogger.log_error(
      error: err,
      query: ctx.query.query_string,
      context: ctx
    )
    raise Errors::ResourceNotFoundError.new(
      "#{field.type.unwrap.graphql_name} not found",
      details: { id: args[:id] }
    )
  end

  rescue_from(ActiveRecord::RecordInvalid) do |err, obj, args, ctx, field|
    field_errors = err.record.errors.map do |error|
      {
        field: error.attribute.to_s,
        message: error.message,
        code: Errors::ErrorCodes::INVALID_INPUT
      }
    end

    GraphqlLogger.log_error(
      error: err,
      query: ctx.query.query_string,
      context: ctx,
      field_errors: field_errors
    )

    raise Errors::ValidationError.new(
      'Validation failed',
      field_errors: field_errors
    )
  end

  rescue_from(Pundit::NotAuthorizedError) do |err, obj, args, ctx, field|
    GraphqlLogger.log_authorization_failure(
      user: ctx[:current_user],
      action: field.graphql_name,
      resource: obj || field,
      context: ctx
    )
    raise Errors::AuthorizationError.new(
      'You are not authorized to perform this action',
      details: { field: field.graphql_name }
    )
  end

  rescue_from(JWT::DecodeError, JWT::ExpiredSignature, JWT::VerificationError) do |err, obj, args, ctx, field|
    GraphqlLogger.log_error(
      error: err,
      query: ctx.query.query_string,
      context: ctx
    )
    
    case err
    when JWT::ExpiredSignature
      raise Errors::TokenExpiredError.new
    when JWT::VerificationError
      raise Errors::InvalidTokenError.new
    else
      raise Errors::InvalidTokenError.new('Invalid token format')
    end
  end

  rescue_from(Rack::Attack::Throttle) do |err, obj, args, ctx, field|
    GraphqlLogger.log_rate_limit(
      identifier: ctx[:request]&.remote_ip || 'unknown',
      limit: 'unknown',
      current_count: 'unknown',
      context: ctx
    )
    raise Errors::RateLimitExceededError.new(
      'Rate limit exceeded. Please try again later.'
    )
  end

  rescue_from(StandardError) do |err, obj, args, ctx, field|
    # Log all unhandled errors
    GraphqlLogger.log_error(
      error: err,
      query: ctx.query.query_string,
      context: ctx,
      field: field&.graphql_name
    )

    # In development, re-raise to see full backtrace
    if Rails.env.development?
      raise err
    end

    # In production, return generic error
    raise Errors::BaseError.new(
      'An unexpected error occurred',
      error_code: Errors::ErrorCodes::INTERNAL_ERROR
    )
  end

  # GraphQL-Ruby calls this when something goes wrong while running a query:
  def self.type_error(err, context)
    GraphqlLogger.log_error(
      error: err,
      query: context.query.query_string,
      context: context
    )

    case err
    when GraphQL::InvalidNullError
      # Log but don't replace the error
      Rails.logger.error "Null error: #{err.message}"
      nil
    when GraphQL::StringEncodingError
      Rails.logger.warn "String encoding error: #{err.message}"
      nil
    when GraphQL::IntegerEncodingError, GraphQL::IntegerDecodingError
      Rails.logger.warn "Integer encoding error: #{err.message}"
      err.respond_to?(:integer_value) ? err.integer_value : nil
    else
      super
    end
  end

  # Union and Interface Resolution
  def self.resolve_type(_abstract_type, _obj, _ctx)
    # Este projeto não usa Unions ou Interfaces atualmente
    # Se precisar no futuro, implementar a lógica adequada aqui
    nil
  end

  # Limit the size of incoming queries:
  max_query_string_tokens(5000)

  # Stop validating when it encounters this many errors:
  validate_max_errors(100)

  # Relay-style Object Identification:

  # Return a string UUID for `object`
  def self.id_from_object(object, _type_definition, _query_ctx)
    # For example, use Rails' GlobalID library (https://github.com/rails/globalid):
    object.to_gid_param
  end

  # Given a string UUID, find the object
  def self.object_from_id(global_id, _query_ctx)
    # For example, use Rails' GlobalID library (https://github.com/rails/globalid):
    GlobalID.find(global_id)
  end
end
