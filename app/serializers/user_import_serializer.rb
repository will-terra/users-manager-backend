# Serializer for UserImport records using JSONAPI format
# Exposes import status, progress tracking, and file information
class UserImportSerializer
  include JSONAPI::Serializer

  attributes :id, :status, :progress, :total_rows, :error_message, :created_at, :updated_at

  # Calculate completion percentage
  attribute :percentage do |import|
    import.percentage
  end

  # Extract attached file name
  attribute :file_name do |import|
    import.file.filename.to_s if import.file.attached?
  end

  # Generate URL for accessing the attached file
  attribute :file_url do |import|
    Rails.application.routes.url_helpers.rails_blob_url(import.file, only_path: true) if import.file.attached?
  end

  belongs_to :user
end
