require 'rails_helper'

RSpec.describe 'Api::V1::Registrations', type: :request do
  describe 'POST /api/v1/sign_up' do
    context 'with valid parameters' do
      let(:valid_attributes) do
        {
          user: {
            full_name: 'John Doe',
            email: 'john@example.com',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }
      end

      it 'creates a new user' do
        expect {
          post '/api/v1/sign_up', params: valid_attributes
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['user']['email']).to eq('john@example.com')
        expect(json_response['user']['role']).to eq('admin')
        expect(json_response['token']).to be_present
        expect(json_response['redirect_to']).to eq('/profile')
      end

      it 'creates subsequent users as regular users' do
        # Create the first user (admin)
        create(:user, :admin)

        expect {
          post '/api/v1/sign_up', params: valid_attributes
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['user']['email']).to eq('john@example.com')
        expect(json_response['user']['role']).to eq('user')
        expect(json_response['token']).to be_present
        expect(json_response['redirect_to']).to eq('/profile')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) do
        {
          user: {
            full_name: '',
            email: 'invalid_email',
            password: 'short',
            password_confirmation: 'mismatch'
          }
        }
      end

      it 'does not create user and returns errors' do
        expect {
          post '/api/v1/sign_up', params: invalid_attributes
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to be_present
      end
    end
  end
end
