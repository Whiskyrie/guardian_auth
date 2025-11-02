# frozen_string_literal: true

# PasswordResetMailer for sending password reset emails
# Handles HTML and text email templates for password recovery
class PasswordResetMailer < ApplicationMailer
  # Send password reset email
  def reset_password_email(user, token, reset_url)
    @user = user
    @token = token
    @reset_url = reset_url
    @expires_in = '1 hora'
    @frontend_url = ENV['FRONTEND_URL'] || 'http://localhost:3000'
    @app_name = 'Guardian Auth'
    @support_email = ENV['SUPPORT_EMAIL'] || 'support@guardian-auth.com'

    # Set email headers
    headers['X-Entity-Ref-ID'] = "password-reset-#{user.id}-#{Time.current.to_i}"

    mail(
      to: user.email,
      from: ENV['FROM_EMAIL'] || 'noreply@guardian-auth.com',
      subject: "Redefinir senha - #{@app_name}",
      template_name: 'reset_password'
    )
  end

  # Test email for configuration validation
  def test_email
    @app_name = 'Guardian Auth'
    @test_message = 'Este é um email de teste para validar a configuração do sistema.'

    mail(
      to: params[:to],
      from: ENV['FROM_EMAIL'] || 'noreply@guardian-auth.com',
      subject: "Email de teste - #{@app_name}",
      template_name: 'test_email'
    )
  end

  # Email notification for successful password reset
  def password_reset_confirmation(user)
    @user = user
    @app_name = 'Guardian Auth'
    @frontend_url = ENV['FRONTEND_URL'] || 'http://localhost:3000'
    @support_email = ENV['SUPPORT_EMAIL'] || 'support@guardian-auth.com'

    headers['X-Entity-Ref-ID'] = "password-reset-confirmation-#{user.id}-#{Time.current.to_i}"

    mail(
      to: user.email,
      from: ENV['FROM_EMAIL'] || 'noreply@guardian-auth.com',
      subject: "Senha redefinida com sucesso - #{@app_name}",
      template_name: 'password_reset_confirmation'
    )
  end

  # Email notification for suspicious activity
  def security_alert(user, activity_details)
    @user = user
    @activity = activity_details
    @app_name = 'Guardian Auth'
    @frontend_url = ENV['FRONTEND_URL'] || 'http://localhost:3000'
    @support_email = ENV['SUPPORT_EMAIL'] || 'support@guardian-auth.com'

    headers['X-Priority'] = '1'
    headers['X-MSMail-Priority'] = 'High'

    mail(
      to: user.email,
      from: ENV['FROM_EMAIL'] || 'noreply@guardian-auth.com',
      subject: "Alerta de segurança - #{@app_name}",
      template_name: 'security_alert'
    )
  end

  # Override default mailer defaults if needed
  default from: ENV['FROM_EMAIL'] || 'noreply@guardian-auth.com',
          reply_to: ENV['SUPPORT_EMAIL'] || 'support@guardian-auth.com'
end
