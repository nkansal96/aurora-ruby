module Aurora

    # Config variable for credentials — must be initialized to use module functions
    # e.g. Aurora::config = Aurora::Config.new(APP_ID, APP_TOKEN, DEVICE_ID)
    class Config
        attr_accessor :app_id, :app_token, :device_id

        # app_id and app_token are required, device_id is optional
        def initialize(app_id, app_token, device_id = nil)
            @app_id = app_id
            @app_token = app_token
            @device_id = device_id
        end
    end
end
