require 'rails_helper'

RSpec.describe 'User Avatar Handling', type: :model do
  let(:user) { build(:user) }

  describe 'avatar validations' do
    it 'accepts valid image types' do
      user.avatar.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'avatar.png')),
        filename: 'avatar.png',
        content_type: 'image/png'
      )
      expect(user).to be_valid
    end

    it 'rejects invalid file types' do
      user.avatar.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'test.txt')),
        filename: 'test.txt',
        content_type: 'text/plain'
      )
      expect(user).not_to be_valid
      expect(user.errors[:avatar]).to include('must be one of: .jpeg .png .gif .webp')
    end

    it 'rejects files that are too large' do
      allow_any_instance_of(ActiveStorage::Blob).to receive(:byte_size).and_return(6.megabytes)

      user.avatar.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'avatar.png')),
        filename: 'avatar.png',
        content_type: 'image/png'
      )

      expect(user).not_to be_valid
      expect(user.errors[:avatar]).to include('must be less than 5MB')
    end
  end

  describe 'avatar URL processing' do
    it 'processes valid avatar URL' do
      user.avatar_url = 'https://example.com/avatar.jpg'
      expect(user).to be_valid
    end

    it 'removes avatar when avatar_url is null' do
      user.avatar_url = 'null'
      expect(user.remove_avatar).to eq('1')
    end

    it 'removes avatar when avatar_url is empty' do
      user.avatar_url = ''
      expect(user.remove_avatar).to eq('1')
    end
  end

  describe 'avatar variants' do
    before do
      user.avatar.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'avatar.png')),
        filename: 'avatar.png',
        content_type: 'image/png'
      )
      user.save!
    end

    it 'generates thumb variant URL' do
      expect(user.avatar_thumb_url).to be_present
    end

    it 'generates medium variant URL' do
      expect(user.avatar_medium_url).to be_present
    end

    it 'generates large variant URL' do
      expect(user.avatar_large_url).to be_present
    end

    it 'generates original URL' do
      expect(user.avatar_original_url).to be_present
    end
  end
end
