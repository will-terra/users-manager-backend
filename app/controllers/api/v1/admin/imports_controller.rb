module Api
  module V1
    module Admin
      # Controller to manage user import operations (CSV/file uploads)
      # Restricted to admin users only
      class ImportsController < BaseController
        before_action :authorize_admin

        # GET /api/v1/admin/imports
        # Returns paginated list of all user imports
        def index
          imports = policy_scope(UserImport).order(created_at: :desc).page(params[:page]).per(20)

          render json: {
            imports: UserImportSerializer.new(imports).serializable_hash,
            pagination: pagination_meta(imports)
          }
        end

        # GET /api/v1/admin/imports/:id
        # Returns details of a specific import
        def show
          import = UserImport.find(params[:id])
          render json: UserImportSerializer.new(import).serializable_hash
        end

        # POST /api/v1/admin/imports
        # Creates a new user import and triggers processing job
        # Accepts either a file upload or file_url parameter
        def create
          file_url = params.dig(:import, :file_url)
          user_import = UserImport.new(import_params.except(:file_url))
          user_import.user = current_user

          # Skip file validation if we're downloading from URL
          user_import.skip_file_validation = file_url.present?

          if user_import.save
            if file_url.present?
              download_and_process_file(user_import, file_url)
            else
              UserImportJob.perform_later(user_import.id)
            end

            render json: UserImportSerializer.new(user_import).serializable_hash, status: :created
          else
            render json: { errors: user_import.errors.full_messages }, status: :unprocessable_content
          end
        end

        private

        # Verify current user has admin privileges
        def authorize_admin
          begin
            authorize User, :admin?
          rescue Pundit::NotAuthorizedError
            head :forbidden
          end
        end

        # Strong parameters for import creation
        def import_params
          params.require(:import).permit(:file, :file_url)
        end

        # Queue background job to download file from URL and process it
        def download_and_process_file(user_import, file_url)
          FileDownloadJob.perform_later(user_import.id, file_url)
        end

        # Build pagination metadata for index response
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
