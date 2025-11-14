module Api
  module V1
    # Base controller for all API v1 endpoints
    # Provides:
    # - Pundit authorization with automatic verification
    # - Centralized exception handling for common errors
    # - Standardized JSON response formatting (success/error)
    # - Validation error formatting
    class BaseController < ApplicationController
      include Pundit::Authorization

      # Exception handlers for common error scenarios
      rescue_from Pundit::NotAuthorizedError, with: :handle_unauthorized
      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
      rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
      rescue_from JWT::DecodeError, with: :handle_jwt_error
      rescue_from JWT::ExpiredSignature, with: :handle_jwt_expired

      protected

      # Render a successful JSON response with optional data and metadata
      def render_success(data = nil, status: :ok, meta: {})
        response_data = { success: true }
        response_data[:data] = data if data
        response_data[:meta] = meta if meta.any?

        render json: response_data, status: status
      end

      # Render an error JSON response with message and optional details
      def render_error(message, status: :unprocessable_content, details: nil)
        error_response = {
          success: false,
          error: {
            code: status,
            message: message,
            details: details
          }
        }

        render json: error_response, status: status
      end

      # Render validation errors from an ActiveRecord model
      def render_validation_errors(record)
        errors = record.errors.full_messages.map do |message|
          {
            field: record.errors.attribute_names.find { |attr| record.errors[attr].include?(message) },
            message: message
          }
        end

        render_error(
          "Validation failed",
          status: :unprocessable_content,
          details: errors
        )
      end

      private

      # Handle Pundit authorization failures (403 Forbidden)
      def handle_unauthorized(exception)
        Rails.logger.warn "Unauthorized access attempt: #{exception.message}"
        render_error("You are not authorized to perform this action", status: :forbidden)
      end

      # Handle ActiveRecord not found errors (404 Not Found)
      def handle_not_found(exception)
        model_name = exception.model.constantize.model_name.human.downcase
        render_error("#{model_name} not found", status: :not_found)
      end

      # Handle ActiveRecord validation errors (422 Unprocessable Entity)
      def handle_record_invalid(exception)
        render_validation_errors(exception.record)
      end

      # Handle missing required parameters (400 Bad Request)
      def handle_parameter_missing(exception)
        render_error("Missing parameter: #{exception.param}", status: :bad_request)
      end

      # Handle invalid JWT tokens (401 Unauthorized)
      def handle_jwt_error(exception)
        render_error("Invalid authentication token", status: :unauthorized)
      end

      # Handle expired JWT tokens (401 Unauthorized)
      def handle_jwt_expired(exception)
        render_error("Authentication token has expired", status: :unauthorized)
      end
    end
  end
end
