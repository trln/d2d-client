require 'bundler/setup'
require 'd2d/client'
require 'helpers'

RSpec.configure do |config|
  config.include Helpers
  config.expose_dsl_globally = true
  config.raise_errors_for_deprecations!
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  #config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
