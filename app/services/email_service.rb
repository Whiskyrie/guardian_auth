# frozen_string_literal: true

# EmailService for managing transactional email delivery
# Handles password reset emails and configuration validation
class EmailService
  class << self
    # Send password reset email
    def send_password_reset_email(user:, token:, reset_url:)
      return false unless user.present? && token.present?

      begin
        # Create mailer instance
        mailer = PasswordResetMailer.reset_password_email(user, token, reset_url)

        # Send email
        mailer.deliver_now

        Rails.logger.info "Password reset email sent successfully to #{user.email}"
        true
      rescue StandardError => e
        Rails.logger.error "Failed to send password reset email to #{user.email}: #{e.message}"
        SecurityLogger.log_suspicious_activity(
          user_id: user.id,
          activity: 'email_delivery_failed',
          details: { email: user.email, error: e.message }
        )
        false
      end
    end

    # Send email asynchronously (using Active Job)
    def send_password_reset_email_async(user:, token:, reset_url:)
      return false unless user.present? && token.present?

      begin
        PasswordResetMailer
          .reset_password_email(user, token, reset_url)
          .deliver_later

        Rails.logger.info "Password reset email queued for #{user.email}"
        true
      rescue StandardError => e
        Rails.logger.error "Failed to queue password reset email for #{user.email}: #{e.message}"
        false
      end
    end

    # Validate email configuration
    def validate_configuration!
      required_configs = %w[
        SMTP_ADDRESS
        SMTP_PORT
        SMTP_USERNAME
        SMTP_PASSWORD
        SMTP_DOMAIN
        FROM_EMAIL
        FRONTEND_URL
      ]

      missing_configs = required_configs.reject { |config| ENV[config].present? }

      if missing_configs.any?
        raise EmailConfigurationError, "Missing email configuration: #{missing_configs.join(', ')}"
      end

      true
    end

    # Test email delivery
    def test_delivery(to_email:)
      return false if to_email.blank?

      begin
        validate_configuration!

        test_mail = PasswordResetMailer
                    .with(to: to_email)
                    .test_email

        test_mail.deliver_now

        Rails.logger.info "Test email sent successfully to #{to_email}"
        true
      rescue StandardError => e
        Rails.logger.error "Failed to send test email to #{to_email}: #{e.message}"
        false
      end
    end

    # Get email delivery statistics (placeholder for future implementation)
    def delivery_stats
      {
        sent_today: 0, # TODO: Implement with email tracking
        failed_today: 0,
        bounced_today: 0,
        opened_today: 0,
        clicked_today: 0
      }
    end

    # Custom error classes
    class EmailConfigurationError < StandardError; end
    class EmailDeliveryError < StandardError; end
  end
end
