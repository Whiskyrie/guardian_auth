# frozen_string_literal: true

module AuthorizationHelper
  extend ActiveSupport::Concern

  private

  def authorize!(record, query = nil)
    current_user = context[:current_user]
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

  def admin?
    current_user&.admin?
  end

  def owner?(record)
    current_user == record
  end
end
