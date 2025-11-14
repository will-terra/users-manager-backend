require 'rails_helper'

RSpec.describe UserImportPolicy do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }
  let(:import) { create(:user_import) }

  it 'allows admin for index/show/create/destroy' do
    policy = described_class.new(admin, import)
    expect(policy.index?).to be true
    expect(policy.show?).to be true
    expect(policy.create?).to be true
    expect(policy.destroy?).to be true
  end

  it 'denies regular user for index/show/create/destroy' do
    policy = described_class.new(user, import)
    expect(policy.index?).to be false
    expect(policy.show?).to be false
    expect(policy.create?).to be false
    expect(policy.destroy?).to be false
  end

  it 'scope resolves appropriately' do
    expect(described_class::Scope.new(admin, UserImport).resolve).to eq(UserImport.all)
    expect(described_class::Scope.new(user, UserImport).resolve).to eq(UserImport.none)
  end
end
