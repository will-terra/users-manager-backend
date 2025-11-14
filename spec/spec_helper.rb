RSpec.configure do |config|
  # Persist example status to allow --only-failures flag
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Randomize test order to surface order dependencies.
  config.order = :random
  Kernel.srand config.seed
end
