require 'rails_helper'

RSpec.describe 'XSS (Cross-site scripting) related checks', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:admin_token) { admin.generate_jwt }

  it 'returns user attributes as JSON and does not render HTML content' do
    malicious_name = "<script>alert('xss')</script>"
    user = create(:user, full_name: malicious_name, email: 'xss@example.com')

    get "/api/v1/admin/users/#{user.id}", headers: { 'Authorization' => admin_token }

    expect(response).to have_http_status(:ok)
    # Response should be JSON and contain the raw value (JSON transports data, escaping happens in the renderer)
    expect(response.content_type).to include('application/json')
    json = JSON.parse(response.body)
    expect(json['data']['full_name']).to eq(malicious_name)
    # Important: ensure we are not returning raw HTML that could be interpreted by a browser
    # JSON should escape < and > as unicode sequences in the response body
    expect(response.body).not_to include('<script>')
  end
end
