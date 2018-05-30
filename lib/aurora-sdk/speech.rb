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

    LISTEN_LEN = 0
    SILENCE_LEN = 1.0

    def self.listen(length = LISTEN_LEN, silence_len = SILENCE_LEN)
        Speech.new(Audio.record(length, silence_len))
    end

    def self.continuously_listen(length = LISTEN_LEN, silence_len = SILENCE_LEN)
        Enumerator.new {|y|
            loop {
                y.yield Aurora.listen(length, silence_len)
            }
        }
    end

    def self.listen_and_transcribe(length = LISTEN_LEN, silence_len = SILENCE_LEN)
        Aurora::Api.get_stt(nil, true, Audio.get_record_enum(length, silence_len))
    end

    def self.continuously_listen_and_transcribe(length = LISTEN_LEN, silence_len = SILENCE_LEN)
        Enumerator.new {|y|
            loop {
                y.yield Aurora.listen_and_transcribe(length, silence_len)
            }
        }
    end
end
