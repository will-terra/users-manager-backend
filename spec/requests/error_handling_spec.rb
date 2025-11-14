require 'rails_helper'

RSpec.describe 'Error Handling', type: :request do
  describe '404 Not Found' do
    it 'returns JSON error for unknown routes' do
      get '/api/v1/nonexistent'

      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be false
      expect(json_response['error']['code']).to eq(404)
      expect(json_response['error']['message']).to eq('Route not found')
    end

    it 'returns JSON error for unknown resources' do
      get '/api/v1/users/999999'

      expect(response).to have_http_status(:not_found)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be false
    end
  end

  describe '401 Unauthorized' do
    it 'returns error for missing token' do
      get '/api/v1/users/profile'

      expect(response).to have_http_status(:unauthorized)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Authentication token required')
    end

    it 'returns error for invalid token' do
      get '/api/v1/users/profile', headers: { 'Authorization' => 'invalid_token' }

      expect(response).to have_http_status(:unauthorized)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Invalid token')
    end
  end

  describe '403 Forbidden' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:user_token) { user.generate_jwt }

    it 'returns error for unauthorized resource access' do
      get "/api/v1/users/#{other_user.id}", headers: { 'Authorization' => user_token }

      expect(response).to have_http_status(:forbidden)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be false
      expect(json_response['error']['message']).to include('not authorized')
    end
  end

  describe '422 Unprocessable Entity' do
    let(:user) { create(:user) }
    let(:user_token) { user.generate_jwt }

    it 'returns validation errors for invalid updates' do
      patch "/api/v1/users/#{user.id}",
            params: { user: { email: 'invalid-email' } },
            headers: { 'Authorization' => user_token }

      expect(response).to have_http_status(:unprocessable_content)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be false
      expect(json_response['error']['details']).to be_present
    end
  end

  describe 'Parameter Missing' do
    it 'returns error for missing parameters' do
      post '/api/v1/sign_up', params: { user: {} }

      expect(response).to have_http_status(:bad_request)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be false
    end
  end
end
