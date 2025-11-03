class CleanupExpiredTokensJob < ApplicationJob
  queue_as :low_priority

  def perform
    deleted_count = TokenBlacklist.cleanup_expired!

    Rails.logger.info "CleanupExpiredTokensJob completed: removed #{deleted_count} expired tokens"

    # Optional: Send metrics or notifications if using monitoring tools
    # ApplicationMetrics.increment('jwt.cleanup.tokens_removed', deleted_count) if defined?(ApplicationMetrics)

    deleted_count
  rescue StandardError => e
    Rails.logger.error "CleanupExpiredTokensJob failed: #{e.message}"
    raise e
  end
end
