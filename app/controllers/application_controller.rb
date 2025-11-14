class ApplicationController < ActionController::API
  # Include Pundit for authorization helpers and policies
  include Pundit::Authorization

  # Ensure requests are authenticated before any controller action runs.
  # authenticate_user_from_token! will set `@current_user` when a valid JWT is provided.
  before_action :authenticate_user_from_token!

  # After actions help enforce that controllers call Pundit authorization
  # methods. Use lambda-based conditionals to avoid Rails raising when a
  # controller doesn't implement the referenced action (Rails >= 7.1 will
  # raise for missing callback actions if configured to do so).
  # - `verify_authorized` should run for every action except `index`.
  # - `verify_policy_scoped` should run only for `index` actions.
  after_action :verify_authorized, if: -> { action_name != "index" && !pundit_skipped? }
  after_action :verify_policy_scoped, if: -> { action_name == "index" && !pundit_skipped? }

  # Map common exceptions to JSON error responses with appropriate HTTP
  # statuses so API clients get consistent error shapes.
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  # Track whether Pundit verification should be skipped. Subclasses
  # (e.g. public authentication controllers) call `pundit_skip!` to set this.
  def pundit_skipped?
    @pundit_skipped == true
  end

  # Mark this controller as having Pundit verification explicitly skipped
  # (for public endpoints like login/registration).
  def pundit_skip!
    @pundit_skipped = true
  end

  # Authenticate the request using a Bearer JWT sent in the
  # `Authorization` header. If present, the token is decoded using the
  # secret key stored in Rails credentials under `devise_jwt_secret_key` and the
  # corresponding User is loaded into `@current_user`.
  #
  # If no token is provided and this method is not skipped, it will render
  # a 401 error. If this method is skipped (via skip_before_action),
  # @current_user will simply be nil.
  def authenticate_user_from_token!
    token = extract_token_from_request

    if token
      begin
        # Decode JWT and find the user by id inside the token payload.
        # Use the secret from Rails credentials.
        decoded_token = JWT.decode(
          token,
          Rails.application.credentials.devise_jwt_secret_key,
          true,
          { algorithm: "HS256" }
        ).first

        user_id = decoded_token["id"]
        @current_user = User.find_by(id: user_id)

        unless @current_user
          render json: { error: "User not found" }, status: :unauthorized
          nil
        end

      rescue JWT::DecodeError => e
        Rails.logger.error "JWT Decode Error: #{e.message}"
        render json: { error: "Invalid token" }, status: :unauthorized
        nil
      rescue JWT::ExpiredSignature => e
        Rails.logger.error "JWT Expired: #{e.message}"
        render json: { error: "Token expired" }, status: :unauthorized
        nil
      end
    else
      # If no token is provided, set current_user to nil
      # The action will handle authorization checks as needed
      @current_user = nil
    end
  end

  # Returns the currently authenticated user (if any).
  def current_user
    @current_user
  end

  # Extract the JWT token from the Authorization header.
  # Expected format: "Bearer <token>"
  def extract_token_from_request
    header = request.headers["Authorization"]
    header&.split(" ")&.last
  end

  # Require that the current user has admin role.
  # Renders 403 Forbidden if the user is not an admin.
  def require_admin!
    unless current_user&.admin?
      render json: { error: "Admin access required" }, status: :forbidden
    end
  end

  # Require that a user is authenticated.
  # Returns 401 Unauthorized if no user is authenticated.
  def require_authentication!
    unless current_user
      render json: { error: "Authentication token required" }, status: :unauthorized
    end
  end

  # Render a consistent JSON response for authorization failures.
  def user_not_authorized
    render json: {
      success: false,
      error: {
        code: :forbidden,
        message: "You are not authorized to perform this action"
      }
    }, status: :forbidden
  end

  # Render a consistent JSON response for ActiveRecord::RecordNotFound.
  def record_not_found
    render json: {
      success: false,
      error: {
        code: :not_found,
        message: "Record not found"
      }
    }, status: :not_found
  end
end
