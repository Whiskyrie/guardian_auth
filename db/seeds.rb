# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Carrega helpers compartilhados
require_relative 'seeds/shared_helpers'

puts "Iniciando seeds para ambiente: #{Rails.env}"
puts Time.current.strftime('%Y-%m-%d %H:%M:%S').to_s

# Carrega seeds específicos por ambiente
environment_seeds_file = Rails.root.join('db', 'seeds', "#{Rails.env}.rb")

if File.exist?(environment_seeds_file)
  puts "Carregando seeds específicos: #{environment_seeds_file}"
  load environment_seeds_file
else
  puts "Arquivo de seeds específico não encontrado: #{environment_seeds_file}"
  puts "Carregando seeds padrão..."

  # Fallback para seeds básicos
  admin = User.find_or_create_by!(email: 'admin@guardian.com') do |u|
    u.first_name = 'Admin'
    u.last_name = 'Guardian'
    u.password = 'Admin123456'
    u.role = 'admin'
  end
  puts "Admin padrão criado: #{admin.email}"
end

# Validações finais
puts "\nExecutando validações finais..."
SeedHelpers.validate_all_users
SeedHelpers.print_statistics

puts "\nSeeds executados com sucesso para #{Rails.env}!"

# Documentação de usuários criados
puts "\nUsuários disponíveis para acesso:"

case Rails.env
when 'development'
  puts "Admins:"
  puts "   - admin@guardian.com / senha: Admin123456"
  puts "   - admin2@test.com / senha: User123456"
  puts "   - admin3@test.com / senha: User123456"
  puts "Usuários:"
  puts "   - demo@guardian.com / senha: Demo123456"
  puts "   - user1@test.com / senha: User123456"
  puts "   - user2@test.com / senha: User123456"
  puts "   - user3@test.com / senha: User123456"
  puts "   - user4@test.com / senha: User123456"
  puts "   - user5@test.com / senha: User123456"
when 'test'
  puts "Admin: admin@test.com / senha: Test123456"
  puts "Usuários:"
  puts "   - user@test.com / senha: Test123456"
  puts "   - validation@test.com / senha: Valid123456"
when 'production'
  puts "Admin: admin@guardian.com / senha: [configurada via credentials]"
  puts "Em produção, altere a senha padrão imediatamente!"
end

puts "\nPronto para uso!"
