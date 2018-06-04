module Aurora
    # Class that supports Authentication and Device Identification to the
    # Aurora API
    class Config
        attr_accessor :app_id, :app_token, :device_id

        # app_id and app_token are required, device_id is optional
        #
        # @param app_id [String]
        # @param app_token [String]
        # @param device_id [optional, String]
        def initialize(app_id, app_token, device_id = nil)
            @app_id = app_id
            @app_token = app_token
            @device_id = device_id
        end
    end

    # Checks to see if the user has initialized an Aurora::Config object with
    # an Application ID and Application Token.
    #
    # @return [Boolean]
    def self.config_valid?
        Aurora.config != nil && Aurora.config.is_a?(Config)
    end
end
