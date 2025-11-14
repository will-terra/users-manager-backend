# Small service responsible for building and broadcasting a compact
# administrative stats snapshot over ActionCable. The payload is kept
# intentionally minimal so clients can update dashboards in real-time
# without large messages.
class StatsBroadcastService
  # Broadcast a single 'stats_update' message on the 'admin_stats'
  # channel. The method is a simple class-level entrypoint so it can
  # be called from jobs or controllers without instantiating the
  # service.
  def self.broadcast_stats_update
    stats = {
      # total number of user records
      total_users: User.count,
      # number of admin users (expects `admins` scope on User)
      admin_count: User.admins.count,
      # number of regular users (expects `users` scope on User)
      user_count: User.users.count,
      # signups within the last 7 days
      recent_signups: User.where("created_at >= ?", 7.days.ago).count,
      # users who signed in within the last 24 hours
      active_today: User.where("last_sign_in_at >= ?", 1.day.ago).count,
      # timestamp the snapshot so clients can show freshness
      timestamp: Time.current.iso8601
    }

    ActionCable.server.broadcast(
      "admin_stats",
      {
        type: "stats_update",
        data: stats
      }
    )
  end
end
