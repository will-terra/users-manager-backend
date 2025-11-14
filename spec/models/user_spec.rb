require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { build(:user) }
  let(:admin) { build(:user, :admin) }

  describe 'validations' do
    it { should validate_presence_of(:full_name) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:role) }

    it { should validate_length_of(:full_name).is_at_least(2).is_at_most(100) }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid_email').for(:email) }

    it { should validate_inclusion_of(:role).in_array(User::ROLES) }
  end

  describe 'default values' do
    it 'sets default role to user' do
      user = User.new
      expect(user.role).to eq('user')
    end
  end


  describe 'methods' do
    it '#admin? returns true for admin users' do
      expect(admin.admin?).to be true
    end

    it '#admin? returns false for regular users' do
      expect(user.admin?).to be false
    end

    it '#user? returns true for regular users' do
      expect(user.user?).to be true
    end

    it '#user? returns false for admin users' do
      expect(admin.user?).to be false
    end

    it '#generate_jwt returns a JWT token' do
      user.save
      token = user.generate_jwt
      expect(token).to be_a(String)
      expect(token.split('.').length).to eq(3)
    end
  end

  describe 'scopes' do
    before do
      create_list(:user, 2)
      create_list(:user, 3, :admin)
    end

    it '.admins returns only admin users' do
      expect(User.admins.count).to eq(3)
    end

    it '.users returns only regular users' do
      expect(User.users.count).to eq(2)
    end
  end
end
