class UserSerializer
  include JSONAPI::Serializer

  # Public attributes returned to the API consumer. Keep this list minimal
  # — include only the fields the frontend needs to render a user or make
  # authorization decisions.
  attributes :id, :full_name, :email, :role, :created_at, :updated_at

  # Returns URLs to the user's avatar in different sizes if one is attached.
  # The helper uses `only_path: true` so the frontend can prepend a hostname
  # if necessary (useful in different environments). If no avatar is attached
  # this attribute will be nil and omitted from the JSON output.
  attribute :avatar_urls do |user|
    if user.avatar.attached?
      {
        thumb: user.avatar_thumb_url,
        medium: user.avatar_medium_url,
        large: user.avatar_large_url,
        original: user.avatar_original_url
      }
    end
  end

  # Boolean attribute indicating whether the user has an avatar attached
  attribute :has_avatar do |user|
    user.avatar.attached?
  end
end
