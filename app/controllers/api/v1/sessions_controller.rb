module Api
  module V1
    # Controller responsible for user sessions (login/logout) using JWTs.
    #
    # - `create` authenticates a user and returns a JWT token plus basic user
    #   attributes on success.
    # - `destroy` is a no-op for stateless JWTs (clients discard the token).
    class SessionsController < BaseController
      # Allow unauthenticated access to login
      skip_before_action :authenticate_user_from_token!, only: [ :create ]

      before_action :pundit_skip!
      before_action :require_authentication!, only: [ :refresh ]

      # POST /api/v1/sessions
      # Params: { user: { email: string, password: string } }
      # On success returns: { user: { ... }, token: 'jwt', redirect_to: '/path' }
      def create
        # Find the user by email (Devise helper)
        user = User.find_for_database_authentication(email: session_params[:email])

        # Verify password and, if valid, issue a JWT for client use
        if user&.valid_password?(session_params[:password])
          token = user.generate_jwt
          render_success(
            {
              user: user_serialized(user),
              token: token,
              redirect_to: redirect_path(user)
            },
            status: :created
          )
        else
          # Generic error to avoid leaking whether email exists
          render_error("Invalid email or password", status: :unauthorized)
        end
      end

      # DELETE /api/v1/sessions
      # For stateless JWT authentication, logout is normally handled on the
      # client by deleting the stored token. We also blacklist the token
      # on the server to prevent reuse.
      def destroy
        # Extract and blacklist the current JWT token
        if current_user && request.headers["Authorization"].present?
          token = request.headers["Authorization"].split(" ").last
          begin
            payload = JWT.decode(
              token,
              Rails.application.credentials.devise_jwt_secret_key,
              true,
              { algorithm: "HS256" }
            ).first
            JWTBlacklist.revoke_jwt(payload, current_user)
          rescue JWT::DecodeError => e
            Rails.logger.warn("Failed to decode JWT during logout: #{e.message}")
          end
        end

        render_success(nil, status: :no_content)
      end

      # POST /api/v1/sessions/refresh
      # Refreshes the JWT token for authenticated users, providing a new token
      # with updated expiration time. This allows users to stay logged in
      # while actively using the application.
      def refresh
        token = current_user.generate_jwt
        render_success(
          {
            user: user_serialized(current_user),
            token: token,
            redirect_to: redirect_path(current_user)
          },
          status: :ok
        )
      end

      private

      # Strong parameters for the session endpoints
      def session_params
        params.require(:user).permit(:email, :password)
      end

      # Choose a redirect path based on user role. This is returned in the
      # JSON response so the frontend can navigate appropriately after login.
      def redirect_path(user)
        user.admin? ? "/admin/dashboard" : "/profile"
      end

      # Serialize user data for the response
      def user_serialized(user)
        UserSerializer.new(user).serializable_hash[:data][:attributes]
      end
    end
  end
end
