module Mutations
  class ResendVerificationEmail < BaseMutation
    include RateLimitMutation

    description 'Reenvia o email de verificação para o usuário autenticado'
    rate_limited 'resendVerificationEmail'

    field :success, Boolean, null: false
    field :message, String, null: true
    field :errors, [Types::UserErrorType], null: false

    def resolve
      authenticate!
      user = current_user

      if user.email_verified?
        return { success: true, message: 'Email já está verificado.', errors: [] }
      end

      if user.verification_cooldown_active?
        return {
          success: false,
          message: 'Aguarde 15 minutos antes de solicitar um novo email.',
          errors: auth_error(Errors::ErrorCodes::RATE_LIMIT_EXCEEDED, 'Aguarde antes de solicitar novamente')
        }
      end

      SendVerificationEmailJob.perform_later(user.id)

      { success: true, message: 'Email de verificação enviado. Verifique sua caixa de entrada.', errors: [] }
    rescue StandardError => e
      Rails.logger.error "ResendVerificationEmail mutation error: #{e.message}"
      { success: false, message: 'Falha ao enviar email. Tente novamente.',
        errors: auth_error(Errors::ErrorCodes::INTERNAL_ERROR, 'Falha ao enviar email') }
    end
  end
end
