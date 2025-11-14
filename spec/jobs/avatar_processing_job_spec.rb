require 'rails_helper'

RSpec.describe AvatarProcessingJob, type: :job do
  it 'does nothing when user not found or no avatar' do
    allow(User).to receive(:find_by).and_return(nil)
    expect { described_class.perform_now(123) }.not_to raise_error
  end

  it 'processes avatar when present' do
    blob = double('blob', analyze: true)
    avatar = double('avatar', attached?: true, blob: blob, variant: double(processed: true))
    user = double('user', id: 1, avatar: avatar)
    allow(User).to receive(:find_by).with(id: 1).and_return(user)
    expect(ImageOptimizationService).to receive(:optimize_avatar).with(blob)
    described_class.perform_now(1)
  end
end
