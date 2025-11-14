class JWTBlacklistCleanupJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "JwtBlacklistCleanupJob: starting cleanup at #{Time.current}"
    JWTBlacklist.cleanup_expired!
    Rails.logger.info "JwtBlacklistCleanupJob: finished cleanup at #{Time.current}"
  rescue StandardError => e
    Rails.logger.error "JwtBlacklistCleanupJob: error during cleanup - #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}" if defined?(Rails)
    raise
  end
end
