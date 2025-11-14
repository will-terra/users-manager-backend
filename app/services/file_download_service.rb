# Service to download files from a URL and store them in a temporary file
# Returns a hash with the file IO, filename, and content type
class FileDownloadService
  def initialize(url)
    @url = url
  end

  # Downloads the file from the URL and returns a hash with file details
  # Returns nil if URL is blank or download fails
  def call
    return nil unless @url.present?

    begin
      uri = URI.parse(@url)
      response = Net::HTTP.get_response(uri)

      # Process successful HTTP responses
      if response.is_a?(Net::HTTPSuccess)
        # Create a temporary file to store the downloaded content
        tempfile = Tempfile.new([ "download", File.extname(uri.path) ])
        tempfile.binmode
        tempfile.write(response.body)
        tempfile.rewind

        # Return hash with file details for ActiveStorage attachment
        {
          io: tempfile,
          filename: File.basename(uri.path),
          content_type: response.content_type
        }
      else
        raise "HTTP Error: #{response.code}"
      end
    rescue => e
      # Log error and return nil on failure
      Rails.logger.error "Error downloading file from URL: #{e.message}"
      nil
    end
  end
end
