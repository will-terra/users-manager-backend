class JWTBlacklist < ApplicationRecord
  # Stores revoked JWT identifiers (jti) with expiry so tokens can be invalidated

  # Check if the JWT (payload) has been revoked
  # payload is expected to include 'jti' and 'exp'
  def self.jwt_revoked?(payload, user)
    jti = payload["jti"] || payload[:jti]
    return false unless jti

    where(jti: jti).exists?
  end

  # Revoke a JWT by storing its jti and exp
  def self.revoke_jwt(payload, user)
    jti = payload["jti"] || payload[:jti]
    return unless jti

    exp = begin
      Time.at(payload["exp"] || payload[:exp]).utc
    rescue StandardError
      nil
    end

    # If exp is missing, set a reasonable short TTL (e.g., now)
    exp ||= Time.now.utc

    # Create an entry unless one already exists
    create_with(exp: exp).find_or_create_by(jti: jti)
  end

  # Optional: cleanup expired entries (can be scheduled)
  def self.cleanup_expired!
    where("exp < ?", Time.now.utc).delete_all
  end
end
