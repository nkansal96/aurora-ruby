require 'net/http'
require 'json'
require_relative 'aurora-sdk/api'
require_relative 'aurora-sdk/audio'
require_relative 'aurora-sdk/config'
require_relative 'aurora-sdk/error'
require_relative 'aurora-sdk/interpret'
require_relative 'aurora-sdk/text'
require_relative 'aurora-sdk/speech'

module Aurora
    # Configuration holding credentials
    class << self
        attr_accessor :config
    end
end
