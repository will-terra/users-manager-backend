require 'rails_helper'
require 'tempfile'

RSpec.describe FileDownloadService do
  describe '#call' do
    it 'returns nil for blank url' do
      expect(described_class.new(nil).call).to be_nil
      expect(described_class.new('').call).to be_nil
    end

    it 'returns file hash for successful HTTP response' do
      url = 'http://example.com/path/image.png'
      response = Object.new
      def response.is_a?(klass)
        klass == Net::HTTPSuccess
      end
      def response.body
        'PNGDATA'
      end
      def response.content_type
        'image/png'
      end

      allow(Net::HTTP).to receive(:get_response).and_return(response)

      result = described_class.new(url).call
      expect(result).to be_a(Hash)
      expect(result[:filename]).to eq('image.png')
      expect(result[:content_type]).to eq('image/png')
      expect(result[:io].read).to eq('PNGDATA')
    end

    it 'returns nil on HTTP error' do
      url = 'http://example.com/notfound'
      response = Object.new
      def response.is_a?(klass)
        false
      end
      def response.code
        '404'
      end
      allow(Net::HTTP).to receive(:get_response).and_return(response)
      expect(described_class.new(url).call).to be_nil
    end
  end
end
