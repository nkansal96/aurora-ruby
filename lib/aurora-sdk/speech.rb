module Aurora
    class Speech
        attr_accessor :audio

        def initialize(audio)
            if !audio.is_a?(AudioFile)
                raise AudioTypeError.new(audio.class)
            end
            @audio = audio
        end

        def to_text
            Aurora::Api.get_stt(@audio)
        end
    end

    # TODO: Listening Functions

    LISTEN_LEN = 0
    SILENCE_LEN = 1.0

    def self.listen(length = LISTEN_LEN, silence_len = SILENCE_LEN)
        if length != 0
            Speech.new(Audio.record(length))
        end
    end

    # TODO: for these continuous functions, we need to be able to break from the loop
    # after there has been silence

    def self.continuously_listen(length = LISTEN_LEN, silence_len = SILENCE_LEN)
        Enumerator.new {|y|
            loop {
                y.yield Aurora.listen(length, silence_len)
            }
        }
    end

    def self.listen_and_transcribe(length = LISTEN_LEN, silence_len = SILENCE_LEN)
        # TODO: Implement with streams
    end

    def self.continuously_listen_and_transcribe(length = LISTEN_LEN, silence_len = SILENCE_LEN)
        Enumerator.new {|y|
            loop {
                y.yield Aurora.listen_and_transcribe(length, silence_len)
            }
        }
    end
end
