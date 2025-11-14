require 'rails_helper'
require 'securerandom'

RSpec.describe 'CSRF / Authorization enforcement for state-changing endpoints', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:admin_token) { admin.generate_jwt }

  it 'rejects creating an admin resource without Authorization header' do
  # Attempt to create a user (admin endpoint) without Authorization header
  post '/api/v1/admin/users', params: { user: { full_name: 'Bad', email: 'bad@example.com', role: 'user', password: 'password123', password_confirmation: 'password123' } }

    # The API should not allow state changes without a valid token
    expect([ 401, 403 ]).to include(response.status)
  end

  it 'rejects creating an admin resource with an invalid token' do
  post '/api/v1/admin/users', headers: { 'Authorization' => 'invalid.token' }, params: { user: { full_name: 'Bad', email: 'bad2@example.com', role: 'user', password: 'password123', password_confirmation: 'password123' } }

    expect(response).to have_http_status(:unauthorized)
  end

  it 'allows creation when authorized as admin' do
    unique_email = "good+#{SecureRandom.hex(4)}@example.com"
    expect {
      post '/api/v1/admin/users', headers: { 'Authorization' => admin_token }, params: { user: { full_name: 'Good', email: unique_email, role: 'user', password: 'password123', password_confirmation: 'password123' } }
    }.to change { User.count }.by_at_least(1)

    # Creation should return HTTP 201 Created or 200 OK depending on implementation
    expect([ 200, 201 ]).to include(response.status)
  end
end
