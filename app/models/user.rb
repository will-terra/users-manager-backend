class User < ApplicationRecord
  # User model
  # - Handles authentication via Devise (including JWT handling)
  # - Stores a single attached avatar and supports downloading via an URL
  # - Tracks simple roles (admin, user) and broadcasts app-wide stats when
  #   user records change

  # Devise modules enabled for this app. jwt_revocation_strategy uses the
  # `JWTBlacklist` model to handle revoked tokens.
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable,
         :trackable, :jwt_authenticatable,
         jwt_revocation_strategy: JWTBlacklist

  # Supported roles for authorization checks
  ROLES = %w[admin user].freeze

  # Basic attribute validations
  validates :full_name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }
  validates :role, presence: true, inclusion: { in: ROLES }

  # Avatar handling
  AVATAR_EXTENSIONS = %w[.jpeg .png .gif .webp].freeze
  AVATAR_CONTENT_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze
  AVATAR_MAX_SIZE = 5.megabytes
  AVATAR_DIMENSIONS = { width: 500, height: 500 }.freeze

  attr_reader :avatar_url, :remove_avatar

  def avatar_url=(value)
    @avatar_url = value
    # If avatar_url is "null" or empty string, mark for removal
    if value.in?([ "null", "" ])
      @remove_avatar = "1"
    end
  end

  def remove_avatar=(value)
    @remove_avatar = value
  end

  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 100, 100 ]
    attachable.variant :medium, resize_to_fill: [ 300, 300 ]
    attachable.variant :large, resize_to_limit: [ 500, 500 ]
  end

  # Avatar callbacks
  before_save :process_avatar_url, if: -> { avatar_url.present? && !@processing_avatar_url }
  before_save :purge_avatar, if: -> { remove_avatar == "1" }

  # Broadcast stats updates whenever users change in ways the frontend cares
  # about (create, destroy, or role changes).
  after_create :broadcast_stats_update
  after_update :broadcast_stats_update, if: -> { saved_change_to_role? }
  after_destroy :broadcast_stats_update

  # Avatar validations
  validate :avatar_content_type
  validate :avatar_size

  # Only validate image dimensions when a new avatar is being attached or
  # when processing a remote avatar URL. Validating dimensions on every
  # save caused unrelated updates (e.g. changing name/email) to fail when an
  # already-attached avatar exceeded the configured limits.
  validate :avatar_dimensions, if: -> { avatar.attached? && avatar.blob.persisted? && should_validate_avatar_dimensions? }

  # Convenience scopes for querying by role
  scope :admins, -> { where(role: "admin") }
  scope :users, -> { where(role: "user") }

  # Keep import records for auditing even if a user is deleted. We nullify
  # the `user_id` on delete (DB-level ON DELETE SET NULL) and avoid removing
  # the imports automatically; this preserves history.
  has_many :user_imports, dependent: :nullify

  # Role predicate helpers used throughout the app/policies
  def admin?
    role == "admin"
  end

  def user?
    role == "user"
  end

  # Generate a simple JWT for the user. This duplicates Devise JWT behavior
  # in places where an explicit token is required (e.g. API responses).
  def generate_jwt
    JWT.encode(
      {
        id: id,
        exp: 15.minutes.from_now.to_i,
        email: email,
        role: role,
        full_name: full_name,
        jti: SecureRandom.uuid
      },
      Rails.application.credentials.devise_jwt_secret_key
    )
  end

  # Devise JWT callback - called when a JWT is dispatched (user signs in)
  # This allows us to track or modify the JWT payload if needed
  def on_jwt_dispatch(token, payload)
    # No additional action needed for now, but this callback must exist
  end

  # Public methods for avatar URLs
  def avatar_thumb_url
    avatar_variant_url(:thumb)
  end

  def avatar_medium_url
    avatar_variant_url(:medium)
  end

  def avatar_large_url
    avatar_variant_url(:large)
  end

  def avatar_original_url
    return unless avatar.attached?
    Rails.application.routes.url_helpers.rails_blob_url(avatar, only_path: true)
  end

  private

  def process_avatar_url
    return if avatar_url.blank?

    # If avatar_url is "null" or empty string, it's already marked for removal
    return if avatar_url.in?([ "null", "" ])

    # Set flag to prevent re-entry
    @processing_avatar_url = true

    begin
      # Download and attach avatar from URL
      AvatarFromUrlService.new(self, avatar_url).call
    ensure
      # Clear avatar_url to prevent reprocessing on next save
      @avatar_url = nil
      @processing_avatar_url = false
    end
  end

  def purge_avatar
    avatar.purge_later
  end

  # Validate avatar MIME type
  def avatar_content_type
    return unless avatar.attached?

    unless avatar.content_type.in?(AVATAR_CONTENT_TYPES)
      # Match spec expectation: space-separated extensions (no commas)
      errors.add(:avatar, "must be one of: #{AVATAR_EXTENSIONS.join(' ')}")
    end
  end

  # Validate avatar file size (limit to 5 MB)
  def avatar_size
    return unless avatar.attached?

    if avatar.blob.byte_size > AVATAR_MAX_SIZE
      errors.add(:avatar, "must be less than #{AVATAR_MAX_SIZE / 1.megabyte}MB")
    end
  end

  def avatar_dimensions
    return unless avatar.attached?

    # Check dimensions only if it's an image
    if avatar.image?
      metadata = avatar.blob.metadata
      width = metadata[:width]
      height = metadata[:height]

      if width.present? && height.present?
        max_width = AVATAR_DIMENSIONS[:width]
        max_height = AVATAR_DIMENSIONS[:height]

        if width > max_width || height > max_height
          errors.add(:avatar, "must be smaller than #{max_width}x#{max_height} pixels")
        end
      end
    end
  end

  def avatar_variant_url(variant_name)
    return unless avatar.attached?

    begin
      variant = avatar.variant(variant_name)
      Rails.application.routes.url_helpers.rails_blob_url(variant, only_path: true)
    rescue ActiveStorage::InvariableError
      # If image doesn't support variants, return original
      avatar_original_url
    end
  end

  # Determine whether to run the avatar dimensions validation. We only want
  # to run this when an avatar is being changed in the current request
  # (file upload via params or processing a supplied avatar_url). Controllers
  # set @avatar_being_updated = true when they detect avatar/avatar_url in
  # the incoming params. @processing_avatar_url is set during processing of
  # the URL. This keeps dimension validation scoped to avatar updates.
  def should_validate_avatar_dimensions?
    return true if defined?(@processing_avatar_url) && @processing_avatar_url
    defined?(@avatar_being_updated) && @avatar_being_updated
  end

  # Queue a job to broadcast updated user stats to admin dashboards/clients
  def broadcast_stats_update
    StatsBroadcastJob.perform_later
  end
end
