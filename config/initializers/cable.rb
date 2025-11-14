# Action Cable Configuration
Rails.application.configure do
  # Configure Action Cable
  config.action_cable.mount_path = "/cable"
  config.action_cable.url = ENV.fetch("ACTION_CABLE_URL", "ws://localhost:3000/cable")

  # In production, configure allowed_request_origins
  if Rails.env.production?
    config.action_cable.allowed_request_origins = [
      ENV.fetch("FRONTEND_URL", "http://localhost:5173")
    ]
  end
end
