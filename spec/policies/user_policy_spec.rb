require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe '#index?' do
    it 'allows admin' do
      policy = UserPolicy.new(admin, User)
      expect(policy.index?).to be true
    end

    it 'denies regular user' do
      policy = UserPolicy.new(user, User)
      expect(policy.index?).to be false
    end
  end

  describe '#show?' do
    it 'allows admin to see any user' do
      policy = UserPolicy.new(admin, other_user)
      expect(policy.show?).to be true
    end

    it 'allows user to see themselves' do
      policy = UserPolicy.new(user, user)
      expect(policy.show?).to be true
    end

    it 'denies user to see other users' do
      policy = UserPolicy.new(user, other_user)
      expect(policy.show?).to be false
    end
  end

  describe '#update?' do
    it 'allows admin to update any user' do
      policy = UserPolicy.new(admin, other_user)
      expect(policy.update?).to be true
    end

    it 'allows user to update themselves' do
      policy = UserPolicy.new(user, user)
      expect(policy.update?).to be true
    end

    it 'denies user to update other users' do
      policy = UserPolicy.new(user, other_user)
      expect(policy.update?).to be false
    end
  end

  describe '#destroy?' do
    it 'allows admin to delete other users' do
      policy = UserPolicy.new(admin, other_user)
      expect(policy.destroy?).to be true
    end

    it 'allows admin to attempt to delete themselves (validation in controller prevents it)' do
      policy = UserPolicy.new(admin, admin)
      expect(policy.destroy?).to be true
    end

    it 'denies user to delete any user' do
      policy = UserPolicy.new(user, other_user)
      expect(policy.destroy?).to be false
    end
  end

  describe 'scope' do
    it 'returns all users for admin' do
      create_list(:user, 3)
      scope = UserPolicy::Scope.new(admin, User).resolve
      expect(scope.count).to eq(4) # 3 created + admin
    end

    it 'returns only themselves for regular user' do
      create_list(:user, 3)
      scope = UserPolicy::Scope.new(user, User).resolve
      expect(scope).to eq([ user ])
    end
  end
end
