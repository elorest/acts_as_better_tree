require 'bundler/setup'
require 'active_record'
require 'factory_bot'
require 'acts_as_better_tree'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  
  # Explicitly enable the should syntax
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end
