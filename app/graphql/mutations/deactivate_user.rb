module Mutations
  class DeactivateUser < BaseMutation
    description 'Desativa uma conta de usuário (apenas administradores)'

    argument :user_id, ID, required: true, description: 'ID do usuário a desativar'
    argument :reason, String, required: false, description: 'Motivo da desativação (opcional)'

    field :user, Types::UserType, null: true, description: 'Usuário desativado'
    field :success, Boolean, null: false, description: 'Se a operação foi bem-sucedida'
    field :message, String, null: false, description: 'Mensagem de resultado'
    field :errors, [Types::UserErrorType], null: false, description: 'Lista de erros'

    def resolve(user_id:, reason: nil)
      authenticate!

      unless current_user&.admin?
        return {
          user: nil,
          success: false,
          message: 'Você não tem permissão para desativar contas',
          errors: auth_error(Errors::ErrorCodes::INSUFFICIENT_PERMISSIONS,
                             'Only administrators can deactivate accounts')
        }
      end

      target = User.find_by(id: user_id)

      unless target
        return {
          user: nil,
          success: false,
          message: 'Usuário não encontrado',
          errors: auth_error(Errors::ErrorCodes::RESOURCE_NOT_FOUND, "User with ID #{user_id} does not exist")
        }
      end

      if target == current_user
        return {
          user: nil,
          success: false,
          message: 'Administradores não podem desativar sua própria conta',
          errors: auth_error(Errors::ErrorCodes::BUSINESS_RULE_VIOLATION,
                             'Administrators cannot deactivate their own account')
        }
      end

      if target.deactivated?
        return {
          user: target,
          success: true,
          message: 'A conta já está desativada',
          errors: []
        }
      end

      target.deactivate!(by: current_user, reason: reason)

      AuditLogger.log(
        action: 'user_deactivation',
        resource: 'User',
        resource_id: target.id,
        user: current_user,
        metadata: AuditLogger.build_metadata(
          ip: context[:remote_ip],
          user_agent: context[:user_agent],
          reason: reason,
          target_email: target.email
        ),
        result: 'success'
      )

      {
        user: target.reload,
        success: true,
        message: 'Conta desativada com sucesso',
        errors: []
      }
    rescue StandardError => e
      Rails.logger.error "DeactivateUser error: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
      {
        user: nil,
        success: false,
        message: 'Ocorreu um erro ao desativar a conta',
        errors: auth_error(Errors::ErrorCodes::INTERNAL_ERROR, 'An internal error occurred while deactivating the account')
      }
    end
  end
end
