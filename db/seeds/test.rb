# Seeds específicos para ambiente de teste
# Mantém dados mínimos e previsíveis para testes automatizados

puts "🧪 Carregando seeds de teste..."

# Admin de teste
admin = User.find_or_create_by!(email: 'admin@test.com') do |u|
  u.first_name = 'Test'
  u.last_name = 'Admin'
  u.password = 'Test123456'
  u.role = 'admin'
end
puts "✅ Admin de teste criado: #{admin.email}"

# Usuário padrão de teste
user = User.find_or_create_by!(email: 'user@test.com') do |u|
  u.first_name = 'Test'
  u.last_name = 'User'
  u.password = 'Test123456'
  u.role = 'user'
end
puts "✅ Usuário de teste criado: #{user.email}"

# Usuário para testes específicos de validação
validation_user = User.find_or_create_by!(email: 'validation@test.com') do |u|
  u.first_name = 'Validation'
  u.last_name = 'Test'
  u.password = 'Valid123456'
  u.role = 'user'
end
puts "✅ Usuário de validação criado: #{validation_user.email}"

puts "🎉 Seeds de teste carregados com sucesso!"
puts "📊 Total de usuários: #{User.count}"
