# Helpers e configurações compartilhadas entre ambientes

module SeedHelpers
  # Método para verificar se um usuário já existe e foi atualizado
  def self.log_user_creation(user, action = 'criado')
    status = user.persisted? ? 'OK' : 'ERRO'
    puts "#{status} Usuário #{action}: #{user.email} (#{user.role})"

    if user.errors.any?
      puts "  AVISO: Erros: #{user.errors.full_messages.join(', ')}"
    end
  end

  # Método para criar usuário com log melhorado
  def self.create_user_with_log(email:, first_name:, last_name:, role: 'user', password: 'User123456')
    user = User.find_or_initialize_by(email: email)

    if user.persisted?
      # Usuário já existe, apenas atualiza se necessário
      updated = false

      if user.first_name != first_name
        user.first_name = first_name
        updated = true
      end

      if user.last_name != last_name
        user.last_name = last_name
        updated = true
      end

      if user.role != role
        user.role = role
        updated = true
      end

      if updated
        user.save!
        log_user_creation(user, 'atualizado')
      else
        log_user_creation(user, 'já existe')
      end
    else
      # Usuário novo
      user.first_name = first_name
      user.last_name = last_name
      user.password = password
      user.role = role
      user.save!
      log_user_creation(user)
    end

    user
  end

  # Estatísticas do banco
  def self.print_statistics
    puts "\nEstatísticas atuais:"
    puts "   Total de usuários: #{User.count}"
    puts "   Admins: #{User.admins.count}"
    puts "   Usuários: #{User.users.count}"
    puts "   Nunca logaram: #{User.inactive.count}"
    puts "   Já logaram: #{User.active.count}"
  end

  # Valida se todos os usuários são válidos
  def self.validate_all_users
    invalid_users = User.all.reject(&:valid?)

    if invalid_users.any?
      puts "\nUsuários inválidos encontrados:"
      invalid_users.each do |user|
        puts "   #{user.email}: #{user.errors.full_messages.join(', ')}"
      end
      return false
    end

    puts "\nTodos os usuários são válidos!"
    true
  end
end
