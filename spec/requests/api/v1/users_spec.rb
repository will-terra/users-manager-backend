require 'rails_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }
  let(:token) { user.generate_jwt }
  let(:admin_token) { admin.generate_jwt }

  describe 'GET /api/v1/users/profile' do
    it 'returns current user profile' do
      get '/api/v1/users/profile',
          headers: { 'Authorization' => token }

      expect(response).to have_http_status(:ok)
  json_response = JSON.parse(response.body)
  expect(json_response['data']['email']).to eq(user.email)
    end
  end

  describe 'GET /api/v1/users' do
    before do
      create_list(:user, 3)
    end

    it 'returns forbidden for regular user' do
      get '/api/v1/users', headers: { 'Authorization' => token }
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns users for admin' do
      get '/api/v1/users', headers: { 'Authorization' => admin_token }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to have_key('data')
    end
  end

  describe 'PATCH /api/v1/users/:id/toggle_role' do
    let(:target_user) { create(:user) }

    context 'as admin' do
      it 'toggles user role' do
        patch "/api/v1/users/#{target_user.id}/toggle_role",
              headers: { 'Authorization' => admin_token }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['data']['attributes']['role']).to eq('admin')
      end
    end

    context 'as regular user' do
      it 'returns forbidden' do
        patch "/api/v1/users/#{target_user.id}/toggle_role",
              headers: { 'Authorization' => token }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'PATCH /api/v1/users/:id' do
    let(:target_user) { create(:user) }

    it 'returns validation errors for invalid update' do
      patch "/api/v1/users/#{target_user.id}",
            headers: { 'Authorization' => admin_token },
            params: { user: { email: 'invalid_email' } }

  expect(response).to have_http_status(:unprocessable_content)
  json = JSON.parse(response.body)
  expect(json['error']).to be_present
  expect(json['error']['details']).to be_present
    end

    it 'deletes user as admin' do
      delete "/api/v1/users/#{target_user.id}", headers: { 'Authorization' => admin_token }
      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'PATCH /api/v1/users/profile' do
    it 'updates current user profile' do
      patch '/api/v1/users/profile',
            headers: { 'Authorization' => token },
            params: { user: { full_name: 'Updated Name' } }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['data']['full_name']).to eq('Updated Name')
    end

    context 'password change' do
      it 'changes password with valid current password' do
        patch '/api/v1/users/profile',
              headers: { 'Authorization' => token },
              params: {
                user: {
                  current_password: 'password123',
                  password: 'newpassword123',
                  password_confirmation: 'newpassword123'
                }
              }

        expect(response).to have_http_status(:ok)
        
        # Verify user can login with new password
        user.reload
        expect(user.valid_password?('newpassword123')).to be true
      end

      it 'rejects password change without current password' do
        patch '/api/v1/users/profile',
              headers: { 'Authorization' => token },
              params: {
                user: {
                  password: 'newpassword123',
                  password_confirmation: 'newpassword123'
                }
              }

        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include('Current password is required to change password')
      end

      it 'rejects password change with incorrect current password' do
        patch '/api/v1/users/profile',
              headers: { 'Authorization' => token },
              params: {
                user: {
                  current_password: 'wrongpassword',
                  password: 'newpassword123',
                  password_confirmation: 'newpassword123'
                }
              }

        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include('Current password is incorrect')
      end

      it 'rejects password change without confirmation' do
        patch '/api/v1/users/profile',
              headers: { 'Authorization' => token },
              params: {
                user: {
                  current_password: 'password123',
                  password: 'newpassword123'
                }
              }

        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include('Password confirmation is required')
      end

      it 'allows profile update without changing password' do
        patch '/api/v1/users/profile',
              headers: { 'Authorization' => token },
              params: { user: { full_name: 'Updated Name' } }

        expect(response).to have_http_status(:ok)
        
        # Verify password unchanged
        user.reload
        expect(user.valid_password?('password123')).to be true
      end
    end
  end
end
