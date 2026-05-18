module Types
  class MutationType < Types::BaseObject
    description "Ponto de entrada para todas as mutações (alterações de dados) no sistema Guardian Auth"

    # Authentication mutations
    field :register_user, mutation: Mutations::RegisterUser,
                          description: "Registra um novo usuário no sistema"

    field :login_user, mutation: Mutations::LoginUser,
                       description: "Autentica um usuário e retorna token JWT"

    field :refresh_token, mutation: Mutations::RefreshToken,
                          description: "Renova um token JWT válido antes de expirar"

    field :logout_user, mutation: Mutations::LogoutUser,
                        description: "Desconecta o usuário atual e invalida o token"

    field :logout_all_devices, mutation: Mutations::LogoutAllDevices,
                               description: "Desconecta o usuário de todos os dispositivos"

    # Email verification
    field :verify_email, mutation: Mutations::VerifyEmail,
                         description: "Verifica o email usando o token enviado por email"

    field :resend_verification_email, mutation: Mutations::ResendVerificationEmail,
                                      description: "Reenvia o email de verificação para o usuário autenticado"

    # Password management
    field :change_password, mutation: Mutations::ChangePassword,
                            description: "Altera a senha do usuário autenticado"

    field :request_password_reset, mutation: Mutations::RequestPasswordReset,
                                   description: "Solicita um token de redefinição de senha"

    field :reset_password, mutation: Mutations::ResetPassword,
                           description: "Redefine a senha usando um token válido"

    # Profile management
    field :update_my_profile, mutation: Mutations::UpdateMyProfile,
                              description: "Atualiza o perfil do usuário autenticado"

    # Admin-only user management
    field :update_user, mutation: Mutations::UpdateUser,
                        description: "Atualiza dados de um usuário específico (apenas administradores)"

    field :update_user_by_email, mutation: Mutations::UpdateUserByEmail,
                                 description: "Atualiza dados de um usuário pelo email (apenas administradores)"

    field :delete_user, mutation: Mutations::DeleteUser,
                        description: "Remove um usuário do sistema (apenas administradores)"

    field :update_user_role, mutation: Mutations::UpdateUserRole,
                             description: "Atualiza o papel/função de um usuário (apenas administradores)"
  end
end
