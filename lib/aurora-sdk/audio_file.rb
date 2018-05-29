require_relative '../portaudio'
require_relative 'audio'

module Aurora
    class AudioFile
        attr_reader :playing, :should_stop

        # audio should be binary string representing WAV file
        def initialize(audio, playing = false, should_stop = false)
            @audio = audio
            @playing = playing
            @should_stop = should_stop
        end

        def to_wav
            @audio
        end

        def write_to_file(filename)
            Audio.write_to_file(@audio, filename)
        end

        def play
            @playing = true
            Audio.play_wav(@audio)
            @playing = false
        end

        def stop
            if @playing
                @should_stop = true
            end
        end

        # Pads both sides of audio with specified amount of silence (in seconds)
        def pad(seconds)
            @audio = Audio.pad(@audio, seconds)
        end

        # Pads the left side of the audio with the specified amount of silence (in seconds)
        def pad_left(seconds)
            @audio = Audio.pad_left(@audio, seconds)
        end

        # Pads the right side of the audio with the specified amount of silence (in seconds)
        def pad_right(seconds)
            @audio = Audio.pad_right(@audio, seconds)
        end

        # Trims extraneous silence at the ends of the audio
        def trim_silence
            @audio = Audio.trim_silence(0.03, 0.10, @audio)
        end

    end
end
