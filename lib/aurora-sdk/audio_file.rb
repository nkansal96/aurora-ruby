require_relative '../portaudio'
require_relative 'audio'

module Aurora
    # Interface to Aurora::Audio
    class AudioFile
        attr_reader :playing, :should_stop

        # @param audio [String] Binary string representation of WAV File
        # @param playing [Bool] Indicates whether audio is playing
        # @param should_stop [Bool] Indicates whether playback should stop
        #
        # @return a new instance of Aurora::Speech
        def initialize(audio, playing = false, should_stop = false)
            @audio = audio
            @playing = playing
            @should_stop = should_stop
        end

        # Returns binary string representation of audio
        #
        # @return [String]
        def to_wav
            @audio
        end

        # Writes the WAV data to the specified location
        #
        # @param filename [String] File path to write to
        #
        # @return [Int] Number of bytes written in total
        def write_to_file(filename)
            Audio.write_to_file(@audio, filename)
        end

        # Plays the underlying audio on the default output device.
        # Although this call blocks, you can stop playback by calling the stop() method
        #
        # @return [Bool]
        def play
            @playing = true
            Audio.play_wav(@audio)
            @playing = false
        end

        # Stop playback of the audio
        # @return [Bool]
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
            @audio = Audio.trim_silence(0.03, 0.1, @audio)
        end

    end
end
