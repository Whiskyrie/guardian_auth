class GraphqlController < ApplicationController
  include Authentication
  include Authorization

  # If accessing from outside this domain, nullify the session
  # This allows for outside API access while preventing CSRF attacks,
  # but you'll have to authenticate your user separately
  # protect_from_forgery with: :null_session

  def execute
    variables = prepare_variables(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]

    # Extract token for context (better reliability)
    token = extract_token_from_header
    current_user = current_user_from_token

    Rails.logger.info "GraphQL Context - Token: #{token ? 'present' : 'nil'}, User: #{current_user ? 'present' : 'nil'}"

    context = {
      current_user: current_user,
      current_token: token,
      request: request,
      pundit: pundit_user,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    }

    # Start timing
    start_time = Time.current

    result = GuardianAuthSchema.execute(
      query,
      variables: variables,
      context: context,
      operation_name: operation_name
    )

    # Calculate duration
    duration = (Time.current - start_time) * 1000 # Convert to milliseconds

    # Log the GraphQL query
    GraphqlLogger.log_query(
      query: query,
      variables: variables,
      operation_name: operation_name,
      context: context,
      duration: duration,
      result: result
    )

    # Add rate limit headers if present in context
    if context[:rate_limit_headers]
      context[:rate_limit_headers].each do |header, value|
        response.headers[header] = value
      end
    end

    render json: result
  rescue StandardError => e
    # Log the error
    GraphqlLogger.log_error(
      error: e,
      query: query,
      context: context || {},
      variables: variables,
      operation_name: operation_name
    )

    raise e unless Rails.env.development?

    handle_error_in_development(e)
  end

  private

  # Handle variables in form data, JSON body, or a blank value
  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  def handle_error_in_development(e)
    logger.error e.message
    logger.error e.backtrace.join("\n")

    render json: { errors: [{ message: e.message, backtrace: e.backtrace }], data: {} }, status: 500
  end
end
