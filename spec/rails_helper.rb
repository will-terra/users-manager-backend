ENV['RAILS_ENV'] ||= 'test'

# Start SimpleCov before loading the application so it can track coverage.
# We require it lazily (it is in the test group of the Gemfile).
begin
  require 'simplecov'
  SimpleCov.start 'rails' do
    add_filter '/spec/'
  end
  # Enforce a minimum global coverage threshold. If coverage falls below
  # this percentage the test run will exit non-zero so CI/builds fail.
  SimpleCov.minimum_coverage 90
rescue LoadError
  warn 'simplecov gem not available; coverage will not be generated. Run `bundle install`.'
end

require File.expand_path('../config/environment', __dir__)

# Prevent database modifications when running tests against production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'
require 'shoulda/matchers'
require 'pundit/matchers'

# Configure shoulda-matchers to use RSpec and Rails
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories. (If you create support files later.)
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }

require 'factory_bot_rails' if defined?(FactoryBot)

RSpec.configure do |config|
  # Include FactoryBot syntax methods
  config.include FactoryBot::Syntax::Methods if defined?(FactoryBot)
  config.include Pundit::Matchers if defined?(Pundit::Matchers)

  # Use transactional fixtures
  config.use_transactional_fixtures = true

  # If you're not using ActiveRecord, uncomment this line
  # config.use_active_record = false

  # Clean up and initialize database before running test suite
  config.before(:suite) do
    if defined?(ActiveRecord::Migration)
      ActiveRecord::Migration.maintain_test_schema!
    end
  end

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end

require_relative 'spec_helper'
