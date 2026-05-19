class SessionPolicy < ApplicationPolicy
  def show?
    owner? || admin?
  end

  def destroy?
    owner? || admin?
  end

  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      elsif user
        scope.where(user_id: user.id)
      else
        scope.none
      end
    end
  end

  private

  def owner?
    user && record.user_id == user.id
  end
end
