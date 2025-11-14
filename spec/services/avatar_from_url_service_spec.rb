require 'rails_helper'
require 'webmock/rspec'

RSpec.describe AvatarFromUrlService, type: :service do
  let(:user) { create(:user) }
  let(:valid_image_url) { 'https://example.com/avatar.jpg' }
  let(:invalid_url) { 'not-a-url' }
  let(:non_image_url) { 'https://example.com/document.pdf' }

  before do
    # Stub para requisições HTTP
    stub_request(:get, valid_image_url)
      .to_return(
        status: 200,
        body: File.read(Rails.root.join('spec', 'fixtures', 'files', 'avatar.png')),
        headers: { 'Content-Type' => 'image/jpeg' }
      )

    stub_request(:get, non_image_url)
      .to_return(
        status: 200,
        body: 'PDF content',
        headers: { 'Content-Type' => 'application/pdf' }
      )
  end

  describe '#call' do
    it 'successfully downloads and attaches avatar from valid URL' do
      service = AvatarFromUrlService.new(user, valid_image_url)

      expect(service.call).to be_truthy
      expect(user.avatar).to be_attached
    end

    it 'returns false for invalid URL' do
      service = AvatarFromUrlService.new(user, invalid_url)

      expect(service.call).to be_falsey
      expect(user.errors[:avatar_url]).to be_present
    end

    it 'returns false for non-image URL' do
      service = AvatarFromUrlService.new(user, non_image_url)

      expect(service.call).to be_falsey
      expect(user.errors[:avatar_url]).to be_present
    end

    it 'handles HTTP errors gracefully' do
      stub_request(:get, valid_image_url).to_return(status: 404)

      service = AvatarFromUrlService.new(user, valid_image_url)
      expect(service.call).to be_falsey
    end
  end
end
