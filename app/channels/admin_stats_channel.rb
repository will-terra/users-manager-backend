# WebSocket channel for broadcasting basic administrative statistics.
# Only admin users are allowed to subscribe. The channel streams on
# the "admin_stats" broadcast and can push a current snapshot of stats
# on subscription or when the client explicitly requests them.
class AdminStatsChannel < ApplicationCable::Channel
  # Called when a client attempts to subscribe to this channel.
  # Rejects non-admin users and starts streaming for admins, then
  # immediately transmits the current stats snapshot.
  def subscribed
    return reject unless current_user&.admin?

    stream_from "admin_stats"

    transmit_current_stats
  end

  # Hook for when the connection unsubscribes (kept empty intentionally).
  def unsubscribed
  end

  # Client-invoked action to request an immediate stats snapshot.
  def request_stats
    transmit_current_stats
  end

  private

  # Build and transmit a small, stable hash of admin stats.
  # Shape: { type: "stats_update", data: { total_users:, admin_count:, ... } }
  # Keys are minimal to keep the payload compact for WebSocket clients.
  def transmit_current_stats
    stats = {
      # total number of user records
      total_users: User.count,
      # number of admin users (scope on User model)
      admin_count: User.admins.count,
      # number of non-admin users (scope on User model)
      user_count: User.users.count,
      # signups in the last 7 days
      recent_signups: User.where("created_at >= ?", 7.days.ago).count,
      # users who signed in within the last 24 hours
      active_today: User.where("last_sign_in_at >= ?", 1.day.ago).count
    }

    transmit({ type: "stats_update", data: stats })
  end
end
