require 'rails_helper'

RSpec.describe ParameterValidationService do
  describe '#validate' do
    it 'returns error when required param is missing' do
      svc = described_class.new({}, required: [ :email ])
      expect(svc.validate).to include('Missing required parameter: email')
      expect(svc.valid?).to be false
    end

    it 'returns error for unpermitted parameters' do
      svc = described_class.new({ foo: 'bar' }, required: [], optional: [])
      expect(svc.validate).to include('Unpermitted parameter: foo')
    end

    it 'is valid when required params present and no extra params' do
      svc = described_class.new({ email: 'a@b.com' }, required: [ :email ], optional: [])
      expect(svc.validate).to be_empty
      expect(svc.valid?).to be true
    end
  end
end
