# Seeds para dados de demonstração mais complexos
# Carrega apenas em desenvolvimento quando solicitado

puts "🎭 Carregando dados de demonstração avançados..."

# Cria usuários com dados mais realistas usando Faker se disponível
require 'securerandom'

# Configurações
DEMO_USERS_COUNT = 50
DEMO_ADMINS_COUNT = 5

# Nomes de exemplo (case Faker não esteja disponível)
first_names = %w[
  João Maria Pedro Ana Carlos Lucia Paulo Isabel Roberto Fernanda
  André Juliana Ricardo Beatriz Marcos Camila Gabriel Larissa Felipe Rafaela
  Diego Amanda Rodrigo Patrícia Bruno Vanessa Leonardo Priscila Fabio Carolina
  Gustavo Monica Alexandre Daniela Vitor Claudia Thiago Sandra Eduardo Renata
  Lucas Cristina Marcelo Adriana Rafael Eliane Leandro Silvia Fernando Tatiana
]

last_names = %w[
  Silva Santos Oliveira Souza Rodrigues Ferreira Alves Pereira Lima Costa
  Ribeiro Martins Carvalho Gomes Barbosa Rocha Araújo Dias Cardoso Nascimento
  Correia Fernandes Castro Freitas Melo Cunha Pinto Moreira Ramos Azevedo
  Monteiro Campos Reis Cavalcanti Duarte Machado Nogueira Lopes Teixeira Mendes
]

puts "👥 Criando #{DEMO_USERS_COUNT} usuários de demonstração..."

DEMO_USERS_COUNT.times do |i|
  first_name = first_names.sample
  last_name = last_names.sample
  email = "demo#{i + 1}@exemplo.com"
  
  user = User.find_or_create_by!(email: email) do |u|
    u.first_name = first_name
    u.last_name = last_name
    u.password = 'Demo123456'
    u.role = 'user'
  end
  
  # Simula alguns logins passados
  if rand > 0.3  # 70% chance de ter feito login
    user.update!(last_login_at: rand(30.days).seconds.ago)
  end
  
  print "." if (i + 1) % 10 == 0
end

puts "\n👑 Criando #{DEMO_ADMINS_COUNT} admins de demonstração..."

DEMO_ADMINS_COUNT.times do |i|
  first_name = first_names.sample
  last_name = last_names.sample
  email = "admin-demo#{i + 1}@exemplo.com"
  
  admin = User.find_or_create_by!(email: email) do |u|
    u.first_name = first_name
    u.last_name = last_name
    u.password = 'Admin123456'
    u.role = 'admin'
  end
  
  # Admins fazem login mais frequentemente
  admin.update!(last_login_at: rand(7.days).seconds.ago)
  
  puts "✅ Admin demo criado: #{admin.email}"
end

# Simula alguns usuários desativados (para testes futuros)
inactive_emails = %w[
  inativo1@exemplo.com
  inativo2@exemplo.com
  suspendido@exemplo.com
]

puts "\n😴 Criando usuários inativos para testes..."

inactive_emails.each do |email|
  user = User.find_or_create_by!(email: email) do |u|
    u.first_name = 'Usuário'
    u.last_name = 'Inativo'
    u.password = 'Inactive123456'
    u.role = 'user'
  end
  # Não define last_login_at para manter como "nunca logou"
  puts "✅ Usuário inativo criado: #{user.email}"
end

puts "\n🎉 Dados de demonstração carregados!"
puts "📊 Estatísticas finais:"
puts "   Total geral: #{User.count} usuários"
puts "   👤 Usuários comuns: #{User.users.count}"
puts "   👑 Administradores: #{User.admins.count}"
puts "   ✅ Já fizeram login: #{User.active.count}"
puts "   😴 Nunca logaram: #{User.inactive.count}"

puts "\n💡 Para acessar os dados de demo:"
puts "   - Usuários: demo1@exemplo.com até demo#{DEMO_USERS_COUNT}@exemplo.com"
puts "   - Admins: admin-demo1@exemplo.com até admin-demo#{DEMO_ADMINS_COUNT}@exemplo.com"
puts "   - Inativos: inativo1@exemplo.com, inativo2@exemplo.com, suspendido@exemplo.com"
puts "   - Senha padrão: Demo123456 (usuários) ou Admin123456 (admins)"
