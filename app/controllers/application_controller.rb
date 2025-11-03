class ApplicationController < ActionController::API
  include Pundit::Authorization

  # Set up request context for audit logging
  before_action :set_request_context

  # Handle Pundit authorization errors
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def set_request_context
    # Store request context in thread for audit logging
    Thread.current[:request_context] = {
      request_id: request.uuid,
      remote_ip: request.remote_ip,
      user_agent: request.user_agent,
      path: request.path,
      method: request.method
    }

    # Store current user in thread for audit logging
    Thread.current[:current_user] = current_user if respond_to?(:current_user) && current_user
  end

  def user_not_authorized
    # Log authorization failure
    if current_user
      AuditLogger.log_access_denied(
        user: current_user,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        resource: controller_name,
        action: action_name,
        reason: 'insufficient_permissions'
      )
    end

    render json: { error: 'You are not authorized to perform this action' }, status: :forbidden
  end
end
