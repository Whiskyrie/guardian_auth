class UserMailer < ApplicationMailer
  def verification_email(user, token)
    @user = user
    @token = token
    @app_url = ENV.fetch('APP_URL', 'http://localhost:3000')
    @verify_url = "#{@app_url}/verify-email?token=#{token}"
    @expires_in = '24 horas'

    mail(to: user.email, subject: '[Guardian Auth] Confirme seu endereço de email')
  end
end
