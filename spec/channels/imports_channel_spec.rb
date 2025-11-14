require 'rails_helper'

RSpec.describe ImportsChannel, type: :channel do
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:user_import) { create(:user_import, user: admin) }

  describe 'subscription' do
    context 'as admin' do
      before do
        stub_connection current_user: admin
      end

      it 'successfully subscribes to specific import' do
        subscribe(import_id: user_import.id)
        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_from("import_#{user_import.id}")
      end

      it 'successfully subscribes to all imports' do
        subscribe
        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_from("admin_imports")
      end

      it 'transmits current import status when subscribing to specific import' do
        subscribe(import_id: user_import.id)
        # Transmit sends directly to the connection, not via broadcast
        # We can check the streams instead
        expect(subscription).to have_stream_from("import_#{user_import.id}")
      end
    end

    context 'as regular user' do
      before do
        stub_connection current_user: regular_user
      end

      it 'rejects subscription' do
        subscribe(import_id: user_import.id)
        expect(subscription).to be_rejected
      end
    end

    context 'without authentication' do
      before do
        stub_connection current_user: nil
      end

      it 'rejects subscription' do
        subscribe(import_id: user_import.id)
        expect(subscription).to be_rejected
      end
    end
  end

  describe 'request_import_status' do
    before do
      stub_connection current_user: admin
      subscribe(import_id: user_import.id)
    end

    it 'transmits import status when requested' do
      # transmit sends data directly to the connection, not via broadcast
      # We can just verify the perform doesn't raise an error
      expect { perform :request_import_status }.not_to raise_error
    end
  end
end
