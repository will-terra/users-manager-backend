module Api
  module V1
    # Controller for managing users via the JSON API.
    #
    # Responsibilities:
    # - List, show, update and destroy users (actions protected by Pundit)
    # - Provide a `profile` endpoint that returns the current user's data
    # - Allow role toggling via `toggle_role` (authorization checked separately)
    class UsersController < BaseController
      # Load the target user for actions that operate on a specific record
      before_action :set_user, only: [ :show, :update, :destroy, :toggle_role ]

      # Ensure user is authenticated before accessing any action
      before_action :require_authentication!

      # GET /api/v1/users
      # Requires authorization; returns a collection scoped by Pundit policies
      def index
        authorize User
        users = policy_scope(User)
        render json: UserSerializer.new(users).serializable_hash
      end

      # GET /api/v1/users/:id
      # Returns a single user (authorization enforced)
      def show
        authorize @user
        render json: UserSerializer.new(@user).serializable_hash
      end

      # GET /api/v1/users/profile
      # Convenience endpoint that returns the currently authenticated user's data
      def profile
        # This action requires authentication (already enforced by before_action)
        # Authorize using UserPolicy#profile? which always returns true for authenticated users
        authorize current_user, :profile?
        render json: { data: UserSerializer.new(current_user).serializable_hash[:data][:attributes] }
      end

      # PATCH/PUT /api/v1/users/:id
      # Updates attributes permitted by `user_params`. Authorization is enforced.
      def update
        authorize @user
        # Mark the user when an avatar payload is present so model validations
        # that check avatar dimensions only run when a new avatar is being
        # attached or when a remote URL is being processed. This prevents
        # unrelated updates (e.g. changing full_name) from failing due to an
        # existing avatar that might violate dimension rules.
        if params.dig(:user, :avatar).present? || params.dig(:user, :avatar_url).present?
          @user.instance_variable_set(:@avatar_being_updated, true)
        end

        if @user.update(user_params)
          render json: UserSerializer.new(@user).serializable_hash
        else
          render_validation_errors(@user)
        end
      end

      # PATCH /api/v1/users/profile
      # Updates the currently authenticated user's profile. Mirrors the
      # behaviour of `update` but operates on `current_user` instead of
      # expecting an :id path parameter. This endpoint is used by the
      # frontend when a client wants to update the signed-in user's own
      # profile (including uploading an avatar file).
      def profile_update
        authorize current_user, :update?
        if params.dig(:user, :avatar).present? || params.dig(:user, :avatar_url).present?
          current_user.instance_variable_set(:@avatar_being_updated, true)
        end

        # Handle password update validation
        update_params = user_params
        if update_params[:password].present?
          # Require password confirmation first
          unless update_params[:password_confirmation].present?
            return render json: { errors: ["Password confirmation is required"] }, status: :unprocessable_entity
          end

          # Require current password for security
          unless params.dig(:user, :current_password).present?
            return render json: { errors: ["Current password is required to change password"] }, status: :unprocessable_entity
          end

          # Verify current password
          unless current_user.valid_password?(params.dig(:user, :current_password))
            return render json: { errors: ["Current password is incorrect"] }, status: :unprocessable_entity
          end
        else
          # Remove password fields if password is blank (not updating password)
          update_params.delete(:password)
          update_params.delete(:password_confirmation)
        end

        if current_user.update(update_params)
          render json: { data: UserSerializer.new(current_user).serializable_hash[:data][:attributes] }
        else
          render_validation_errors(current_user)
        end
      end

      # DELETE /api/v1/users/:id
      # Destroys the user record. Controllers should ensure only authorized
      # actors (e.g., admins or the user themself) can perform this action.
      def destroy
        authorize @user
        @user.destroy
        head :no_content
      end

      # PATCH /api/v1/users/:id/toggle_role
      # Toggles between 'admin' and 'user' roles for the target user. This
      # action invokes a Pundit check for `toggle_role?` to ensure only
      # permitted actors can change roles.
      def toggle_role
        authorize @user, :toggle_role?
        new_role = @user.admin? ? "user" : "admin"
        if @user.update(role: new_role)
          render json: UserSerializer.new(@user).serializable_hash
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_content
        end
      end

      private

      # Find and assign the user for member actions
      def set_user
        @user = User.find(params[:id])
      end

      # Strong parameters for updates. Only allow attributes that should be
      # mutable by API clients. `avatar` expects an uploaded file; `avatar_url`
      # can be used by clients to point to remote avatars if supported.
      # `remove_avatar` can be set to '1' to remove the user's avatar.
      # Password fields are permitted for profile updates (current_password handled separately)
      def user_params
        params.require(:user).permit(:full_name, :email, :avatar, :avatar_url, :remove_avatar, :password, :password_confirmation)
      end
    end
  end
end
