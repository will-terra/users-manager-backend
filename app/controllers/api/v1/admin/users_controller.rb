module Api
  module V1
    module Admin
      # Admin controller for managing users in the system
      # Provides CRUD operations and role management functionality
      # Requires admin authorization for all actions
      class UsersController < ApplicationController
        before_action :set_user, only: [ :show, :update, :destroy, :toggle_role ]

        # GET /api/v1/admin/users
        # Lists all users with pagination
        # Returns overview statistics when overview=true parameter is present
        def index
          authorize User

          users = policy_scope(User)
          users = UserSearchService.new(users, params).call
          users = users.order(created_at: :desc)
                       .page(params[:page])
                       .per(params[:per_page] || 20)

          if params[:overview] == "true"
            render_overview(users)
          else
            # JSON:API serializer returns a nested shape ({ data: [ { id, attributes } ] })
            # Convert to a flat array of attribute hashes with id included so the
            # frontend can consume a consistent, simple shape:
            # { users: [ { id, full_name, ... }, ... ], pagination: { ... } }
            serialized = UserSerializer.new(users).serializable_hash
            flat_users = Array(serialized[:data]).map do |resource|
              attrs = resource[:attributes] || {}
              attrs.merge(id: resource[:id].to_i)
            end

            render json: {
              data: {
                users: flat_users,
                pagination: pagination_meta(users)
              }
            }
          end
        end

        # GET /api/v1/admin/users/:id
        # Returns details for a specific user
        def show
          authorize @user
          # Return a flat user object under `data` so the frontend receives
          # { data: { id: ..., full_name: ..., email: ... } }
          serialized = UserSerializer.new(@user).serializable_hash
          resource = serialized[:data] || {}
          attrs = (resource[:attributes] || {}).merge(id: resource[:id]&.to_i)
          render json: { data: attrs }
        end

        # POST /api/v1/admin/users
        # Creates a new user (password is required)
        def create
          authorize User

          # Require password to be explicitly provided
          if admin_user_params[:password].blank?
            return render json: { errors: [ "Password is required" ] }, status: :unprocessable_content
          end

          # Build user from safe params
          user = User.new(admin_user_params)

          # If the request included an avatar payload, mark the model so
          # avatar-specific validations run only when appropriate.
          if params.dig(:user, :avatar).present? || params.dig(:user, :avatar_url).present?
            user.instance_variable_set(:@avatar_being_updated, true)
          end

          # Handle role explicitly (avoid permitting it through strong params —
          # prevents mass-assignment warnings). Only set role if the caller
          # passed it and the current request is authorized (admins only).
          if params.dig(:user, :role).present?
            user.role = params.dig(:user, :role)
          end

          if user.save
            # UserMailer.with(user: user, temp_password: user.password).welcome_email.deliver_later
            serialized = UserSerializer.new(user).serializable_hash
            resource = serialized[:data] || {}
            attrs = (resource[:attributes] || {}).merge(id: resource[:id]&.to_i)
            render json: { data: attrs }, status: :created
          else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_content
          end
        end

        # PATCH/PUT /api/v1/admin/users/:id
        # Updates user information (password is optional)
        def update
          authorize @user

          # Ensure avatar validations run when an avatar payload is present
          if params.dig(:user, :avatar).present? || params.dig(:user, :avatar_url).present?
            @user.instance_variable_set(:@avatar_being_updated, true)
          end

          # Remove password fields if blank
          if admin_user_params[:password].blank?
            admin_user_params.delete(:password)
            admin_user_params.delete(:password_confirmation)
          end

          # Note: role is intentionally not permitted via strong params here.
          # Use the dedicated `toggle_role` endpoint to change roles to reduce
          # risk and satisfy
          if @user.update(admin_user_params)
            serialized = UserSerializer.new(@user).serializable_hash
            resource = serialized[:data] || {}
            attrs = (resource[:attributes] || {}).merge(id: resource[:id]&.to_i)
            render json: { data: attrs }
          else
            render json: { errors: @user.errors.full_messages }, status: :unprocessable_content
          end
        end

        # DELETE /api/v1/admin/users/:id
        # Deletes a user (admins cannot delete themselves)
        def destroy
          authorize @user

          # Prevent admin from deleting themselves
          if @user == current_user
            render json: { errors: [ "You cannot delete your own account" ] }, status: :unprocessable_content
          else
            begin
              @user.destroy
              head :no_content
            rescue ActiveRecord::InvalidForeignKey => e
              # Return a helpful error instead of letting the 500 bubble up.
              # This typically means other records reference this user (FK
              # constraint). Advise the client/admin what to do next.
              Rails.logger.warn("Failed to delete user=#{@user.id}: #{e.message}")
              render json: {
                errors: [
                  "Cannot delete user because related records exist (e.g. user_imports). Remove or reassign dependent records before deleting."
                ]
              }, status: :conflict
            end
          end
        end

        # PATCH /api/v1/admin/users/:id/toggle_role
        # Toggles user role between 'admin' and 'user'
        def toggle_role
          authorize @user, :toggle_role?

          new_role = @user.admin? ? "user" : "admin"
          if @user.update(role: new_role)
            serialized = UserSerializer.new(@user).serializable_hash
            resource = serialized[:data] || {}
            attrs = (resource[:attributes] || {}).merge(id: resource[:id]&.to_i)
            render json: { data: attrs }
          else
            render json: { errors: @user.errors.full_messages }, status: :unprocessable_content
          end
        end

        private

        # Finds and sets the user from the :id parameter
        def set_user
          @user = User.find(params[:id])
        end

        # Strong parameters for user creation/update
        # Note: we intentionally do NOT permit `:role` here to avoid allowing
        # clients to mass-assign roles. Role changes should be performed via
        # the `toggle_role` action (or other explicit server-side flows).
        def admin_user_params
          params.require(:user).permit(
            :full_name, :email, :password, :password_confirmation,
            :avatar, :avatar_url, :remove_avatar
          )
        end

        # Renders user statistics overview (total users, admins, recent signups, etc.)
        def render_overview(users = policy_scope(User))
          overview = {
            total_users: users.count,
            admin_count: users.admins.count,
            user_count: users.users.count,
            recent_signups: users.where("created_at >= ?", 7.days.ago).count,
            active_today: users.where("last_sign_in_at >= ?", 1.day.ago).count
          }

          render json: { overview: overview }
        end

        # Generates pagination metadata for paginated collections
        def pagination_meta(collection)
          {
            current_page: collection.current_page,
            next_page: collection.next_page,
            prev_page: collection.prev_page,
            total_pages: collection.total_pages,
            total_count: collection.total_count,
            per_page: collection.limit_value
          }
        end
      end
    end
  end
end
