class AvatarProcessingJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user&.avatar&.attached?

    begin
      # Analyze the image to obtain metadata
      user.avatar.blob.analyze

      # Optimize the image
      ImageOptimizationService.optimize_avatar(user.avatar.blob)

      # Process variants
      process_variants(user)

    rescue => e
      Rails.logger.error "AvatarProcessingJob failed for user #{user_id}: #{e.message}"
    end
  end

  private

  def process_variants(user)
    # Pre-process variants for better performance
    user.avatar.variant(:thumb).processed
    user.avatar.variant(:medium).processed
    user.avatar.variant(:large).processed
  end
end
