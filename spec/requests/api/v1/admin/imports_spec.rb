require 'rails_helper'

RSpec.describe 'Api::V1::Admin::Imports', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:admin_token) { admin.generate_jwt }
  let(:user_token) { regular_user.generate_jwt }

  describe 'POST /api/v1/admin/imports' do
    context 'as admin' do
      it 'creates a new import with file' do
        file = fixture_file_upload('spec/fixtures/files/users.csv', 'text/csv')

        expect {
          post '/api/v1/admin/imports',
               params: { import: { file: file } },
               headers: { 'Authorization' => admin_token }
        }.to change(UserImport, :count).by(1)

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['data']['attributes']['status']).to eq('pending')
      end

      it 'creates a new import with file URL' do
        expect {
          post '/api/v1/admin/imports',
               params: { import: { file_url: 'https://example.com/users.csv' } },
               headers: { 'Authorization' => admin_token }
        }.to change(UserImport, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it 'returns errors for invalid import' do
        post '/api/v1/admin/imports',
             params: { import: { file: nil } },
             headers: { 'Authorization' => admin_token }

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)['errors']).to be_present
      end
    end

    context 'as regular user' do
      it 'returns forbidden' do
        post '/api/v1/admin/imports',
             params: { import: { file: nil } },
             headers: { 'Authorization' => user_token }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET /api/v1/admin/imports' do
    let!(:imports) { create_list(:user_import, 5, user: admin) }

    context 'as admin' do
      it 'returns paginated imports' do
        get '/api/v1/admin/imports',
            headers: { 'Authorization' => admin_token }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['imports']['data'].count).to eq(5)
        expect(json_response['pagination']).to be_present
      end
    end
  end

  describe 'GET /api/v1/admin/imports/:id' do
    let(:import) { create(:user_import, user: admin) }

    context 'as admin' do
      it 'returns the import' do
        get "/api/v1/admin/imports/#{import.id}",
            headers: { 'Authorization' => admin_token }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['data']['attributes']['status']).to eq('pending')
      end
    end
  end
end
