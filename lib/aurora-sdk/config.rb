module Aurora
    class Config
        attr_accessor :app_id, :app_token, :device_id

        # app_id and app_token are required, device_id is optional
        def initialize(app_id, app_token, device_id = nil)
            @app_id = app_id
            @app_token = app_token
            @device_id = device_id
        end
    end

    def self.config_valid?
        Aurora.config != nil && Aurora.config.is_a?(Config)
    end
end
