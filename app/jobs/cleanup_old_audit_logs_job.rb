# frozen_string_literal: true

class CleanupOldAuditLogsJob < ApplicationJob
  queue_as :low_priority

  def perform(retention_days = nil)
    # Get retention period from environment variable or use default
    retention_days = retention_days || ENV.fetch('AUDIT_LOG_RETENTION_DAYS', 90).to_i
    
    # Calculate cutoff date
    cutoff_date = retention_days.days.ago
    
    # Delete old audit logs
    deleted_count = AuditLog.where('created_at < ?', cutoff_date).delete_all
    
    Rails.logger.info "CleanupOldAuditLogsJob completed: removed #{deleted_count} audit logs older than #{retention_days} days"
    
    # Optional: Send metrics or notifications if using monitoring tools
    # ApplicationMetrics.increment('audit.logs.cleanup', deleted_count) if defined?(ApplicationMetrics)
    
    deleted_count
  rescue StandardError => e
    Rails.logger.error "CleanupOldAuditLogsJob failed: #{e.message}"
    raise e
  end
end
