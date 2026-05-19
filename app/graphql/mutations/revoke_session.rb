module Mutations
  class RevokeSession < BaseMutation
    description 'Revoga uma sessão específica. Usuários revogam as próprias; admins podem revogar qualquer uma.'

    argument :session_id, ID, required: true, description: 'ID da sessão a revogar'

    field :success, Boolean, null: false, description: 'Se a operação foi bem-sucedida'
    field :message, String, null: false, description: 'Mensagem de resultado'
    field :errors, [Types::UserErrorType], null: false, description: 'Lista de erros'

    def resolve(session_id:)
      authenticate!

      session = Session.find_by(id: session_id)

      unless session
        return {
          success: false,
          message: 'Sessão não encontrada',
          errors: auth_error(Errors::ErrorCodes::RESOURCE_NOT_FOUND, "Session #{session_id} not found")
        }
      end

      unless current_user.admin? || session.user_id == current_user.id
        return {
          success: false,
          message: 'Você não tem permissão para revogar esta sessão',
          errors: auth_error(Errors::ErrorCodes::INSUFFICIENT_PERMISSIONS, 'Cannot revoke another user\'s session')
        }
      end

      if session.revoked?
        return {
          success: true,
          message: 'A sessão já estava revogada',
          errors: []
        }
      end

      reason = current_user.admin? && session.user_id != current_user.id ? 'admin_revoked' : 'user_revoked'
      session.revoke!(reason: reason)

      AuditLogger.log(
        action: 'session_revoked',
        resource: 'Session',
        resource_id: session.id.to_s,
        user: current_user,
        metadata: AuditLogger.build_metadata(
          ip: context[:remote_ip],
          user_agent: context[:user_agent],
          target_user_id: session.user_id,
          reason: reason
        ),
        result: 'success'
      )

      {
        success: true,
        message: 'Sessão revogada com sucesso',
        errors: []
      }
    rescue StandardError => e
      Rails.logger.error "RevokeSession error: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
      {
        success: false,
        message: 'Ocorreu um erro ao revogar a sessão',
        errors: auth_error(Errors::ErrorCodes::INTERNAL_ERROR, 'An internal error occurred while revoking the session')
      }
    end
  end
end
