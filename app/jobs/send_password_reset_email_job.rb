# frozen_string_literal: true

# SendPasswordResetEmailJob for sending password reset emails asynchronously
# Queues email delivery with proper error handling and logging
class SendPasswordResetEmailJob < ApplicationJob
  queue_as :default

  def perform(user_id, token)
    user = User.find_by(id: user_id)

    unless user
      Rails.logger.warn "SendPasswordResetEmailJob: User not found for ID #{user_id}"
      return false
    end

    # Build reset URL
    reset_url = build_reset_url(token)

    # Send email
    success = EmailService.send_password_reset_email(
      user: user,
      token: token,
      reset_url: reset_url
    )

    if success
      Rails.logger.info "Password reset email sent successfully to #{user.email}"
    else
      Rails.logger.error "Failed to send password reset email to #{user.email}"
      # Could implement retry logic here if needed
    end

    success
  rescue StandardError => e
    Rails.logger.error "SendPasswordResetEmailJob failed for user #{user_id}: #{e.message}"

    # Log security event for failed email delivery
    SecurityLogger.log_suspicious_activity(
      user_id: user_id,
      activity: 'password_reset_email_failed',
      details: { error: e.message, user_id: user_id }
    )

    false
  end

  private

  def build_reset_url(token)
    frontend_url = ENV['FRONTEND_URL'] || 'http://localhost:3000'
    "#{frontend_url}/reset-password?token=#{token}"
  end
end
