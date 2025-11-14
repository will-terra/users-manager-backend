require 'rails_helper'

RSpec.describe ApplicationCable::Connection do
  describe '#extract_token_from_headers' do
    it 'returns token when Authorization header present' do
      conn = ApplicationCable::Connection.allocate
      req = double('request', headers: { 'HTTP_AUTHORIZATION' => 'Bearer abc' }, params: {})
      conn.instance_variable_set(:@request, req)
      expect(conn.send(:extract_token_from_headers)).to eq('abc')
    end

    it 'returns nil when header missing' do
      conn = ApplicationCable::Connection.allocate
      req = double('request', headers: {}, params: {})
      conn.instance_variable_set(:@request, req)
      expect(conn.send(:extract_token_from_headers)).to be_nil
    end
  end

  describe '#find_verified_user' do
    it 'returns user when token is valid in params' do
      user = FactoryBot.create(:user)
      conn = ApplicationCable::Connection.allocate
      req = double('request', params: { token: 'tkn' }, headers: {})
      conn.instance_variable_set(:@request, req)
      allow(Rails.application).to receive_message_chain(:credentials, :devise_jwt_secret_key).and_return('secret')
      allow(JWT).to receive(:decode).and_return([ { 'id' => user.id } ])
      expect(conn.send(:find_verified_user)).to eq(user)
    end

    it 'rejects connection when token missing' do
      conn = ApplicationCable::Connection.allocate
      req = double('request', params: {}, headers: {})
      conn.instance_variable_set(:@request, req)
      expect(conn).to receive(:reject_unauthorized_connection)
      conn.send(:find_verified_user)
    end
  end
end
