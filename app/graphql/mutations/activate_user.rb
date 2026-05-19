module Mutations
  class ActivateUser < BaseMutation
    description 'Reativa uma conta de usuário desativada (apenas administradores)'

    argument :user_id, ID, required: true, description: 'ID do usuário a reativar'

    field :user, Types::UserType, null: true, description: 'Usuário reativado'
    field :success, Boolean, null: false, description: 'Se a operação foi bem-sucedida'
    field :message, String, null: false, description: 'Mensagem de resultado'
    field :errors, [Types::UserErrorType], null: false, description: 'Lista de erros'

    def resolve(user_id:)
      authenticate!

      unless current_user&.admin?
        return {
          user: nil,
          success: false,
          message: 'Você não tem permissão para reativar contas',
          errors: auth_error(Errors::ErrorCodes::INSUFFICIENT_PERMISSIONS,
                             'Only administrators can activate accounts')
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

      unless target.deactivated?
        return {
          user: target,
          success: true,
          message: 'A conta já está ativa',
          errors: []
        }
      end

      target.activate!

      AuditLogger.log(
        action: 'user_activation',
        resource: 'User',
        resource_id: target.id,
        user: current_user,
        metadata: AuditLogger.build_metadata(
          ip: context[:remote_ip],
          user_agent: context[:user_agent],
          target_email: target.email
        ),
        result: 'success'
      )

      {
        user: target.reload,
        success: true,
        message: 'Conta reativada com sucesso',
        errors: []
      }
    rescue StandardError => e
      Rails.logger.error "ActivateUser error: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
      {
        user: nil,
        success: false,
        message: 'Ocorreu um erro ao reativar a conta',
        errors: auth_error(Errors::ErrorCodes::INTERNAL_ERROR, 'An internal error occurred while activating the account')
      }
    end
  end
end
