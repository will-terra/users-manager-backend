# Health check endpoint for monitoring service availability
class UpController < ApplicationController
  # Allow public access without authentication. Use `raise: false` so tests
  # don't fail if the parent controller doesn't define the callback.
  skip_before_action :authenticate_user!, raise: false
  skip_after_action :verify_policy_scoped, raise: false

  # Returns service status with timestamp and environment
  def index
    render json: {
      status: "OK",
      timestamp: Time.current.iso8601,
      environment: Rails.env
    }
  end
end
