module Aurora
    # Interface to Aurora::AudioFile
    class Speech
        attr_accessor :audio

        # @param audio [Aurora::AudioFile]
        #
        # @return a new instance of Aurora::Speech
        def initialize(audio)
            if !audio.is_a?(AudioFile)
                raise AudioTypeError.new(audio.class)
            end
            @audio = audio
        end
        
        # Transcribes speech to text
        #
        # @return [Aurora::Text]
        def to_text
            Aurora::Api.get_stt(@audio)
        end
    end

    # LISTEN_LEN is the default amount of time (in seconds) to listen for.
    LISTEN_LEN = 0
    # SILENCE_LEN is the default amount of silence (in seconds) that the
    # recording framework will allow before stopping.
    SILENCE_LEN = 1.0

    # listen generates an Aurora::Speech object from recorded audio
    #
    # @param length [Float] the time (in seconds) to listen for.
    #                       A value of 0 means that the recording framework will
    #                       continue to listen until the specified amount of
    #                       silence. A value greater than 0 will override any
    #                       value set to 'silence_len'.
    # @param silence_len [Float] how long of silence (in seconds) will be
    #                            allowed before automatically stopping. This
    #                            value is only taken into consideration if
    #                            'length' is 0.
    #
    # @return [Aurora::Speech]
    def self.listen(length = LISTEN_LEN, silence_len = SILENCE_LEN)
        Speech.new(Audio.record(length, silence_len))
    end

    # continuously_listen calls 'listen' continuously.
    #
    # @param length [Float] the time (in seconds) to listen for.
    #                       A value of 0 means that the recording framework will
    #                       continue to listen until the specified amount of
    #                       silence. A value greater than 0 will override any
    #                       value set to 'silence_len'.
    # @param silence_len [Float] how long of silence (in seconds) will be
    #                            allowed before automatically stopping. This
    #                            value is only taken into consideration if
    #                            'length' is 0.
    #
    # @return [Enumerator]
    def self.continuously_listen(length = LISTEN_LEN, silence_len = SILENCE_LEN)
        Enumerator.new {|y|
            loop {
                y.yield Aurora.listen(length, silence_len)
            }
        }
    end

    # listen_and_transcribe generates an Aurora::Speech object from recorded
    # audio and directly streams that object into the Aurora API in order
    # to transcribe the audio in real-time. After the transcription, this
    # function will return an Aurora::Text object, significantly reducing
    # latency for those who additionally want to transcribe their audio.
    #
    # @param length [Float] the time (in seconds) to listen for.
    #                       A value of 0 means that the recording framework will
    #                       continue to listen until the specified amount of
    #                       silence. A value greater than 0 will override any
    #                       value set to 'silence_len'.
    # @param silence_len [Float] how long of silence (in seconds) will be
    #                            allowed before automatically stopping. This
    #                            value is only taken into consideration if
    #                            'length' is 0.
    #
    # @return [Aurora::Text]
    def self.listen_and_transcribe(length = LISTEN_LEN, silence_len = SILENCE_LEN)
        Aurora::Api.get_stt(nil, true, Audio.get_record_enum(length, silence_len))
    end

    # continuously_listen_and_transcribe calls 'listen_and_transcribe'
    # continuously.
    #
    # @param length [Float] the time (in seconds) to listen for.
    #                       A value of 0 means that the recording framework will
    #                       continue to listen until the specified amount of
    #                       silence. A value greater than 0 will override any
    #                       value set to 'silence_len'.
    # @param silence_len [Float] how long of silence (in seconds) will be
    #                            allowed before automatically stopping. This
    #                            value is only taken into consideration if
    #                            'length' is 0.
    #
    # @return [Enumerator]
    def self.continuously_listen_and_transcribe(length = LISTEN_LEN, silence_len = SILENCE_LEN)
        Enumerator.new {|y|
            loop {
                y.yield Aurora.listen_and_transcribe(length, silence_len)
            }
        }
    end
end
