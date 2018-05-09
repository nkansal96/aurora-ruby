module Aurora

    INVALID_CONFIG_MSG = "Config not properly set. Aurora.config must be initialized with ID and Token."
    NIL_SPEECH_AUDIO_MSG = "The audio file was nil. In order to convert a Speech object to Text, it must have a valid audio file. Usually, this means you created a Speech object that wasn't created using one of the Listen methods."
    WAV_CORRUPT_FILE_MSG = "The WAV file was corrupted and did not have a correctly formatted RIFF header. Check the file to make sure it was not corrupted or incomplete."
    API_ERROR_MSG = "An error occurred with the API request."

    class InvalidConfigError < StandardError
        def initialize(msg=INVALID_CONFIG_MSG)
            super
        end
    end

    class NilSpeechAudioError < StandardError
        def initialize(msg=NIL_SPEECH_AUDIO_MSG)
            super
        end
    end

    class WAVCorruptFileError < StandardError
        def initialize(msg=WAV_CORRUPT_FILE_MSG)
            super
        end
    end

    class APIError < StandardError
        def initialize(msg=API_ERROR_MSG)
            super
        end
    end
end
