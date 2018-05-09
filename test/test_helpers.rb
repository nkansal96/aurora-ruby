module TestHelpers
    APP_ID = '40d32fb42fc846ac438425593bfdc33d'
    APP_TOKEN = 'O31MY3tPoEMHGcjGEQqnNY1HanDrkkAu'

    def setup
        Aurora::config = Aurora::Config.new(APP_ID, APP_TOKEN)
    end

    def teardown
        Aurora::config = nil
    end
end
