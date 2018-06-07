module TestHelpers
    APP_ID = '' # Add your Aurora APP ID here
    APP_TOKEN = '' # Add your Aurora APP TOKEN here

    def setup
        Aurora.config = Aurora::Config.new(APP_ID, APP_TOKEN)
    end

    def teardown
        Aurora.config = nil
    end
end
