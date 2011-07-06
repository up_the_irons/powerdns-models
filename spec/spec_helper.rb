$:.unshift(File.dirname(__FILE__) + '/..')
$:.unshift(File.dirname(__FILE__) + '/../lib')

RAILS_ENV = "test" unless defined?(RAILS_ENV)

require 'rubygems'

begin
  require 'active_record'
rescue LoadError
  require 'activerecord'
end

config = YAML::load(File.open(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.configurations = config

require 'init'

begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  require 'spec'
end

require 'spec/mocks'

require 'factory_girl'
require 'spec/factories.rb'

Spec::Runner.configure do |config|
  # Can't figure out how to get this to work
  #
  # I always get::
  #
  #   undefined method `use_transactional_fixtures=' for #<Spec::Runner::Configuration:0x7fa8fa8cf2d0> (NoMethodError)
  #
  # config.use_transactional_fixtures = true
end

Spec::Mocks::Proxy.allow_message_expectations_on_nil

# Include when needed
#
# require 'ruby-debug'
