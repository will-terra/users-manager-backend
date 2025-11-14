# Service object to download an avatar image from a remote URL and
# attach it to a user's ActiveStorage `avatar` attachment.
#
# Usage:
# AvatarFromUrlService.new(user, url).call
#
# Notes / behavior:
# - If `url` is blank, the service is a no-op.
# - The remote resource is fetched via Net::HTTP. Only successful
#   HTTP responses (2xx) will be written and attached.
# - Validates URL scheme, file extension, content type, and file size.
# - Any exception during download/attach is caught, logged, and added
#   to user errors. The service does not raise so callers can use it
#   safely in background jobs or controllers.
class AvatarFromUrlService
  class AvatarDownloadError < StandardError; end

  # Initialize with the user (model instance that responds to `avatar`)
  # and the remote URL to download (string).
  def initialize(user, url)
    @user = user
    @url = url
  end

  # Perform the download and attach. Returns truthy when attachment
  # happened (response was successful), otherwise false.
  def call
    return if @url.blank?

    begin
      uri = URI.parse(@url)

      # Validate URL
      validate_url(uri)

      # Download file
      file_data = download_file(uri)

      # Validate file
      validate_file(file_data)

      # Attach to user
      attach_file(file_data)

    rescue => e
      Rails.logger.error "AvatarFromUrlService Error: #{e.message}"
      @user.errors.add(:avatar_url, "could not be processed: #{e.message}")
      false
    end
  end

  private

  def validate_url(uri)
    unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      raise AvatarDownloadError, "Invalid URL scheme"
    end

    # Check if it's an image URL
    unless uri.path.downcase.match?(/\.(jpg|jpeg|png|gif|webp)$/i)
      raise AvatarDownloadError, "URL must point to an image file (JPG, PNG, GIF, WebP)"
    end
  end

  def download_file(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 10
    http.read_timeout = 10

    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = "UserManager App"

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise AvatarDownloadError, "HTTP Error: #{response.code} #{response.message}"
    end

    content_type = response.content_type
    unless content_type.start_with?("image/")
      raise AvatarDownloadError, "Content is not an image: #{content_type}"
    end

    {
      io: StringIO.new(response.body),
      filename: File.basename(uri.path) || "avatar#{File.extname(uri.path) || '.jpg'}",
      content_type: content_type
    }
  end

  def validate_file(file_data)
    # Check file size
    file_data[:io].rewind
    content = file_data[:io].read
    file_data[:io].rewind

    if content.bytesize > 5.megabytes
      raise AvatarDownloadError, "Image is too large (max 5MB)"
    end

    # Check if it's really an image
    unless file_data[:content_type].start_with?("image/")
      raise AvatarDownloadError, "File is not a valid image"
    end
  end

  def attach_file(file_data)
    @user.avatar.attach(
      io: file_data[:io],
      filename: file_data[:filename],
      content_type: file_data[:content_type]
    )
  end
end
