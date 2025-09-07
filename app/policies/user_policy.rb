# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def show?
    # Usuário pode ver próprio perfil ou admin pode ver qualquer usuário
    owner? || admin?
  end

  def create?
    # Qualquer um pode criar usuário (registro)
    true
  end

  def update?
    # Usuário pode editar próprio perfil ou admin pode editar qualquer usuário
    owner? || admin?
  end

  def destroy?
    # Admin pode deletar usuários, mas não a si mesmo
    admin? && !owner?
  end

  def index?
    # Apenas admin pode listar todos os usuários
    admin?
  end

  class Scope < Scope
    def resolve
      if user&.admin?
        scope.all
      elsif user
        scope.where(id: user.id)
      else
        scope.none
      end
    end
  end
end
