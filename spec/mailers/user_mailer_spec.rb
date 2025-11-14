require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  describe 'welcome_email_with_password' do
    let(:user) { create(:user, full_name: 'John Doe', email: 'john@example.com') }
    let(:password) { 'temp_password_123' }
    let(:mail) { UserMailer.welcome_email_with_password(user, password) }

    it 'renders the headers' do
      expect(mail.subject).to eq('Welcome! Your account has been created')
      expect(mail.to).to eq([ 'john@example.com' ])
      expect(mail.from).to eq([ 'from@example.com' ])
    end

    it 'renders the body with user info and password' do
      expect(mail.body.encoded).to match('John Doe')
      expect(mail.body.encoded).to match('john@example.com')
      expect(mail.body.encoded).to match('temp_password_123')
    end

    it 'includes security warning about password being sent only once' do
      expect(mail.body.encoded).to match(/only be sent once/)
    end
  end
end
