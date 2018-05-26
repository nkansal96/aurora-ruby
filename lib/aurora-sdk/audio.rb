require 'enumerator'
require_relative '../portaudio'

module Aurora
    class AudioFile
        attr_reader :playing, :should_stop

        def initialize(audio, playing = false, should_stop = false)
            @audio = audio
            @playing = playing
            @should_stop = should_stop
        end

        def to_wav
            @audio
        end

        def write_to_file(filename)
            open(filename, "wb") do |file|
                file.write(@audio)
            end
        end

        def play
            @playing = true
            Audio.play_wav(@audio)
            @playing = false
        end
    end

    class Audio
        PA = Portaudio

        # WAVE PCM Format based on http://soundfile.sapp.org/doc/WaveFormat/
        SAMPLE_RATE = 16000
        FRAMES_PER_BUFFER = 2
        NUM_CHANNELS = 1 # mono
        SAMPLE_TYPE = PA::PaInt16

        # WAVE File Data Offsets (in bytes)
        CHUNK_SIZE              = 4
        CHUNK_SIZE_OFFSET       = 4
        NUM_CHANNELS_OFFSET     = 22
        DATA_OFFSET             = 44

        def self.play_wav(data)
            handle_error(PA.Pa_Initialize)

            stream = Fiddle::Pointer.malloc 0
            output_param = get_output_params

            handle_error(PA.Pa_OpenStream(stream.ref, nil, output_param, SAMPLE_RATE, FRAMES_PER_BUFFER, PA::PaClipOff, nil, nil))
            handle_error(PA.Pa_StartStream(stream))

            if !valid_wav?(data)
                raise WAVFileError
            end

            # Play audio data by iterating through chunks
            (DATA_OFFSET..data.length-1).step(CHUNK_SIZE).each do |i|
                buffer = data[i..(i+CHUNK_SIZE-1)]
                err = PA.Pa_WriteStream(stream, buffer, FRAMES_PER_BUFFER)
                handle_error(err)
            end

            terminate(stream)
        end


        def self.play_file(filename)
            handle_error(PA.Pa_Initialize)

            stream = Fiddle::Pointer.malloc 0
            output_param = get_output_params

            handle_error(PA.Pa_OpenStream(stream.ref, nil, output_param, SAMPLE_RATE, FRAMES_PER_BUFFER, PA::PaClipOff, nil, nil))
            handle_error(PA.Pa_StartStream(stream))

            # Read audio file in chunks and play
            File.open(filename) do |file|
                if !valid_wav?(file)
                    raise WAVFileError
                end

                # Play back audio by writing to stream
                file.seek DATA_OFFSET
                while (buffer = file.read(CHUNK_SIZE)) do
                    err = PA.Pa_WriteStream(stream, buffer, FRAMES_PER_BUFFER)
                    handle_error(err)
                end
            end

            terminate(stream)
        end

        private_class_method def self.terminate(stream)
            handle_error(PA.Pa_StopStream(stream))
            handle_error(PA.Pa_CloseStream(stream))
            handle_error(PA.Pa_Terminate)
        end

        private_class_method def self.get_output_params
            output_param = PA::PaStreamParameters.malloc

            # Initialize output parameters
            output_param.device = PA.Pa_GetDefaultOutputDevice
            if output_param.device < 0
                puts 'Output device not found.'
                exit
            end

            output_param.channelCount = NUM_CHANNELS
            output_param.sampleFormat = SAMPLE_TYPE
            output_device_info = PA::Pa_GetDeviceInfo(output_param.device)
            if output_device_info.null?
                puts 'Error getting device info'
                exit
            end

            output_device_info = PA::PaDeviceInfo.new(output_device_info)
            output_param.suggestedLatency = output_device_info.defaultLowOutputLatency
            output_param.hostApiSpecificStreamInfo = nil

            return output_param
        end

        private_class_method def self.handle_error(err)
            if err != PA::PaErrorCode::PaNoError
                puts PA.Pa_GetErrorText(err)
                # TODO: raise an error regarding PortAudio
                PA.Pa_Terminate
                exit
            end
        end

        # TODO: Validates file headers with expected values for WAV format
        private_class_method def self.valid_wav?(file)
            # file.seek CHUNK_SIZE_OFFSET
            # chunk_size = file.read(CHUNK_SIZE).unpack('V')
            # puts chunk_size
            # if chunk_size != CHUNK_SIZE
            #     return false
            # end
            #
            # file.seek NUM_CHANNELS_OFFSET
            # num_channels = file.read(2).unpack("I<*")
            # puts num_channels
            # if num_channels != NUM_CHANNELS
            #    return false
            # end
            return true
        end
    end
end
