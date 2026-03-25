# Fonte canônica de autenticação para o layer GraphQL.
#
# Este concern é a ÚNICA implementação autorizada dos métodos `current_user`,
# `authenticated?` e `authenticate!` para mutations e tipos do sistema Guardian Auth.
# Qualquer alteração aqui propaga automaticamente para BaseMutation e BaseObject.
#
# NÃO duplique estes métodos em mutations ou tipos individuais.
module AuthorizationHelper
  extend ActiveSupport::Concern

  private

  def authorize!(record, query = nil)
    policy = Pundit.policy(current_user, record)
    query ||= :index?

    raise GraphQL::ExecutionError, 'Not authorized' unless policy.public_send(query)

    policy
  end

  def pundit_user
    context[:current_user]
  end

  def current_user
    context[:current_user]
  end

  def authenticated?
    current_user.present?
  end

  def authenticate!
    return true if authenticated?

    raise GraphQL::ExecutionError, 'Authentication required. Please provide a valid token.'
  end

  def admin?
    current_user&.admin?
  end

  def owner?(record)
    current_user == record
  end
end
