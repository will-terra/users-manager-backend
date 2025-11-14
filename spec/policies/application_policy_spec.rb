require 'rails_helper'

RSpec.describe ApplicationPolicy do
  let(:user) { create(:user) }

  describe '#initialize' do
    it 'raises when user is nil' do
      expect { described_class.new(nil, User) }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  describe 'default permissions' do
    subject { described_class.new(user, User.new) }

    it { expect(subject.index?).to be false }
    it { expect(subject.show?).to be false }
    it { expect(subject.create?).to be false }
    it { expect(subject.update?).to be false }
    it { expect(subject.destroy?).to be false }
  end

  describe 'Scope' do
    it 'raises when user is nil' do
      expect { described_class::Scope.new(nil, User) }.to raise_error(Pundit::NotAuthorizedError)
    end

    it 'resolves to all for authenticated user' do
      resolved = described_class::Scope.new(user, User).resolve
      expect(resolved).to eq(User.all)
    end
  end
end
