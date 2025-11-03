module Errors
  class BaseError < GraphQL::ExecutionError
    attr_reader :error_code, :details

    def initialize(message = nil, error_code: nil, details: {}, locale: nil)
      @error_code = error_code || self.class.default_error_code
      @details = details
      @locale = locale || I18n.locale

      final_message = message || localized_message || default_message
      super(final_message)
    end

    def to_h
      super.merge(
        'extensions' => {
          'code' => @error_code,
          'details' => @details,
          'locale' => @locale
        }.compact
      )
    end

    def self.default_error_code
      ErrorCodes::INTERNAL_ERROR
    end

    def localized_message(locale = nil)
      current_locale = locale || @locale || I18n.locale
      I18n.t(i18n_key, default: nil, locale: current_locale)
    end

    protected

    def i18n_key
      'graphql.errors.server.internal_error'
    end

    public

    def default_message
      'An error occurred'
    end
  end

  class AuthenticationError < BaseError
    def self.default_error_code
      ErrorCodes::AUTHENTICATION_REQUIRED
    end

    protected

    def i18n_key
      'graphql.errors.authentication.required'
    end

    private

    def default_message
      'Authentication required'
    end
  end

  class InvalidTokenError < AuthenticationError
    def self.default_error_code
      ErrorCodes::INVALID_TOKEN
    end

    protected

    def i18n_key
      'graphql.errors.authentication.invalid_token'
    end

    private

    def default_message
      'Invalid or malformed token'
    end
  end

  class TokenExpiredError < AuthenticationError
    def self.default_error_code
      ErrorCodes::TOKEN_EXPIRED
    end

    protected

    def i18n_key
      'graphql.errors.authentication.token_expired'
    end

    private

    def default_message
      'Token has expired'
    end
  end

  class InvalidCredentialsError < AuthenticationError
    def self.default_error_code
      ErrorCodes::INVALID_CREDENTIALS
    end

    protected

    def i18n_key
      'graphql.errors.authentication.invalid_credentials'
    end

    private

    def default_message
      'Invalid email or password'
    end
  end

  class AuthorizationError < BaseError
    def self.default_error_code
      ErrorCodes::UNAUTHORIZED
    end

    protected

    def i18n_key
      'graphql.errors.authorization.unauthorized'
    end

    private

    def default_message
      'You are not authorized to perform this action'
    end
  end

  class InsufficientPermissionsError < AuthorizationError
    def self.default_error_code
      ErrorCodes::INSUFFICIENT_PERMISSIONS
    end

    protected

    def i18n_key
      'graphql.errors.authorization.insufficient_permissions'
    end

    private

    def default_message
      'Insufficient permissions to access this resource'
    end
  end

  class ValidationError < BaseError
    attr_reader :field_errors

    def initialize(message = nil, field_errors: [], **)
      @field_errors = field_errors
      super(message, error_code: ErrorCodes::VALIDATION_FAILED, **)
    end

    def to_h
      result = super
      result['extensions']['field_errors'] = @field_errors if @field_errors.any?
      result
    end

    protected

    def i18n_key
      'graphql.errors.validation.failed'
    end

    private

    def default_message
      'Validation failed'
    end
  end

  class ResourceNotFoundError < BaseError
    def self.default_error_code
      ErrorCodes::RESOURCE_NOT_FOUND
    end

    protected

    def i18n_key
      'graphql.errors.resource.not_found'
    end

    private

    def default_message
      'Resource not found'
    end
  end

  class ResourceAlreadyExistsError < BaseError
    def self.default_error_code
      ErrorCodes::RESOURCE_ALREADY_EXISTS
    end

    protected

    def i18n_key
      'graphql.errors.resource.already_exists'
    end

    private

    def default_message
      'Resource already exists'
    end
  end

  class RateLimitExceededError < BaseError
    def self.default_error_code
      ErrorCodes::RATE_LIMIT_EXCEEDED
    end

    protected

    def i18n_key
      'graphql.errors.rate_limit.exceeded'
    end

    private

    def default_message
      'Rate limit exceeded. Please try again later'
    end
  end

  class BusinessRuleViolationError < BaseError
    def self.default_error_code
      ErrorCodes::BUSINESS_RULE_VIOLATION
    end

    protected

    def i18n_key
      'graphql.errors.business.rule_violation'
    end

    private

    def default_message
      'Business rule violation'
    end
  end

  class ProfileUpdateTooFrequentError < BusinessRuleViolationError
    def self.default_error_code
      ErrorCodes::PROFILE_UPDATE_TOO_FREQUENT
    end

    protected

    def i18n_key
      'graphql.errors.business.profile_update_too_frequent'
    end

    private

    def default_message
      'Profile can only be updated once every 7 days'
    end
  end

  class ServiceUnavailableError < BaseError
    def self.default_error_code
      ErrorCodes::SERVICE_UNAVAILABLE
    end

    protected

    def i18n_key
      'graphql.errors.server.service_unavailable'
    end

    private

    def default_message
      'Service temporarily unavailable'
    end
  end

  class TimeoutError < BaseError
    def self.default_error_code
      ErrorCodes::TIMEOUT
    end

    protected

    def i18n_key
      'graphql.errors.server.timeout'
    end

    private

    def default_message
      'Request timed out'
    end
  end

  class DatabaseError < BaseError
    def self.default_error_code
      ErrorCodes::DATABASE_ERROR
    end

    protected

    def i18n_key
      'graphql.errors.server.database'
    end

    private

    def default_message
      'Database error occurred'
    end
  end
end
