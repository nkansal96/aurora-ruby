module Aurora
    class AudioFile
        # TODO: Incomplete!
        def initialize(audio, playing = false, should_stop = false)
            @audio = audio # TODO: currently just WAV data, need abstraction
            @playing = playing
            @should_stop = should_stop
        end

        # TODO: @audio will not be WAV data
        def to_wav
            @audio
        end
    end
end
