module Api
  module V1
    module Admin
      # Controller that exposes administrative statistics about users.
      # Intended for admin-only access and returns aggregated metrics as JSON.
      class StatsController < ApplicationController
        # GET /api/v1/admin/stats
        # Returns a JSON payload with aggregated user metrics (counts, distributions).
        def index
          authorize User, :index?
          skip_policy_scope

          stats = {
            total_users: User.count,
            admin_count: User.admins.count,
            user_count: User.users.count,
            recent_signups: User.where("created_at >= ?", 7.days.ago).count,
            active_today: User.where("last_sign_in_at >= ?", 1.day.ago).count,
            inactive_users: User.where("last_sign_in_at <= ?", 30.days.ago).count,
            users_by_month: users_by_month_data,
            role_distribution: role_distribution_data
          }

          render json: { stats: stats }
        end

        private

        # Build a hash of user signups grouped by month (YYYY-MM -> count).
        # Uses DATE_TRUNC to aggregate by month and formats keys as 'YYYY-MM'.
        def users_by_month_data
          User.group(Arel.sql("DATE_TRUNC('month', created_at)"))
              .order(Arel.sql("DATE_TRUNC('month', created_at)"))
              .count
              .transform_keys { |date| date.strftime("%Y-%m") }
        end

        # Returns a hash of user counts keyed by role (e.g., { 'admin' => 3, 'user' => 42 }).
        def role_distribution_data
          User.group(:role).count
        end
      end
    end
  end
end
