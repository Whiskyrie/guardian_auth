module Mutations
  class UpdateUserByEmail < BaseMutation
    description 'Update user information by email'

    argument :email, String, description: 'Email of user to update'
    argument :input, Types::UserInputType, description: 'User fields to update'

    field :success, Boolean, null: false, description: 'Whether the update was successful'
    field :message, String, null: true, description: 'Result message'
    field :user, Types::UserType, null: true
    field :errors, [Types::UserErrorType], null: false

    def resolve(email:, input:)
      # Buscar o usuário pelo email
      user = User.find_by_email(email)

      unless user
        return {
          success: false,
          message: 'User not found',
          user: nil,
          errors: auth_error(Errors::ErrorCodes::RESOURCE_NOT_FOUND, 'User not found')
        }
      end

      # Verificar autorização usando Pundit
      authorize!(user, :update?)

      role_validation = validate_role_change(input)
      return role_validation if role_validation

      update_attrs = input.to_h.compact
      requested_role = update_attrs.delete(:role)

      begin
        ActiveRecord::Base.transaction do
          user.update!(update_attrs)
          apply_role_change!(user, requested_role) if requested_role.present?
        end
      rescue ActiveRecord::RecordInvalid => e
        return { success: false, message: 'Update failed', user: nil, errors: format_model_errors(e.record) }
      end

      { success: true, message: 'User updated successfully', user: user.reload, errors: [] }
    end

    private

    def validate_role_change(input)
      return unless input[:role].present?

      unless current_user&.admin?
        return {
          success: false,
          message: 'Only administrators can change user roles',
          user: nil,
          errors: auth_error(Errors::ErrorCodes::INSUFFICIENT_PERMISSIONS,
                             'Only administrators can change user roles')
        }
      end

      unless Role.exists?(name: input[:role])
        return {
          success: false,
          message: 'Role not found',
          user: nil,
          errors: auth_error(Errors::ErrorCodes::INVALID_INPUT,
                             "Role '#{input[:role]}' is not configured in the system")
        }
      end

      nil
    end

    def apply_role_change!(user, role_name)
      role = Role.find_by(name: role_name)
      return unless role

      user.user_roles.where.not(role_id: role.id).destroy_all
      user.user_roles.find_or_create_by!(role: role) do |user_role|
        user_role.granted_by = current_user
        user_role.granted_at = Time.current
      end
    end
  end
end
