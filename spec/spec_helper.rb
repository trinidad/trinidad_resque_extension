$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'trinidad_resque_extension'
require 'mocha'

RSpec.configure do |config|
  config.mock_with :mocha
end
