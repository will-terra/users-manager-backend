require 'rails_helper'

RSpec.describe 'SQL/Parameter Injection', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:admin_token) { admin.generate_jwt }

  it 'ignores malicious SQL in search param and does not alter database' do
    # create some users to search against
    create_list(:user, 5)
    initial_count = User.count

    # Common malicious payloads an attacker might try
    payloads = [
      "'; DROP TABLE users; --",
      """ OR 1=1 --""",
      "admin' OR '1'='1",
      "%'); DELETE FROM users; --"
    ]

    payloads.each do |p|
      get '/api/v1/admin/users', params: { search: p }, headers: { 'Authorization' => admin_token }

      # should return OK and not perform destructive operations (no deletion)
      expect(response).to have_http_status(:ok)
      expect(User.count).to be >= initial_count
    end
  end
end
