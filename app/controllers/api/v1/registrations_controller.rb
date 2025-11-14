module Api
  module V1
    # Controller responsible for handling user registration/sign-up requests
    # Inherits from BaseController to leverage common API functionality
    class RegistrationsController < BaseController
      # Skip authentication for the create action since users registering don't have tokens yet
      skip_before_action :authenticate_user_from_token!, only: [ :create ]

      # Skip Pundit authorization checks for this controller
      # Registration is a public endpoint that doesn't require authorization policies
      before_action :pundit_skip!

      # POST /api/v1/registrations
      # Creates a new user account and returns user data with authentication token
      def create
        # Initialize a new user with the permitted registration parameters
        user = User.new(registration_params)

        # Assign role: first user becomes admin, all subsequent users are regular users
        # This ensures the system always has at least one admin account
        user.role = User.exists? ? "user" : "admin"

          # Attempt to save the user to the database (triggers validations)
          if user.save
            # Generate a JWT authentication token for the newly created user
            token = user.generate_jwt

            # Return success response with user data and token
            # Note: Data is duplicated in both nested 'data' object and root level
            # for backwards compatibility or different client requirements
            render json: {
              success: true,
              data: {
                user: user_serialized(user),
                token: token,
                redirect_to: "/profile"
              },
              user: user_serialized(user),
              token: token,
              redirect_to: "/profile"
            },
            status: :created
          else
            # Return error response if validation fails
            # Includes validation error messages to help user correct their input
            render json: {
              success: false,
              error: {
                code: :unprocessable_content,
                message: "Validation failed",
                details: user.errors.full_messages
              },
              errors: user.errors.full_messages
            },
            status: :unprocessable_content
          end
      end

      private

      # Strong parameters method to whitelist allowed user registration attributes
      # Prevents mass assignment vulnerabilities by only permitting specific fields
      # @return [ActionController::Parameters] permitted parameters for user creation
      def registration_params
        params.require(:user).permit(:full_name, :email, :password, :password_confirmation)
      end

      # Serialize user data for the response
      # Converts the User model into a JSON-friendly hash using UserSerializer
      # Extracts the attributes from the serializer's nested structure
      # @param user [User] the user object to serialize
      # @return [Hash] serialized user attributes
      def user_serialized(user)
        UserSerializer.new(user).serializable_hash[:data][:attributes]
      end

      # Choose a redirect path based on user role. Mirrors SessionsController.
      # Admin users are redirected to the admin dashboard, regular users to their profile
      # Note: This method is defined but not currently used in the create action
      # @param user [User] the user object to determine redirect for
      # @return [String] the path to redirect to
      def redirect_path(user)
        user.admin? ? "/admin/dashboard" : "/profile"
      end
    end
  end
end
