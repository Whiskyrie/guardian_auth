module Mutations
  class RegisterUser < BaseMutation
    argument :email, String, required: true
    argument :password, String, required: true
    argument :first_name, String, required: true
    argument :last_name, String, required: true
    
    field :auth_payload, Types::AuthPayloadType, null: false
    
    def resolve(email:, password:, first_name:, last_name:)
      user = User.new(
        email: email,
        password: password,
        first_name: first_name,
        last_name: last_name
      )
      
      if user.save
        token = JwtService.encode(user_id: user.id)
        {
          auth_payload: {
            token: token,
            user: user,
            errors: []
          }
        }
      else
        formatted_errors = format_user_errors(user.errors)
        {
          auth_payload: {
            token: nil,
            user: nil,
            errors: formatted_errors
          }
        }
      end
    end

    private

    def format_user_errors(errors)
      errors.map do |attribute, message|
        error_code = generate_error_code(attribute, message)
        {
          field: attribute.to_s,
          message: message,
          code: error_code
        }
      end
    end

    def generate_error_code(attribute, message)
      case attribute
      when :email
        case message
        when /can't be blank/i then 'EMAIL_REQUIRED'
        when /has already been taken/i then 'EMAIL_ALREADY_TAKEN'
        when /is invalid/i then 'EMAIL_INVALID'
        else 'EMAIL_ERROR'
        end
      when :password
        case message
        when /can't be blank/i then 'PASSWORD_REQUIRED'
        when /too short/i then 'PASSWORD_TOO_SHORT'
        else 'PASSWORD_ERROR'
        end
      when :first_name
        case message
        when /can't be blank/i then 'FIRST_NAME_REQUIRED'
        else 'FIRST_NAME_ERROR'
        end
      when :last_name
        case message
        when /can't be blank/i then 'LAST_NAME_REQUIRED'
        else 'LAST_NAME_ERROR'
        end
      else
        'VALIDATION_ERROR'
      end
    end
  end
end