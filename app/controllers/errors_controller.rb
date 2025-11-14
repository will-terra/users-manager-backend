# Controller for handling custom error responses.
# Configured via config.exceptions_app to provide consistent JSON error formatting.
# All actions skip authentication since errors can occur before auth.
class ErrorsController < ApplicationController
  skip_before_action :authenticate_user_from_token!

  before_action :pundit_skip!

  # Handle 404 Not Found errors
  def not_found
    render json: {
      success: false,
      error: {
        code: 404,
        message: "Route not found",
        details: "The route '#{request.path}' does not exist"
      }
    }, status: :not_found
  end

  # Handle 500 Internal Server Error
  def internal_server_error
    render json: {
      success: false,
      error: {
        code: 500,
        message: "Internal server error",
        details: "Something went wrong on our end. Please try again later."
      }
    }, status: :internal_server_error
  end

  # Handle 422 Unprocessable Entity errors
  def unprocessable_entity
    render json: {
      success: false,
      error: {
        code: 422,
        message: "Unprocessable entity",
        details: "The request was well-formed but unable to be processed."
      }
    }, status: :unprocessable_content
  end
end
