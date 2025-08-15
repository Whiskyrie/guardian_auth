# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Usuários de desenvolvimento
puts "Criando usuários de desenvolvimento..."

admin = User.find_or_create_by!(email: 'admin@guardian.com') do |u|
  u.first_name = 'Admin'
  u.last_name = 'Guardian' 
  u.password = '123456789'
  u.role = 'admin'
end
puts "Admin criado: #{admin.email}"

user = User.find_or_create_by!(email: 'user@guardian.com') do |u|
  u.first_name = 'User'
  u.last_name = 'Guardian'
  u.password = '123456789' 
  u.role = 'user'
end
puts "Usuário criado: #{user.email}"

# Usuário de teste padrão
test_user = User.find_or_create_by!(email: 'teste@email.com') do |u|
  u.first_name = 'Teste'
  u.last_name = 'Silva'
  u.password = 'teste'
  u.role = 'user'
end
puts "Usuário de teste criado: #{test_user.email}"

puts "Seeds executados com sucesso!"
puts "Usuários disponíveis para teste:"
puts "- admin@guardian.com / senha: 123456789"
puts "- user@guardian.com / senha: 123456789"  
puts "- teste@email.com / senha: teste"
