module Aurora
    # Namespace for Aurora Error Types
    module Error
      INVALID_CONFIG_MSG = "Config not properly set. Aurora.config must be initialized with ID and Token."
      NIL_SPEECH_AUDIO_MSG = "The audio file was nil. In order to convert a Speech object to Text, it must have a valid audio file. Usually, this means you created a Speech object that wasn't created using one of the Listen methods."
      WAV_FILE_MSG = "The WAV file was corrupted or did not have a correctly formatted RIFF header."
      API_ERROR_MSG = "An error occurred with the API request."
      PORTAUDIO_MSG = "An error occurred with PortAudio."
      INVALID_AUDIO_MSG = "The audio object was not of expected type AudioFile."

      # Config not properly set. Aurora.config must be initialized with ID and
      # Token.
      class InvalidConfigError < StandardError
          def initialize(msg=INVALID_CONFIG_MSG)
              super
          end
      end

      # The audio file was nil. In order to convert a Speech object to Text, it
      # must have a valid audio file. Usually, this means you created a Speech
      # object that wasn't created using one of the Listen methods.
      class NilSpeechAudioError < StandardError
          def initialize(msg=NIL_SPEECH_AUDIO_MSG)
              super
          end
      end

      # The WAV file was corrupted or did not have a correctly formatted RIFF
      # header.
      class WAVFileError < StandardError
          def initialize(msg=WAV_FILE_MSG)
              super
          end
      end

      # An error occurred with the API request.
      class APIError < StandardError
          def initialize(msg=API_ERROR_MSG)
              super
          end
      end

      # An error occurred with PortAudio.
      class PortAudioError < StandardError
          def initialize(msg=PORTAUDIO_MSG)
              msg = "An error occurred with PortAudio: #{msg}"
              super(msg)
          end
      end

      # The audio object was a different type instead of expected type
      # AudioFile.
      class AudioTypeError < TypeError
          def initialize(class_name=nil, msg=INVALID_AUDIO_MSG)
              if class_name != nil
                  msg = "The audio object was of type '#{class_name}' instead of expected type AudioFile."
              end
              super(msg)
          end
      end
    end
end
