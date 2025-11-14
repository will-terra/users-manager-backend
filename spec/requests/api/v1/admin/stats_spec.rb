require 'rails_helper'

RSpec.describe 'Api::V1::Admin::Stats', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:admin_token) { admin.generate_jwt }
  let(:user_token) { regular_user.generate_jwt }

  describe 'GET /api/v1/admin/stats' do
    before do
      create_list(:user, 5)
      create_list(:user, 3, :admin)

      create(:user, created_at: 1.day.ago)
      create(:user, last_sign_in_at: 1.hour.ago)
      create(:user, last_sign_in_at: 2.days.ago)
    end

    context 'as admin' do
      it 'returns dashboard statistics' do
        get '/api/v1/admin/stats',
            headers: { 'Authorization' => admin_token }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        stats = json_response['stats']

        expect(stats['total_users']).to eq(12) # 1 admin + 1 regular_user + 5 users + 3 admins + 3 extras - 1 (regular_user not created until needed)
        expect(stats['admin_count']).to eq(4) # 3 created + 1 admin making request
        expect(stats['user_count']).to eq(8) # 5 created + 3 extras
        expect(stats['recent_signups']).to be >= 1
        expect(stats['active_today']).to be >= 1
        expect(stats['users_by_month']).to be_a(Hash)
        expect(stats['role_distribution']).to be_a(Hash)
      end
    end

    context 'as regular user' do
      it 'returns forbidden' do
        get '/api/v1/admin/stats',
            headers: { 'Authorization' => user_token }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
