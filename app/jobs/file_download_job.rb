# Background job to download a file from a URL and attach it to a UserImport record
# After successful download, triggers UserImportJob to process the file
class FileDownloadJob < ApplicationJob
  queue_as :default

  def perform(user_import_id, file_url)
    user_import = UserImport.find(user_import_id)

    begin
      # Download file using FileDownloadService
      file_data = FileDownloadService.new(file_url).call

      if file_data
        # Attach downloaded file to the UserImport record
        user_import.file.attach(
          io: file_data[:io],
          filename: file_data[:filename],
          content_type: file_data[:content_type]
        )

        user_import.save!
        # Trigger processing job after successful attachment
        UserImportJob.perform_later(user_import.id)
      else
        user_import.mark_as_failed(StandardError.new("Failed to download file from URL"))
      end
    rescue => e
      # Mark import as failed if any error occurs
      user_import.mark_as_failed(e)
    end
  end
end
