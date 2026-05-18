module Mutations
  class VerifyEmail < BaseMutation
    description 'Verifica o endereço de email usando o token enviado por email'

    argument :token, String, required: true, description: 'Token de verificação recebido por email'

    field :success, Boolean, null: false
    field :message, String, null: true
    field :user, Types::UserType, null: true
    field :errors, [Types::UserErrorType], null: false

    def resolve(token:)
      token = token.to_s.strip
      return invalid_token_response if token.blank?

      digest = Digest::SHA256.hexdigest(token)
      user = User.find_by(email_verification_digest: digest)
      return invalid_token_response unless user

      case user.verify_email!(token)
      when :ok
        AuditLogger.log(
          action: 'email_verified',
          resource: 'User',
          resource_id: user.id,
          user: user,
          metadata: { ip_address: context[:remote_ip] },
          result: 'success'
        )
        { success: true, message: 'Email verificado com sucesso.', user: user, errors: [] }
      when :already_verified
        { success: true, message: 'Email já estava verificado.', user: user, errors: [] }
      when :expired
        { success: false, message: 'Token expirado. Solicite um novo email de verificação.',
          user: nil, errors: auth_error(Errors::ErrorCodes::TOKEN_EXPIRED, 'Token expirado') }
      else
        invalid_token_response
      end
    rescue StandardError => e
      Rails.logger.error "VerifyEmail mutation error: #{e.message}"
      { success: false, message: 'Falha na verificação. Tente novamente.',
        user: nil, errors: auth_error(Errors::ErrorCodes::INTERNAL_ERROR, 'Falha na verificação') }
    end

    private

    def invalid_token_response
      { success: false, message: 'Token inválido ou já utilizado.',
        user: nil, errors: auth_error(Errors::ErrorCodes::INVALID_INPUT, 'Token inválido') }
    end
  end
end
