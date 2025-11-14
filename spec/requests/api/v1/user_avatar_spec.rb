require 'rails_helper'

RSpec.describe 'User Avatar API', type: :request do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }
  let(:user_token) { user.generate_jwt }
  let(:admin_token) { admin.generate_jwt }

  describe 'PATCH /api/v1/users/:id' do
    it 'allows avatar file upload' do
      file = fixture_file_upload('spec/fixtures/files/avatar.png', 'image/png')

      patch "/api/v1/users/#{user.id}",
            params: { user: { avatar: file } },
            headers: { 'Authorization' => user_token }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['data']['attributes']['has_avatar']).to be true
      expect(json_response['data']['attributes']['avatar_urls']).to be_present
    end

    it 'allows avatar URL' do
      patch "/api/v1/users/#{user.id}",
            params: { user: { avatar_url: 'https://example.com/avatar.jpg' } },
            headers: { 'Authorization' => user_token }

      expect(response).to have_http_status(:ok)
    end

    it 'allows avatar removal' do
      # Primeiro, adicionar um avatar
      user.avatar.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'avatar.png')),
        filename: 'avatar.png',
        content_type: 'image/png'
      )
      user.save!

      patch "/api/v1/users/#{user.id}",
            params: { user: { remove_avatar: '1' } },
            headers: { 'Authorization' => user_token }

      expect(response).to have_http_status(:ok)
      user.reload
      expect(user.avatar).not_to be_attached
    end
  end

  describe 'Admin avatar operations' do
    it 'admin can update user avatar' do
      file = fixture_file_upload('spec/fixtures/files/avatar.png', 'image/png')

      patch "/api/v1/admin/users/#{user.id}",
            params: { user: { avatar: file } },
            headers: { 'Authorization' => admin_token }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['data']['has_avatar']).to be true
    end
  end
end
