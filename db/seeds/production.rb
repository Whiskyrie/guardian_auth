# Seeds para ambiente de produção
# Apenas dados essenciais para funcionamento do sistema

puts "🚀 Carregando seeds de produção..."

# Apenas o admin principal é criado em produção
admin = User.find_or_create_by!(email: 'admin@guardian.com') do |u|
  u.first_name = 'System'
  u.last_name = 'Administrator'
  u.password = Rails.application.credentials.admin_password || 'Admin123456'
  u.role = 'admin'
end
puts "✅ Administrador do sistema criado: #{admin.email}"

puts "🎉 Seeds de produção carregados com sucesso!"
puts "📊 Total de usuários: #{User.count}"

# Aviso de segurança
unless Rails.application.credentials.admin_password
  puts "⚠️  AVISO: Usando senha padrão. Configure Rails.application.credentials.admin_password em produção!"
end
