require 'rails_helper'

RSpec.describe 'Api::V1::Sessions', type: :request do
  let(:user) { create(:user, email: 'user@example.com', password: 'password123') }
  let(:admin) { create(:user, :admin, email: 'admin@example.com', password: 'password123') }

  describe 'POST /api/v1/sign_in' do
    context 'with valid credentials' do
      it 'returns user data and token for regular user' do
        post '/api/v1/sign_in', params: {
          user: { email: user.email, password: 'password123' }
        }

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']['user']['email']).to eq(user.email)
        expect(json_response['data']['token']).to be_present
        expect(json_response['data']['redirect_to']).to eq('/profile')
      end

      it 'returns admin redirect for admin user' do
        post '/api/v1/sign_in', params: {
          user: { email: admin.email, password: 'password123' }
        }

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']['redirect_to']).to eq('/admin/dashboard')
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized error' do
        post '/api/v1/sign_in', params: {
          user: { email: user.email, password: 'wrong_password' }
        }

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']['message']).to eq('Invalid email or password')
      end
    end
  end

  describe 'DELETE /api/v1/sign_out' do
    let(:user) { create(:user) }
    let(:token) { user.generate_jwt }

    it 'returns no content' do
      delete '/api/v1/sign_out',
             headers: { 'Authorization' => token }

      expect(response).to have_http_status(:no_content)
    end
  end
end
