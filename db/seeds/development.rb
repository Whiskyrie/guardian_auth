# Seeds específicos para desenvolvimento
# Carrega dados realistas para facilitar desenvolvimento e testes manuais

puts "Carregando seeds de desenvolvimento..."

# Admin principal
admin = User.find_or_create_by!(email: 'admin@guardian.com') do |u|
  u.first_name = 'Admin'
  u.last_name = 'Guardian'
  u.password = 'Admin123456'
  u.role = 'admin'
end
puts "Admin criado: #{admin.email} (#{admin.role})"

# Usuários de teste com dados variados
test_users_data = [
  {
    first_name: 'João',
    last_name: 'Silva',
    email: 'user1@test.com',
    role: 'user'
  },
  {
    first_name: 'Maria',
    last_name: 'Santos',
    email: 'user2@test.com',
    role: 'user'
  },
  {
    first_name: 'Pedro',
    last_name: 'Oliveira',
    email: 'user3@test.com',
    role: 'user'
  },
  {
    first_name: 'Ana',
    last_name: 'Costa',
    email: 'user4@test.com',
    role: 'user'
  },
  {
    first_name: 'Carlos',
    last_name: 'Ferreira',
    email: 'user5@test.com',
    role: 'user'
  },
  {
    first_name: 'Admin',
    last_name: 'Secundário',
    email: 'admin2@test.com',
    role: 'admin'
  },
  {
    first_name: 'Super',
    last_name: 'Admin',
    email: 'admin3@test.com',
    role: 'admin'
  }
]

test_users_data.each do |user_data|
  user = User.find_or_create_by!(email: user_data[:email]) do |u|
    u.first_name = user_data[:first_name]
    u.last_name = user_data[:last_name]
    u.password = 'User123456'
    u.role = user_data[:role]
  end
  puts "Usuário criado: #{user.email} (#{user.role})"
end

# Usuário de demonstração com nome mais realista
demo_user = User.find_or_create_by!(email: 'demo@guardian.com') do |u|
  u.first_name = 'Demo'
  u.last_name = 'User'
  u.password = 'Demo123456'
  u.role = 'user'
end
puts "Usuário demo criado: #{demo_user.email} (#{demo_user.role})"

puts "Seeds de desenvolvimento carregados com sucesso!"
puts "Total de usuários: #{User.count}"
puts "Admins: #{User.admins.count}"
puts "Usuários: #{User.users.count}"
