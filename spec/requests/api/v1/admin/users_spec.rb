require 'rails_helper'

RSpec.describe 'Api::V1::Admin::Users', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:admin_token) { admin.generate_jwt }
  let(:user_token) { regular_user.generate_jwt }

  describe 'GET /api/v1/admin/users' do
    let!(:users) { create_list(:user, 15) }
    let!(:admins) { create_list(:user, 3, :admin) }

    context 'as admin' do
      it 'returns paginated users' do
        get '/api/v1/admin/users',
            headers: { 'Authorization' => admin_token }

  expect(response).to have_http_status(:ok)
  json_response = JSON.parse(response.body)
  expect(json_response['data']['users'].count).to eq(19) # 15 users + 3 admins + 1 admin making request
  expect(json_response['data']['pagination']).to be_present
  expect(json_response['data']['pagination']['total_count']).to eq(19) # 15 users + 3 admins + 1 admin making request
      end

      it 'returns overview when overview=true' do
        get '/api/v1/admin/users',
            params: { overview: true },
            headers: { 'Authorization' => admin_token }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['overview']['total_users']).to eq(19)
        expect(json_response['overview']['admin_count']).to eq(4) # 3 created + 1 admin making request
        expect(json_response['overview']['user_count']).to eq(15)
      end

      it 'filters by role' do
        get '/api/v1/admin/users',
            params: { role: 'admin' },
            headers: { 'Authorization' => admin_token }

  json_response = JSON.parse(response.body)
  expect(json_response['data']['users'].count).to eq(4) # All admins
      end

      it 'searches users by name or email' do
  _user = create(:user, full_name: 'Zebediah Xylophones', email: 'zebediah.unique@example.com')

        get '/api/v1/admin/users',
            params: { search: 'Zebediah' },
            headers: { 'Authorization' => admin_token }

  json_response = JSON.parse(response.body)
  expect(json_response['data']['users'].count).to eq(1)
  expect(json_response['data']['users'][0]['full_name']).to eq('Zebediah Xylophones')
      end
    end

    context 'as regular user' do
      it 'returns forbidden' do
        get '/api/v1/admin/users',
            headers: { 'Authorization' => user_token }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST /api/v1/admin/users' do
    let(:valid_attributes) do
      {
        user: {
          full_name: 'New User',
          email: 'newuser@example.com',
          role: 'user',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }
    end

    context 'as admin' do
      it 'creates a new user with password' do
        token = admin_token  # Ensure admin is created before counting
        expect {
          post '/api/v1/admin/users',
               params: valid_attributes,
               headers: { 'Authorization' => token }
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
  expect(json_response['data']['email']).to eq('newuser@example.com')
  expect(json_response['data']['role']).to eq('user')
      end

      it 'returns error when password is missing' do
        attributes_without_password = {
          user: {
            full_name: 'New User',
            email: 'newuser@example.com',
            role: 'user'
          }
        }

        post '/api/v1/admin/users',
             params: attributes_without_password,
             headers: { 'Authorization' => admin_token }

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)['errors']).to include('Password is required')
      end

      it 'returns errors for invalid user' do
        post '/api/v1/admin/users',
             params: { user: { email: 'invalid', password: 'password123', password_confirmation: 'password123' } },
             headers: { 'Authorization' => admin_token }

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)['errors']).to be_present
      end
    end
  end

  describe 'PATCH /api/v1/admin/users/:id' do
    let(:user) { create(:user) }

    context 'as admin' do
  it 'updates user attributes' do
    patch "/api/v1/admin/users/#{user.id}",
      params: { user: { full_name: 'Updated Name' } },
      headers: { 'Authorization' => admin_token }

    expect(response).to have_http_status(:ok)
    json_response = JSON.parse(response.body)
  expect(json_response['data']['full_name']).to eq('Updated Name')
  # Role is not permitted via strong params; use toggle_role endpoint instead
  expect(json_response['data']['role']).to eq('user')
  end

      it 'updates user password' do
        patch "/api/v1/admin/users/#{user.id}",
              params: { user: { password: 'newpassword123', password_confirmation: 'newpassword123' } },
              headers: { 'Authorization' => admin_token }

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'DELETE /api/v1/admin/users/:id' do
    let!(:user) { create(:user) }

    context 'as admin' do
      it 'deletes user' do
        token = admin_token  # Ensure admin is created before counting
        expect {
          delete "/api/v1/admin/users/#{user.id}",
                 headers: { 'Authorization' => token }
        }.to change(User, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      it 'prevents self-deletion' do
        delete "/api/v1/admin/users/#{admin.id}",
               headers: { 'Authorization' => admin_token }

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)['errors']).to include('You cannot delete your own account')
      end
    end
  end

  describe 'PATCH /api/v1/admin/users/:id/toggle_role' do
    let(:user) { create(:user) }

    context 'as admin' do
      it 'toggles user to admin' do
        patch "/api/v1/admin/users/#{user.id}/toggle_role",
              headers: { 'Authorization' => admin_token }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
  expect(json_response['data']['role']).to eq('admin')
      end

      it 'toggles admin to user' do
        admin_user = create(:user, :admin)
        patch "/api/v1/admin/users/#{admin_user.id}/toggle_role",
              headers: { 'Authorization' => admin_token }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
  expect(json_response['data']['role']).to eq('user')
      end

      it 'prevents self-role-toggle' do
        patch "/api/v1/admin/users/#{admin.id}/toggle_role",
              headers: { 'Authorization' => admin_token }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
