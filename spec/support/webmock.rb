require 'webmock/rspec'

# Configure WebMock
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.before(:each) do
    # Stub avatar URL downloads
    stub_request(:get, %r{https://example\.com/avatar\d*\.jpg})
      .to_return(
        status: 200,
        body: File.read(Rails.root.join('spec', 'fixtures', 'files', 'avatar.png')),
        headers: { 'Content-Type' => 'image/jpeg' }
      )
  end
end
