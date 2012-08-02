require 'bundler/setup'
require 'active_record'
require 'factory_girl'
require 'acts_as_better_tree'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  
end
