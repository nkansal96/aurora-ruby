require 'net/http'
require 'json'
require_relative 'aurora_sdk/api'
require_relative 'aurora_sdk/config'
require_relative 'aurora_sdk/interpret'
require_relative 'aurora_sdk/text'
require_relative 'aurora_sdk/error'

module Aurora
    # Configuration holding credentials
    # e.g. Aurora.config = Aurora::Config.new(APP_ID, APP_TOKEN, DEVICE_ID)
    class << self
        attr_accessor :config
    end
end
