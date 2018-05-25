require 'net/http'
require 'json'
require_relative 'aurora-sdk/api'
require_relative 'aurora-sdk/audio'
require_relative 'aurora-sdk/config'
require_relative 'aurora-sdk/interpret'
require_relative 'aurora-sdk/text'
require_relative 'aurora-sdk/error'

module Aurora
    # Configuration holding credentials
    # e.g. Aurora.config = Aurora::Config.new(APP_ID, APP_TOKEN, DEVICE_ID)
    class << self
        attr_accessor :config
    end
end
