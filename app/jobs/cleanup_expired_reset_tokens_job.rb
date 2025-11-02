# frozen_string_literal: true

# CleanupExpiredResetTokensJob for cleaning up expired password reset tokens
# Runs periodically to maintain database hygiene
class CleanupExpiredResetTokensJob < ApplicationJob
  queue_as :low_priority

  def perform
    deleted_count = PasswordResetToken.cleanup_expired!

    Rails.logger.info "CleanupExpiredResetTokensJob completed: removed #{deleted_count} expired password reset tokens"

    # Optional: Send metrics or notifications if using monitoring tools
    # ApplicationMetrics.increment('password_reset.cleanup.tokens_removed', deleted_count) if defined?(ApplicationMetrics)

    deleted_count
  rescue StandardError => e
    Rails.logger.error "CleanupExpiredResetTokensJob failed: #{e.message}"
    raise e
  end
end
