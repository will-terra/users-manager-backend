require 'rails_helper'

RSpec.describe UpController, type: :controller do
  describe 'GET #index' do
    before do
      # Prevent Pundit verify hooks from raising in controller tests
      allow_any_instance_of(UpController).to receive(:verify_policy_scoped)
      allow_any_instance_of(UpController).to receive(:verify_authorized)
    end

    it 'returns status OK and environment' do
      get :index
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['status']).to eq('OK')
      expect(body).to have_key('timestamp')
      expect(body['environment']).to eq(Rails.env)
    end
  end
end
